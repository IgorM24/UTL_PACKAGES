CREATE SCHEMA IF NOT EXISTS UTL_ENCODE;

/*----------------------------------------------------------------*/
/* BASE64_ENCODE                                                  */
/*----------------------------------------------------------------*/
CREATE OR REPLACE FUNCTION UTL_ENCODE.base64_encode(r BYTEA) RETURNS BYTEA
LANGUAGE SQL IMMUTABLE STRICT
BEGIN ATOMIC
  RETURN convert_to(encode(r, 'base64'), 'UTF8');
END;


/*----------------------------------------------------------------*/
/* BASE64_DECODE                                                  */
/*----------------------------------------------------------------*/
CREATE OR REPLACE FUNCTION UTL_ENCODE.base64_decode(r BYTEA) RETURNS BYTEA
LANGUAGE SQL IMMUTABLE STRICT 
BEGIN ATOMIC
  RETURN decode(convert_from(r, 'UTF8'), 'base64');
END;


/*----------------------------------------------------------------*/
/* BASE64_ENCODE                                                  */
/*----------------------------------------------------------------*/
CREATE OR REPLACE FUNCTION UTL_ENCODE.base64_encode(r TEXT) RETURNS TEXT
LANGUAGE SQL IMMUTABLE STRICT
BEGIN ATOMIC
  RETURN CASE
           WHEN r = '' THEN NULL
           ELSE encode(convert_to(r, 'UTF8'), 'base64')
         END;
END;


/*----------------------------------------------------------------*/
/* BASE64_DECODE                                                  */
/*----------------------------------------------------------------*/
CREATE OR REPLACE FUNCTION UTL_ENCODE.base64_decode(r TEXT) RETURNS TEXT
LANGUAGE SQL IMMUTABLE STRICT
BEGIN ATOMIC
  RETURN CASE
           WHEN r = '' THEN NULL
           ELSE convert_from(decode(r, 'base64'), 'UTF8')
         END;
END;

/*----------------------------------------------------------------*/
/* text_encode                                                    */
/*----------------------------------------------------------------*/
CREATE OR REPLACE FUNCTION UTL_ENCODE.text_encode(buf            TEXT,
                                                  encode_charset TEXT DEFAULT 'UTF8',
                                                  encoding       TEXT DEFAULT 'base64') RETURNS TEXT
LANGUAGE SQL IMMUTABLE STRICT
BEGIN ATOMIC
  RETURN CASE
           WHEN buf = '' THEN NULL
           ELSE encode(convert_to(buf, encode_charset), encoding)
         END;
END;


CREATE OR REPLACE FUNCTION UTL_ENCODE.text_decode(buf            TEXT,
                                                  encode_charset TEXT DEFAULT 'UTF8',
                                                  encoding       TEXT DEFAULT 'base64') RETURNS TEXT
LANGUAGE SQL IMMUTABLE STRICT
BEGIN ATOMIC
  RETURN CASE
           WHEN buf = '' THEN NULL
           ELSE convert_from(decode(buf, encoding), encode_charset)
         END;
END;


/*----------------------------------------------------------------*/
/* uuencode                                                       */
/*----------------------------------------------------------------*/
CREATE OR REPLACE FUNCTION utl_encode.uuencode(r bytea)
RETURNS bytea AS $$
DECLARE
    v_output     bytea := 'begin 0 uuencode.txt'::bytea || E'\r\n'::bytea;
    v_len        int := octet_length(r);
    v_pos        int := 0;
    v_chunk_size int := 45;
    v_chunk_len  int;
    i            int;
    b1           int; 
    b2           int; 
    b3           int;
    c1           int; 
    c2           int; 
    c3           int; 
    c4           int;
BEGIN
    IF r IS NULL THEN RETURN NULL; END IF;

    WHILE v_pos < v_len LOOP
        v_chunk_len := LEAST(v_chunk_size, v_len - v_pos);
        
        v_output := v_output || set_byte('\x00'::bytea, 0, v_chunk_len + 32);

        FOR i IN 0..(v_chunk_len - 1) BY 3 LOOP
            b1 := get_byte(r, v_pos + i);
            b2 := CASE WHEN v_pos + i + 1 < v_len THEN get_byte(r, v_pos + i + 1) ELSE 0 END;
            b3 := CASE WHEN v_pos + i + 2 < v_len THEN get_byte(r, v_pos + i + 2) ELSE 0 END;

            c1 := (b1 >> 2) & 63;
            c2 := ((b1 << 4) | (b2 >> 4)) & 63;
            c3 := ((b2 << 2) | (b3 >> 6)) & 63;
            c4 := b3 & 63;

            v_output := v_output || set_byte('\x00'::bytea, 0, CASE WHEN c1 = 0 THEN 96 ELSE c1 + 32 END);
            v_output := v_output || set_byte('\x00'::bytea, 0, CASE WHEN c2 = 0 THEN 96 ELSE c2 + 32 END);
            v_output := v_output || set_byte('\x00'::bytea, 0, CASE WHEN c3 = 0 THEN 96 ELSE c3 + 32 END);
            v_output := v_output || set_byte('\x00'::bytea, 0, CASE WHEN c4 = 0 THEN 96 ELSE c4 + 32 END);
        END LOOP;
        
        v_output := v_output || E'\r\n'::bytea;
        v_pos := v_pos + v_chunk_len;
    END LOOP;

    RETURN v_output || E'`\r\nend'::bytea;
