CREATE SCHEMA IF NOT EXISTS utl_raw;

CREATE OR REPLACE FUNCTION utl_raw.cast_to_raw(c text) RETURNS bytea
LANGUAGE sql IMMUTABLE STRICT
BEGIN ATOMIC
  RETURN CASE
           WHEN c = '' THEN NULL
           ELSE convert_to(c,'UTF8')
         END;
END;


CREATE OR REPLACE FUNCTION utl_raw.cast_to_varchar2(r bytea) RETURNS text
LANGUAGE sql IMMUTABLE STRICT
BEGIN ATOMIC
  RETURN convert_from(r,'UTF8');
END;

CREATE OR REPLACE FUNCTION utl_raw.concat(
    r1  bytea DEFAULT NULL,
    r2  bytea DEFAULT NULL,
    r3  bytea DEFAULT NULL,
    r4  bytea DEFAULT NULL,
    r5  bytea DEFAULT NULL,
    r6  bytea DEFAULT NULL,
    r7  bytea DEFAULT NULL,
    r8  bytea DEFAULT NULL,
    r9  bytea DEFAULT NULL,
    r10 bytea DEFAULT NULL,
    r11 bytea DEFAULT NULL,
    r12 bytea DEFAULT NULL
)
RETURNS bytea
LANGUAGE sql
IMMUTABLE STRICT
BEGIN ATOMIC
  RETURN 
    COALESCE(r1,'') ||
    COALESCE(r2,'') ||
    COALESCE(r3,'') ||
    COALESCE(r4,'') ||
    COALESCE(r5,'') ||
    COALESCE(r6,'') ||
    COALESCE(r7,'') ||
    COALESCE(r8,'') ||
    COALESCE(r9,'') ||
    COALESCE(r10,'') ||
    COALESCE(r11,'') ||
    COALESCE(r12,'');
END;

CREATE OR REPLACE FUNCTION utl_raw.length(r bytea) RETURNS integer
LANGUAGE sql IMMUTABLE STRICT
BEGIN ATOMIC
  RETURN octet_length(r);
END;

CREATE OR REPLACE FUNCTION utl_raw.substr(r bytea, pos integer, len integer DEFAULT NULL) RETURNS bytea
LANGUAGE sql IMMUTABLE STRICT
BEGIN ATOMIC
  RETURN CASE
           WHEN len IS NULL THEN substring(r FROM pos)
           ELSE substring(r FROM pos FOR len)
         END;
END;

CREATE OR REPLACE FUNCTION utl_raw.raw_to_hex(r bytea) RETURNS text
LANGUAGE sql IMMUTABLE STRICT
BEGIN ATOMIC
  RETURN encode(r,'hex');
END;


CREATE OR REPLACE FUNCTION utl_raw.hex_to_raw(c text) RETURNS bytea
LANGUAGE sql IMMUTABLE STRICT
BEGIN ATOMIC
  RETURN CASE
           WHEN c = '' THEN NULL
           ELSE decode(c,'hex')
         END;
END;


CREATE OR REPLACE FUNCTION utl_raw.compare(r1 bytea, r2 bytea) RETURNS integer
LANGUAGE sql IMMUTABLE STRICT
BEGIN ATOMIC
  RETURN CASE
           WHEN r1 = r2 THEN 0
           WHEN r1 < r2 THEN -1
           ELSE 1
         END;
END;


CREATE OR REPLACE FUNCTION utl_raw.reverse(r bytea) RETURNS bytea
LANGUAGE plpgsql IMMUTABLE STRICT
AS $$
DECLARE
  len    int := octet_length(r);
  result bytea := repeat(E'\\000', len)::bytea;
  i int;
BEGIN
  FOR i IN 0..len-1 LOOP
    result := set_byte(result, i, get_byte(r, len-1-i));
  END LOOP;

  RETURN result;
END;
$$;


CREATE OR REPLACE FUNCTION utl_raw.bit_and(r1 bytea, r2 bytea) RETURNS bytea
LANGUAGE plpgsql IMMUTABLE STRICT
AS $$
DECLARE
    len int;
    i   int;
    ba  bytea := r1;
BEGIN
    len := LEAST(length(r1),length(r2));

    FOR i IN 0..len-1 LOOP
        ba := set_byte(ba,i,get_byte(r1,i) & get_byte(r2,i));
    END LOOP;

    RETURN ba;
END;
$$;


CREATE OR REPLACE FUNCTION utl_raw.bit_or(r1 bytea, r2 bytea) RETURNS bytea
LANGUAGE plpgsql IMMUTABLE STRICT
AS $$
DECLARE
    len int;
    i int;
    ba bytea := r1;
BEGIN
    len := LEAST(length(r1),length(r2));

    FOR i IN 0..len-1 LOOP
        ba := set_byte(ba,i,get_byte(r1,i) | get_byte(r2,i));
    END LOOP;

    RETURN ba;
END;
$$;

CREATE OR REPLACE FUNCTION utl_raw.bit_xor(r1 bytea, 
                                           r2 bytea) RETURNS bytea
LANGUAGE plpgsql IMMUTABLE STRICT
AS $$
DECLARE
    len int;
    i int;
    ba bytea := r1;
BEGIN
    len := LEAST(length(r1),length(r2));

    FOR i IN 0..len-1 LOOP
        ba := set_byte(ba,i,get_byte(r1,i) # get_byte(r2,i));
    END LOOP;

    RETURN ba;
END;
$$;