END;
$$ LANGUAGE plpgsql IMMUTABLE;


/*----------------------------------------------------------------*/
/* uuencode                                                       */
/*----------------------------------------------------------------*/
CREATE OR REPLACE FUNCTION utl_encode.uuencode(r          bytea,
                                               type       integer,
                                               filename   text,
                                               permission text) RETURNS bytea
LANGUAGE plpgsql
AS $$
DECLARE
    v_pos     int := 0;
    v_len     int := length(r);
    v_chunk   bytea;
    v_line    text;
    v_result  text := 'begin ' || permission || ' ' || filename || E'\r\n';
    i         int;
    chunk_len int;
BEGIN
    WHILE v_pos < v_len 
    LOOP
        v_chunk := substring(r FROM v_pos+1 FOR 45);
        chunk_len := length(v_chunk);
        v_pos := v_pos + chunk_len;

        -- first char of string: length + 32
        v_line := chr(chunk_len + 32);

        -- ecnode 3 bytes for one iteration
        i := 0;
        WHILE i < chunk_len 
        LOOP
            v_line := v_line || convert_from(utl_encode.uuencode(substring(v_chunk FROM i+1 FOR 3)),'UTF8');
            i := i + 3;
        END LOOP;

        v_result := v_result || v_line || E'\r\n';
    END LOOP;

    -- last line '`end' without CRLF
    v_result := v_result || '`end';

    RETURN convert_to(v_result,'UTF8');
END;
$$;


CREATE OR REPLACE FUNCTION utl_encode.uuencode(r    bytea,
                                               type integer) RETURNS bytea
LANGUAGE sql IMMUTABLE STRICT
BEGIN ATOMIC
  RETURN utl_encode.uuencode(r,type,'uuencode.txt','0');
END;


CREATE OR REPLACE FUNCTION utl_encode.uuencode(r        bytea,
                                               type     integer,
                                               filename text) RETURNS bytea
LANGUAGE sql IMMUTABLE STRICT
BEGIN ATOMIC
  RETURN utl_encode.uuencode(r,type,filename,'0');
END;


CREATE OR REPLACE FUNCTION utl_encode.uudecode(p_input bytea) RETURNS bytea
LANGUAGE plpgsql
AS $$
DECLARE
    v_text    text  := convert_from(p_input,'UTF8');
    v_len     int   := length(v_text);
    v_pos     int   := 1;
    v_result  bytea := ''::bytea;
    line_len  int;
    line_text text;
    c1        int; 
    c2        int; 
    c3        int; 
    c4        int;
    b1        int; 
    b2        int; 
    b3        int;
    i         int;
    chunk_len int;
BEGIN
    IF left(v_text,6) = 'begin ' THEN
        v_pos := strpos(v_text,E'\r\n') + 2;
    END IF;

    WHILE v_pos <= v_len 
    LOOP
        IF strpos(v_text,E'\r\n',v_pos) = 0 THEN
            line_text := substr(v_text,v_pos);
            v_pos := v_len + 1;
        ELSE
            line_text := substr(v_text,v_pos, strpos(v_text,E'\r\n',v_pos)-v_pos);
            v_pos := strpos(v_text,E'\r\n',v_pos) + 2;
        END IF;

        IF line_text = '`end' OR line_text = '`' THEN
            EXIT;
        END IF;

        line_len := ascii(substr(line_text,1,1)) - 32; 
        IF line_len < 0 THEN
            line_len := 0;
        END IF;

        i := 2; 
        chunk_len := 0;

        WHILE i <= length(line_text) AND chunk_len < line_len 
        LOOP
            c1 := ascii(substr(line_text,i,1));
            c2 := ascii(substr(line_text,i+1,1));
            c3 := ascii(substr(line_text,i+2,1));
            c4 := ascii(substr(line_text,i+3,1));

            c1 := (c1 - 32) & 63;
            c2 := (c2 - 32) & 63;
            c3 := (c3 - 32) & 63;
            c4 := (c4 - 32) & 63;

            b1 := (c1 << 2) | (c2 >> 4);
            b2 := ((c2 & 15) << 4) | (c3 >> 2);
            b3 := ((c3 & 3) << 6) | c4;

            IF chunk_len + 1 <= line_len THEN
                v_result := v_result || set_byte('\x00'::bytea,0,b1);
                chunk_len := chunk_len + 1;
            END IF;
            IF chunk_len + 1 <= line_len THEN
                v_result := v_result || set_byte('\x00'::bytea,0,b2);
                chunk_len := chunk_len + 1;
            END IF;
            IF chunk_len + 1 <= line_len THEN
                v_result := v_result || set_byte('\x00'::bytea,0,b3);
                chunk_len := chunk_len + 1;
            END IF;

            i := i + 4;
        END LOOP;
    END LOOP;

    RETURN v_result;
END;
$$;
