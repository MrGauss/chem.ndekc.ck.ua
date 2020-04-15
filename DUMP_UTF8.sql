--
-- PostgreSQL database dump
--

-- Dumped from database version 11.7 (Debian 11.7-2.pgdg80+1)
-- Dumped by pg_dump version 11.7 (Debian 11.7-2.pgdg80+1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: chem.ndekc.ck.ua; Type: DATABASE; Schema: -; Owner: -
--

CREATE DATABASE "chem.ndekc.ck.ua" WITH TEMPLATE = template0 ENCODING = 'UTF8' LC_COLLATE = 'ru_UA.UTF-8' LC_CTYPE = 'ru_UA.UTF-8';


\connect "chem.ndekc.ck.ua"

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: GENERATE_STOCK_NUMBER_TRIG(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION "public"."GENERATE_STOCK_NUMBER_TRIG"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
	
	DECLARE rn TEXT;
	DECLARE seq_name TEXT;
	DECLARE seq_exist INTEGER;

DECLARE	

BEGIN

		IF NEW.reagent_number != '' THEN
		
			return NEW;
			
		END IF;

		rn := '';
		seq_name := 'stock_gr_'::text || NEW.group_id ::text || '_'::text || EXTRACT( year from NEW.inc_date )::text || '_seq'::TEXT;
		
		SELECT COUNT(c.relname) FROM pg_class c WHERE c.relkind = 'S' AND c.relname = seq_name INTO seq_exist;
		
		IF seq_exist < 1 THEN
		
					EXECUTE 'CREATE SEQUENCE "public"."' || seq_name || '" INCREMENT 1 MINVALUE 0 START 1;';
					
					seq_exist := 1;
					
		END IF;
		
		
		LOOP
				SELECT ( nextval( seq_name )::TEXT || '-'::TEXT || EXTRACT( year from NEW.inc_date )::text ) INTO rn;
				SELECT COUNT( stock.id ) FROM stock WHERE stock.reagent_number = rn INTO seq_exist;
				
				IF seq_exist = 0 THEN
					EXIT;
				END IF;
		END LOOP;
		
		NEW.reagent_number := rn;

		RETURN NEW;
	
END;$$;


--
-- Name: MAKE_RECIPE_UNIQUE_INDEX_TRIG(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION "public"."MAKE_RECIPE_UNIQUE_INDEX_TRIG"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$

	DECLARE	
BEGIN

		NEW.unique_index = MD5( NEW.reagent_id::TEXT || ':'::TEXT || NEW.reactiv_menu_id::TEXT );
		RETURN NEW;
	
END;$$;


--
-- Name: UPDATE_DISPERSION_QUANTITY_SELF_TRIG(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION "public"."UPDATE_DISPERSION_QUANTITY_SELF_TRIG"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
	
	DECLARE

	fully_dispered 			float8;
	
BEGIN

	IF TG_OP = 'INSERT' THEN
		NEW.quantity_left = NEW.quantity_inc;
		RETURN NEW;
	END IF;

	SELECT coalesce(SUM(quantity), 0) FROM consume WHERE dispersion_id = NEW.id INTO fully_dispered;
	
	NEW.quantity_left = NEW.quantity_inc - fully_dispered;
	
	RETURN NEW;
	
END;$$;


--
-- Name: UPDATE_DISPERSION_QUANTITY_TRIG(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION "public"."UPDATE_DISPERSION_QUANTITY_TRIG"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
	
	DECLARE

	dispersion_quantity_inc 	float8;
	fully_used 			float8;
	curr_dispersion_id 			int8;
	
BEGIN

	IF TG_OP = 'INSERT' OR TG_OP = 'UPDATE' THEN
		curr_dispersion_id = NEW.dispersion_id;
	END IF;

	IF TG_OP != 'INSERT' AND TG_OP != 'UPDATE' THEN
		curr_dispersion_id = OLD.dispersion_id;
	END IF;

	SELECT quantity_inc FROM dispersion WHERE id = curr_dispersion_id INTO dispersion_quantity_inc;
	SELECT coalesce(SUM(quantity), 0) FROM consume WHERE dispersion_id = curr_dispersion_id INTO fully_used;
	
	dispersion_quantity_inc = dispersion_quantity_inc - fully_used;
	
	UPDATE dispersion SET quantity_left=dispersion_quantity_inc WHERE id=curr_dispersion_id;

	IF TG_OP = 'INSERT' OR TG_OP = 'UPDATE' THEN
		RETURN NEW;
	END IF;

	IF TG_OP != 'INSERT' AND TG_OP != 'UPDATE' THEN
		RETURN OLD;
	END IF;
	
END;$$;


--
-- Name: UPDATE_REACTIVE_CONSUME_AFTER_TRIG(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION "public"."UPDATE_REACTIVE_CONSUME_AFTER_TRIG"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
	
	DECLARE

	reactiv_quantity_inc 	float8;
	consumed 			float8;
	curr_reactive_hash 			text;
	
BEGIN

	IF TG_OP = 'INSERT' OR TG_OP = 'UPDATE' THEN
		curr_reactive_hash = NEW.reactive_hash;
	END IF;

	IF TG_OP != 'INSERT' AND TG_OP != 'UPDATE' THEN
		curr_reactive_hash = OLD.reactive_hash;
	END IF;

	SELECT quantity_inc FROM reactiv WHERE hash = curr_reactive_hash INTO reactiv_quantity_inc;
	
	SELECT coalesce(SUM( quantity ), 0) FROM reactiv_consume WHERE curr_reactive_hash = curr_reactive_hash INTO consumed;
	
	reactiv_quantity_inc = reactiv_quantity_inc - consumed;
	
	UPDATE reactiv SET quantity_left=reactiv_quantity_inc WHERE hash=curr_reactive_hash;

	IF TG_OP = 'INSERT' OR TG_OP = 'UPDATE' THEN
		RETURN NEW;
	END IF;

	IF TG_OP != 'INSERT' AND TG_OP != 'UPDATE' THEN
		RETURN OLD;
	END IF;
	
END;$$;


--
-- Name: UPDATE_REACTIVE_QUANTITY_SELF_TRIG(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION "public"."UPDATE_REACTIVE_QUANTITY_SELF_TRIG"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
	
	DECLARE

	fully_consumed 			float8;
	
BEGIN

	IF TG_OP = 'INSERT' THEN
		NEW.quantity_left = NEW.quantity_inc;
		RETURN NEW;
	END IF;

	SELECT coalesce(SUM( quantity ), 0) FROM reactiv_consume WHERE reactive_hash = NEW.hash INTO fully_consumed;
	
	NEW.quantity_left = NEW.quantity_inc - fully_consumed;
	
	RETURN NEW;
	
END;$$;


--
-- Name: UPDATE_STOCK_QUANTITY_SELF_TRIG(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION "public"."UPDATE_STOCK_QUANTITY_SELF_TRIG"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
	
	DECLARE

	fully_dispered 			float8;
	
BEGIN

	IF TG_OP = 'INSERT' THEN
		NEW.quantity_left = NEW.quantity_inc;
		RETURN NEW;
	END IF;

	SELECT coalesce(SUM(quantity_inc), 0) FROM dispersion WHERE stock_id = NEW.id INTO fully_dispered;
	
	NEW.quantity_left = NEW.quantity_inc - fully_dispered;
	
	RETURN NEW;
	
END;$$;


--
-- Name: UPDATE_STOCK_QUANTITY_TRIG(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION "public"."UPDATE_STOCK_QUANTITY_TRIG"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
	
	DECLARE

	stock_quantity_inc 	float8;
	fully_dispered 			float8;
	curr_stock_id 			int8;
	
BEGIN

	IF TG_OP = 'INSERT' OR TG_OP = 'UPDATE' THEN
		curr_stock_id = NEW.stock_id;
	END IF;

	IF TG_OP != 'INSERT' AND TG_OP != 'UPDATE' THEN
		curr_stock_id = OLD.stock_id;
	END IF;

	SELECT quantity_inc FROM stock WHERE id = curr_stock_id INTO stock_quantity_inc;
	SELECT coalesce(SUM(quantity_inc), 0) FROM dispersion WHERE stock_id = curr_stock_id INTO fully_dispered;
	
	stock_quantity_inc = stock_quantity_inc - fully_dispered;
	
	UPDATE stock SET quantity_left=stock_quantity_inc WHERE id=curr_stock_id;

	IF TG_OP = 'INSERT' OR TG_OP = 'UPDATE' THEN
		RETURN NEW;
	END IF;

	IF TG_OP != 'INSERT' AND TG_OP != 'UPDATE' THEN
		RETURN OLD;
	END IF;
	
END;$$;


--
-- Name: generate_hash("text"); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION "public"."generate_hash"("tab_name" "text") RETURNS "text"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
	DECLARE rhash TEXT;
  DECLARE cnt INTEGER;

-- nd1c.generate_hash('tbl_exp_bills'::text, 0)

BEGIN

	tab_name = tab_name::TEXT;
	cnt = 1;
	
	WHILE cnt > 0 LOOP

		rhash = md5( NOW()::text || tab_name::text || (random()*10000000)::text );
		EXECUTE 'SELECT COUNT(hash) as c FROM "' || tab_name || '" WHERE hash=' || quote_literal( rhash ) INTO cnt; 

	END LOOP;

	RETURN rhash;
END;$$;


SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: clearence; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE "public"."clearence" (
    "id" integer NOT NULL,
    "name" character varying(255) DEFAULT ''::character varying NOT NULL,
    "position" integer DEFAULT 0 NOT NULL
);


--
-- Name: clearence_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE "public"."clearence_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: clearence_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE "public"."clearence_id_seq" OWNED BY "public"."clearence"."id";


--
-- Name: consume; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE "public"."consume" (
    "hash" character varying(32) DEFAULT "public"."generate_hash"('consume'::"text") NOT NULL,
    "ts" timestamp(6) without time zone DEFAULT ("now"())::timestamp without time zone NOT NULL,
    "dispersion_id" bigint DEFAULT 0 NOT NULL,
    "inc_expert_id" bigint DEFAULT 0 NOT NULL,
    "quantity" double precision DEFAULT 0 NOT NULL,
    "using_hash" character varying(32) DEFAULT ''::character varying NOT NULL,
    "consume_ts" timestamp without time zone DEFAULT ("now"())::timestamp without time zone NOT NULL,
    "date" "date" DEFAULT '1970-01-01'::"date" NOT NULL
);


--
-- Name: COLUMN "consume"."inc_expert_id"; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN "public"."consume"."inc_expert_id" IS 'Хто використав';


--
-- Name: consume_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE "public"."consume_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: consume_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE "public"."consume_id_seq" OWNED BY "public"."consume"."hash";


--
-- Name: danger_class; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE "public"."danger_class" (
    "id" integer NOT NULL,
    "name" character varying(32) DEFAULT ''::character varying NOT NULL,
    "position" integer DEFAULT 0 NOT NULL
);


--
-- Name: danger_class_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE "public"."danger_class_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: danger_class_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE "public"."danger_class_id_seq" OWNED BY "public"."danger_class"."id";


--
-- Name: dispersion; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE "public"."dispersion" (
    "id" bigint NOT NULL,
    "stock_id" bigint DEFAULT 0 NOT NULL,
    "ts" timestamp(6) without time zone DEFAULT ("now"())::timestamp without time zone NOT NULL,
    "inc_expert_id" bigint DEFAULT 0 NOT NULL,
    "out_expert_id" bigint DEFAULT 0 NOT NULL,
    "quantity_inc" double precision DEFAULT 0 NOT NULL,
    "quantity_left" double precision DEFAULT 0 NOT NULL,
    "group_id" integer DEFAULT 0 NOT NULL,
    "inc_date" "date" DEFAULT '1970-01-01'::"date" NOT NULL,
    "comment" "text" DEFAULT ''::"text" NOT NULL,
    "created_ts" timestamp(6) with time zone DEFAULT ("now"())::timestamp without time zone NOT NULL
);


--
-- Name: COLUMN "dispersion"."inc_expert_id"; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN "public"."dispersion"."inc_expert_id" IS 'Хто отримав';


--
-- Name: COLUMN "dispersion"."out_expert_id"; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN "public"."dispersion"."out_expert_id" IS 'Хто видав';


--
-- Name: dispersion_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE "public"."dispersion_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: dispersion_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE "public"."dispersion_id_seq" OWNED BY "public"."dispersion"."id";


--
-- Name: expert; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE "public"."expert" (
    "id" bigint NOT NULL,
    "surname" character varying(255) DEFAULT ''::character varying NOT NULL,
    "name" character varying(255) DEFAULT ''::character varying NOT NULL,
    "phname" character varying(255) DEFAULT ''::character varying NOT NULL,
    "visible" smallint DEFAULT 1 NOT NULL,
    "ts" timestamp(6) without time zone DEFAULT ("now"())::timestamp without time zone NOT NULL,
    "login" character varying(32) DEFAULT ''::character varying NOT NULL,
    "password" character varying(32) DEFAULT ''::character varying NOT NULL,
    "token" character varying(40) DEFAULT ''::character varying NOT NULL,
    "group_id" integer DEFAULT 0 NOT NULL,
    "last_ip" "inet" DEFAULT '0.0.0.0'::"inet" NOT NULL
);


--
-- Name: expert_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE "public"."expert_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: expert_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE "public"."expert_id_seq" OWNED BY "public"."expert"."id";


--
-- Name: expertise; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE "public"."expertise" (
    "id" bigint NOT NULL,
    "region_id" integer DEFAULT 0 NOT NULL,
    "eint" character varying(255) DEFAULT ''::character varying NOT NULL,
    "inc_date" "date" DEFAULT '1970-01-01'::"date" NOT NULL
);


--
-- Name: expertise_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE "public"."expertise_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: expertise_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE "public"."expertise_id_seq" OWNED BY "public"."expertise"."id";


--
-- Name: groups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE "public"."groups" (
    "id" integer NOT NULL,
    "ts" timestamp(6) without time zone DEFAULT ("now"())::timestamp without time zone NOT NULL,
    "name" character varying(255) DEFAULT ''::character varying NOT NULL,
    "full_name" character varying(255) DEFAULT ''::character varying NOT NULL,
    "region_id" integer DEFAULT 0 NOT NULL
);


--
-- Name: groups_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE "public"."groups_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: groups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE "public"."groups_id_seq" OWNED BY "public"."groups"."id";


--
-- Name: purpose; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE "public"."purpose" (
    "id" integer NOT NULL,
    "name" character varying(255) DEFAULT ''::character varying NOT NULL,
    "ts" timestamp(6) without time zone DEFAULT ("now"())::timestamp without time zone NOT NULL,
    "attr" character varying(32) DEFAULT ''::character varying NOT NULL
);


--
-- Name: purpose_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE "public"."purpose_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: purpose_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE "public"."purpose_id_seq" OWNED BY "public"."purpose"."id";


--
-- Name: reactiv; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE "public"."reactiv" (
    "hash" character varying(32) DEFAULT "public"."generate_hash"('reactiv'::"text") NOT NULL,
    "reactiv_menu_id" bigint DEFAULT 0 NOT NULL,
    "quantity_inc" double precision DEFAULT 0 NOT NULL,
    "quantity_left" double precision DEFAULT 0 NOT NULL,
    "inc_expert_id" bigint DEFAULT 0 NOT NULL,
    "group_id" integer DEFAULT 0 NOT NULL,
    "inc_date" "date" DEFAULT '1970-01-01'::"date" NOT NULL,
    "dead_date" "date" DEFAULT '1970-01-01'::"date" NOT NULL,
    "safe_place" character varying(255) DEFAULT ''::character varying NOT NULL,
    "safe_needs" character varying(255) DEFAULT ''::character varying NOT NULL,
    "comment" "text" DEFAULT ''::"text" NOT NULL,
    "using_hash" character varying(32) DEFAULT ''::character varying NOT NULL
);


--
-- Name: reactiv_consume; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE "public"."reactiv_consume" (
    "hash" character varying(32) DEFAULT "public"."generate_hash"('reactiv_consume'::"text") NOT NULL,
    "reactive_hash" character varying(32) DEFAULT ''::character varying NOT NULL,
    "quantity" double precision DEFAULT 0 NOT NULL,
    "inc_expert_id" bigint DEFAULT 0 NOT NULL,
    "using_hash" character varying(32) DEFAULT ''::character varying NOT NULL,
    "consume_ts" timestamp(6) without time zone DEFAULT ("now"())::timestamp without time zone NOT NULL,
    "ts" timestamp(6) without time zone DEFAULT ("now"())::timestamp without time zone NOT NULL,
    "date" "date" DEFAULT '1970-01-01'::"date" NOT NULL
);


--
-- Name: reactiv_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE "public"."reactiv_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: reactiv_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE "public"."reactiv_id_seq" OWNED BY "public"."reactiv"."hash";


--
-- Name: reactiv_menu; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE "public"."reactiv_menu" (
    "id" bigint NOT NULL,
    "name" character varying(255) DEFAULT 0 NOT NULL,
    "position" integer DEFAULT 0 NOT NULL,
    "units_id" integer DEFAULT 0 NOT NULL,
    "comment" "text" DEFAULT ''::"text" NOT NULL
);


--
-- Name: reactiv_menu_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE "public"."reactiv_menu_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: reactiv_menu_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE "public"."reactiv_menu_id_seq" OWNED BY "public"."reactiv_menu"."id";


--
-- Name: reactiv_menu_ingredients; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE "public"."reactiv_menu_ingredients" (
    "reagent_id" bigint NOT NULL,
    "reactiv_menu_id" bigint DEFAULT 0 NOT NULL,
    "unique_index" character varying(255) DEFAULT ''::character varying NOT NULL
);


--
-- Name: reagent; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE "public"."reagent" (
    "id" bigint NOT NULL,
    "ts" timestamp(6) without time zone DEFAULT ("now"())::timestamp without time zone NOT NULL,
    "name" character varying(255) DEFAULT ''::character varying NOT NULL,
    "created_by_expert_id" bigint DEFAULT 0 NOT NULL,
    "units_id" integer DEFAULT 0 NOT NULL
);


--
-- Name: reagent_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE "public"."reagent_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: reagent_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE "public"."reagent_id_seq" OWNED BY "public"."reagent"."id";


--
-- Name: reagent_state; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE "public"."reagent_state" (
    "id" integer NOT NULL,
    "name" character varying(32) DEFAULT ''::character varying NOT NULL,
    "position" integer DEFAULT 0 NOT NULL
);


--
-- Name: reagent_state_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE "public"."reagent_state_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: reagent_state_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE "public"."reagent_state_id_seq" OWNED BY "public"."reagent_state"."id";


--
-- Name: region; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE "public"."region" (
    "id" integer NOT NULL,
    "ts" timestamp(6) without time zone DEFAULT ("now"())::timestamp without time zone NOT NULL,
    "name" character varying(255) DEFAULT ''::character varying NOT NULL,
    "position" integer DEFAULT 0 NOT NULL
);


--
-- Name: region_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE "public"."region_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: region_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE "public"."region_id_seq" OWNED BY "public"."region"."id";


--
-- Name: stock; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE "public"."stock" (
    "id" bigint NOT NULL,
    "ts" timestamp(6) without time zone DEFAULT ("now"())::timestamp without time zone NOT NULL,
    "reagent_id" bigint DEFAULT 0 NOT NULL,
    "quantity_inc" double precision DEFAULT 0 NOT NULL,
    "inc_date" "date" DEFAULT '1970-01-01'::"date" NOT NULL,
    "inc_expert_id" bigint DEFAULT 0 NOT NULL,
    "group_id" integer DEFAULT 0 NOT NULL,
    "quantity_left" double precision DEFAULT 0 NOT NULL,
    "clearence_id" integer DEFAULT 0 NOT NULL,
    "create_date" "date" DEFAULT '1970-01-01'::"date" NOT NULL,
    "dead_date" "date" DEFAULT '1970-01-01'::"date" NOT NULL,
    "is_sertificat" smallint DEFAULT 0 NOT NULL,
    "creator" "text" DEFAULT ''::"text" NOT NULL,
    "reagent_state_id" integer DEFAULT 0 NOT NULL,
    "danger_class_id" integer DEFAULT 0 NOT NULL,
    "is_suitability" smallint DEFAULT 0 NOT NULL,
    "comment" "text" DEFAULT ''::"text" NOT NULL,
    "safe_place" character varying(255) DEFAULT ''::character varying NOT NULL,
    "safe_needs" character varying(255) DEFAULT ''::character varying NOT NULL,
    "created_ts" timestamp(6) without time zone DEFAULT ("now"())::timestamp without time zone NOT NULL,
    "reagent_number" character varying DEFAULT ''::character varying NOT NULL,
    "provider" "text" DEFAULT ''::"text" NOT NULL,
    "nakladna_num" character varying(32) DEFAULT ''::character varying NOT NULL,
    "nakladna_date" "date" DEFAULT '1970-01-01'::"date" NOT NULL
);


--
-- Name: COLUMN "stock"."inc_expert_id"; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN "public"."stock"."inc_expert_id" IS 'Хто отримав';


--
-- Name: COLUMN "stock"."clearence_id"; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN "public"."stock"."clearence_id" IS 'Ступінь чистоти';


--
-- Name: COLUMN "stock"."create_date"; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN "public"."stock"."create_date" IS 'Дата виробництва';


--
-- Name: COLUMN "stock"."dead_date"; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN "public"."stock"."dead_date" IS 'Кінцева дата зберігання';


--
-- Name: COLUMN "stock"."is_suitability"; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN "public"."stock"."is_suitability" IS 'Висновок про придатність';


--
-- Name: COLUMN "stock"."comment"; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN "public"."stock"."comment" IS 'comment';


--
-- Name: COLUMN "stock"."created_ts"; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN "public"."stock"."created_ts" IS 'Дата створення запису (службова інфа)';


--
-- Name: stock_gr_0_2020_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE "public"."stock_gr_0_2020_seq"
    START WITH 1
    INCREMENT BY 1
    MINVALUE 0
    NO MAXVALUE
    CACHE 1;


--
-- Name: stock_gr_1_2015_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE "public"."stock_gr_1_2015_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: stock_gr_1_2016_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE "public"."stock_gr_1_2016_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: stock_gr_1_2017_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE "public"."stock_gr_1_2017_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: stock_gr_1_2018_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE "public"."stock_gr_1_2018_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: stock_gr_1_2019_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE "public"."stock_gr_1_2019_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: stock_gr_1_2020_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE "public"."stock_gr_1_2020_seq"
    START WITH 1
    INCREMENT BY 1
    MINVALUE 0
    NO MAXVALUE
    CACHE 1;


--
-- Name: stock_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE "public"."stock_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: stock_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE "public"."stock_id_seq" OWNED BY "public"."stock"."id";


--
-- Name: units; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE "public"."units" (
    "id" integer NOT NULL,
    "name" character varying(255) DEFAULT ''::character varying NOT NULL,
    "position" integer DEFAULT 0 NOT NULL,
    "short_name" character varying(32) DEFAULT ''::character varying NOT NULL
);


--
-- Name: units_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE "public"."units_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: units_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE "public"."units_id_seq" OWNED BY "public"."units"."id";


--
-- Name: using; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE "public"."using" (
    "hash" character varying(32) DEFAULT "public"."generate_hash"('using'::"text") NOT NULL,
    "purpose_id" integer DEFAULT 0 NOT NULL,
    "date" "date" DEFAULT '1970-01-01'::"date" NOT NULL,
    "group_id" integer DEFAULT 0 NOT NULL,
    "exp_number" character varying(32) DEFAULT ''::character varying NOT NULL,
    "exp_date" "date" DEFAULT '1970-01-01'::"date" NOT NULL,
    "obj_count" integer DEFAULT 0 NOT NULL,
    "tech_info" "text" DEFAULT ''::"text" NOT NULL,
    "ucomment" "text" DEFAULT ''::"text" NOT NULL
);


--
-- Name: clearence id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."clearence" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."clearence_id_seq"'::"regclass");


--
-- Name: danger_class id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."danger_class" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."danger_class_id_seq"'::"regclass");


--
-- Name: dispersion id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."dispersion" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."dispersion_id_seq"'::"regclass");


--
-- Name: expert id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."expert" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."expert_id_seq"'::"regclass");


--
-- Name: expertise id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."expertise" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."expertise_id_seq"'::"regclass");


--
-- Name: groups id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."groups" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."groups_id_seq"'::"regclass");


--
-- Name: purpose id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."purpose" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."purpose_id_seq"'::"regclass");


--
-- Name: reactiv_menu id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."reactiv_menu" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."reactiv_menu_id_seq"'::"regclass");


--
-- Name: reagent id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."reagent" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."reagent_id_seq"'::"regclass");


--
-- Name: reagent_state id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."reagent_state" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."reagent_state_id_seq"'::"regclass");


--
-- Name: region id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."region" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."region_id_seq"'::"regclass");


--
-- Name: stock id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."stock" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."stock_id_seq"'::"regclass");


--
-- Name: units id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."units" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."units_id_seq"'::"regclass");


--
-- Data for Name: clearence; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO "public"."clearence" ("id", "name", "position") VALUES (0, '--', 0);
INSERT INTO "public"."clearence" ("id", "name", "position") VALUES (1, 'Технічний (тех.)', 0);
INSERT INTO "public"."clearence" ("id", "name", "position") VALUES (9, 'Особливо чистий (ос.ч)', 0);
INSERT INTO "public"."clearence" ("id", "name", "position") VALUES (2, 'Чистий (ч.)', 0);
INSERT INTO "public"."clearence" ("id", "name", "position") VALUES (8, 'Хімічно чистий (х.ч)', 0);
INSERT INTO "public"."clearence" ("id", "name", "position") VALUES (7, 'Чистий для аналізу (ч.д.а)', 0);
INSERT INTO "public"."clearence" ("id", "name", "position") VALUES (10, 'Для хроматографії', 0);
INSERT INTO "public"."clearence" ("id", "name", "position") VALUES (11, 'Фармацевтичний (фарм.)', 0);


--
-- Data for Name: consume; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "using_hash", "consume_ts", "date") VALUES ('', '2020-01-02 15:37:30.168681', 0, 0, 0, '', '2020-03-18 16:07:51.03563', '1970-01-01');


--
-- Data for Name: danger_class; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO "public"."danger_class" ("id", "name", "position") VALUES (0, '--', 0);
INSERT INTO "public"."danger_class" ("id", "name", "position") VALUES (3, 'Перший (І)', 0);
INSERT INTO "public"."danger_class" ("id", "name", "position") VALUES (2, 'Другий (ІІ)', 0);
INSERT INTO "public"."danger_class" ("id", "name", "position") VALUES (1, 'Третій (ІІІ)', 0);
INSERT INTO "public"."danger_class" ("id", "name", "position") VALUES (4, 'Четвертий (IV)', 0);
INSERT INTO "public"."danger_class" ("id", "name", "position") VALUES (5, 'Хімічна речовина', 0);
INSERT INTO "public"."danger_class" ("id", "name", "position") VALUES (6, 'Розхідний матеріал', 0);


--
-- Data for Name: dispersion; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO "public"."dispersion" ("id", "stock_id", "ts", "inc_expert_id", "out_expert_id", "quantity_inc", "quantity_left", "group_id", "inc_date", "comment", "created_ts") VALUES (0, 0, '2020-01-02 15:37:24.48078', 0, 0, 0, 0, 0, '1970-01-01', '', '2020-03-13 11:54:36.766118+02');
INSERT INTO "public"."dispersion" ("id", "stock_id", "ts", "inc_expert_id", "out_expert_id", "quantity_inc", "quantity_left", "group_id", "inc_date", "comment", "created_ts") VALUES (19, 327, '2020-04-14 14:21:55.06768', 3, 3, 5, 5, 1, '2020-04-14', 'Поміщено в холодильник для зберігання та використання в приготуванні розчинів', '2020-04-14 14:21:55.06768+03');
INSERT INTO "public"."dispersion" ("id", "stock_id", "ts", "inc_expert_id", "out_expert_id", "quantity_inc", "quantity_left", "group_id", "inc_date", "comment", "created_ts") VALUES (20, 226, '2020-04-14 14:40:23.706829', 3, 3, 1, 1, 1, '2020-04-14', 'На використання при дослідженні спиртів', '2020-04-14 14:40:23.706829+03');
INSERT INTO "public"."dispersion" ("id", "stock_id", "ts", "inc_expert_id", "out_expert_id", "quantity_inc", "quantity_left", "group_id", "inc_date", "comment", "created_ts") VALUES (21, 340, '2020-04-14 15:59:52.218936', 3, 3, 4, 4, 1, '2020-04-14', 'На використання при дослідженні спиртів', '2020-04-14 15:59:52.218936+03');
INSERT INTO "public"."dispersion" ("id", "stock_id", "ts", "inc_expert_id", "out_expert_id", "quantity_inc", "quantity_left", "group_id", "inc_date", "comment", "created_ts") VALUES (22, 342, '2020-04-14 16:23:04.221482', 3, 3, 2000, 2000, 1, '2020-04-14', 'Передано в сектор біологів для використання в дослідженнях', '2020-04-14 16:23:04.221482+03');


--
-- Data for Name: expert; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO "public"."expert" ("id", "surname", "name", "phname", "visible", "ts", "login", "password", "token", "group_id", "last_ip") VALUES (0, '', '', '', 1, '2019-12-28 11:10:20.623791', '', '', '', 0, '0.0.0.0');
INSERT INTO "public"."expert" ("id", "surname", "name", "phname", "visible", "ts", "login", "password", "token", "group_id", "last_ip") VALUES (3, 'Шинкаренко', 'Дмитро', 'Юрійович', 1, '2020-03-24 17:12:38.05303', 'shinkarenko', '953adda3778dcf339f8debe9a72dcc34', '093bd45f8fd80b2f6b71290c2497c7f0', 1, '192.168.2.127');
INSERT INTO "public"."expert" ("id", "surname", "name", "phname", "visible", "ts", "login", "password", "token", "group_id", "last_ip") VALUES (1, 'Пташкін', 'Роман', 'Леонідович', 1, '2019-12-29 23:17:39.53982', 'root', '855cb86bd065112c52899ef9ea7b9918', 'c76ef91266a649b488083ce845961f61', 1, '46.255.34.254');
INSERT INTO "public"."expert" ("id", "surname", "name", "phname", "visible", "ts", "login", "password", "token", "group_id", "last_ip") VALUES (2, 'Шкурдода', 'Сергій', 'Вікторович', 1, '2020-03-18 15:24:55.417367', 'shkurdoda', 'd80daf84242523a7c25c1162a314d3d3', '5a1b6334917e6194caf45ed52349475f', 1, '192.168.2.118');


--
-- Data for Name: expertise; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO "public"."expertise" ("id", "region_id", "eint", "inc_date") VALUES (0, 0, '0', '1970-01-01');


--
-- Data for Name: groups; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO "public"."groups" ("id", "ts", "name", "full_name", "region_id") VALUES (0, '2019-12-28 11:09:48.499219', '--', '--', 0);
INSERT INTO "public"."groups" ("id", "ts", "name", "full_name", "region_id") VALUES (1, '2019-12-29 23:20:15.009224', 'root', 'root', 1);


--
-- Data for Name: purpose; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO "public"."purpose" ("id", "name", "ts", "attr") VALUES (0, '--', '2019-12-28 11:09:37.583434', '');
INSERT INTO "public"."purpose" ("id", "name", "ts", "attr") VALUES (3, 'Приготування робочого реактиву', '2020-03-18 16:12:38.948107', 'reactiv');
INSERT INTO "public"."purpose" ("id", "name", "ts", "attr") VALUES (1, 'Проведення дослідження (експертизи)', '2020-03-17 14:02:01.806052', 'expertise');
INSERT INTO "public"."purpose" ("id", "name", "ts", "attr") VALUES (2, 'Технічне обслуговування обладнання', '2020-03-17 14:06:40.671071', 'maintenance');


--
-- Data for Name: reactiv; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO "public"."reactiv" ("hash", "reactiv_menu_id", "quantity_inc", "quantity_left", "inc_expert_id", "group_id", "inc_date", "dead_date", "safe_place", "safe_needs", "comment", "using_hash") VALUES ('', 0, 0, 0, 0, 0, '1970-01-01', '1970-01-01', '', '', '', '');


--
-- Data for Name: reactiv_consume; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: reactiv_menu; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO "public"."reactiv_menu" ("id", "name", "position", "units_id", "comment") VALUES (0, '--', 0, 0, '');
INSERT INTO "public"."reactiv_menu" ("id", "name", "position", "units_id", "comment") VALUES (9, 'Реагент 2. 5% розчин сульфата заліза (ІІІ)', 0, 1, 'PT13T3lGR2N5WnlPNU4yYTFsa0o3azNZclZYU21zVGVqdFdkSlp5T3lGR2NzWkNJN2szWWhaeU81Tm1lbXNUZWp0V2RwWnlPNU5HYm1zVGVqRm1KN2szWTZaQ0k3azNZMVp5TzVOR2Rtc1RlakZtSjdrM1ltWnlPNU5HZG05MmNtc1RlanhtSjdrM1kxWnlPNU4yY21BeU81TjJabUFTTmdzVGVqbG1KN2szWTBaeU81TldhbXNUZWo1bUo3azNZcFp5TzVOR2FqWnlPNU5tZW1zVGVqOW1KN2szWXlaQ0k3azNZcFp5TzVOR1ptc1RlajltSjdrM1kyWkNJN2szWXBsbko3azNZdlp5TzVObWJtc1RlakZtSjdrM1kyWnlPNU4yYm1zVGVqcG5KN2szWXJWWGFtc1RlajVtSjdrM1l2WnlPNU5tYW1zVGVqVldhbXNUZWpSbUpnc1RlanhtSjdrM1l0WkNJd0FUTWdzVGVqWmxKN2tXYmxObkp3RXpPdFZuYm1zVGF0VjJjbWd6TTcwV2R1WnlPdzFXWW1zamNoQm5jbXNUZWp0V2RKWnlPNU4yYTFsa0o3azNZclZYU21zamNoQkhibUF5TzVOV1ltc1RlanBuSjdrM1lyVlhhbXNUZWp4bUo3azNZaFp5TzVObWVtQXlPNU5XYm1zVGVqOW1KN2szWTBaeU81TldZbXNUZWpabUo3azNZMFoyYnpaeU81TkdibXNUZWpWbko3azNZelpDSTdrM1k2WkNJN2szWTBaeU81TjJjbXNUZWpWV2Ftc1RlalJsSg%3D%3D');
INSERT INTO "public"."reactiv_menu" ("id", "name", "position", "units_id", "comment") VALUES (21, 'Реагент 16А. Тест з динітробензолом', 0, 1, 'N2tXYmxObkp3RXpPdFZuYm1zVGF0VjJjbWd6TTcwV2R1WnlPdzFXWW1zamJ2eDJialp5TzVOV2Rtc1RlalJuSjdrM1l6WnlPNU5XWnBaeU81TkdkbUF5TzVOV1k1WnlPNU5tYm1zVGVqNW1KN2szWWhaeU81Tm1ibXNUZWo5bUo3azNZclp5TzVOV2Ftc1RlalpsSjdrV2JsTm5Kd0V6T3RWbmJtc1RhdFYyY21nek03MFdkdVp5T3cxV1ltc1RhdFYyY21BVE03MFdkdVp5T3AxV1p6WkNPenNUYjE1bUo3QVhiaFp5T2s5V2F5VkdjbXNUZWpGV2Vtc1RlanhtSjdrM1l2WnlPNU4yYW1zVGVqdFdkcFp5TzVOR2Jtc1RlamRtSjdrM1l1WnlPNU5XWnBaeU81TkdibXNUZWpsbUo3azNZMFp5TzVOV1pwWnlPNU4yYTFsbUo3azNZc1p5TzVOMmJtc1RlakJuSmdzVGVqeG1KN2szWXRaQ0l3QVRNZ3NUZWpabkpnc1RlalZuSjdrM1lzWnlPNU4yYm1zVGVqcG5KN2szWXVaeU81TldacFp5TzVObVltc1RlajltSjdrM1l5WnlPNU5HZG1zVGVqdFdkcFp5TzVObWJtc1RlamxtSjdrM1lrWkNJMEF5T2gxV2J2Tm1KeEF5TzVOMlptQVNNZ3NUZWpsbUo3azNZMFp5TzVOV2Ftc1RlajVtSjdrM1lwWnlPNU5HYWpaeU81Tm1lbXNUZWo5bUo3azNZU1pDSUVaVE03a1dibE5uSndFek90Vm5ibXNUYXRWMmNtZ3pNNzBXZHVaeU93MVdZbXNUZWpGV2Vtc1RlanhtSjdrM1l2WnlPNU4yYW1zVGVqdFdkcFp5TzVOR2Jtc1RlamRtSjdrM1l1WnlPNU5XWnBaeU81TkdibXNUZWpsbUo3azNZMFp5TzVOV1pwWnlPNU4yYTFsbUo3azNZc1p5TzVOMmJtc1RlakJuSmdzVGVqeG1KN2szWXRaQ0l3QVRNZ3NUZWpabkpnc1RlalZuSjdrM1lzWnlPNU4yYm1zVGVqcG5KN2szWXVaeU81TldacFp5TzVObVltc1RlajltSjdrM1l5WnlPNU5HZG1zVGVqdFdkcFp5TzVObWJtc1RlamxtSjdrM1lrWkNJenNUWXQxMmJqWlNNZ3NUZWpkbUpnRURJN2szWXBaeU81TkdkbXNUZWpsbUo3azNZdVp5TzVOV2Ftc1RlamgyWW1zVGVqcG5KN2szWXZaeU81Tm1VbUF5TzVOMlVtWVRNZ3NUZWpSbko3azNZdVp5TzVOV1pwWnlPNU4yWm1zVGVqRm1KN2szWWxsbUo3azNZU1p5T3AxV1p6WkNNeHNUYjE1bUo3a1dibE5uSjRNek90Vm5ibXNEY3RGbUo3UTJicEpYWndaeU81TldhbXNUZWpSbUo3azNZdlp5TzVObWRtQXlPNU5HYm1zVGVqMW1KZ0FETXhBeU81Tm1kbUF5TzVOV2Rtc1RlalJtSjdrM1lwWnlPNU4yY21zVGVqdG1KN2szWXZaeU81Tm1jbXNUZWpSbUo3azNZclZYYW1zVGVqZG1KZ3NUZWpwbUo3azNZcFp5TzVOR2Rtc1RlanRXZHBaeU81TkdibUFDTXhBeU81TldhbXNUZWpSbko3azNZcFp5TzVObWJtc1RlamxtSjdrM1lvTm1KN2szWTZaeU81TjJibXNUZWpKbEpnc0RadmxtY2xCbko3azNZV1pDSTJFREk3azNZMFp5TzVObWJtc1RlalZXYW1zVGVqZG1KN2szWWhaeU81TldacFp5TzVObVVtc1RhdFYyY21BVE03MFdkdVp5T3AxV1p6WkNPenNUYjE1bUo3QVhiaFp5T2s5V2F5VkdjbXNUZWpGV2Vtc1RlanhtSjdrM1l2WnlPNU4yYW1zVGVqdFdkcFp5TzVOR2Jtc1RlamRtSjdrM1l1WnlPNU5XWnBaeU81TkdibXNUZWpsbUo3azNZMFp5TzVOV1pwWnlPNU4yYTFsbUo3azNZc1p5TzVOMmJtc1RlakJuSmdzVGVqeG1KN2szWXRaQ0l3QVRNZ3NUZWpabkpnc1RlalZuSjdrM1lzWnlPNU4yYm1zVGVqcG5KN2szWXVaeU81TldacFp5TzVObVltc1RlajltSjdrM1l5WnlPNU5HZG1zVGVqdFdkcFp5TzVObWJtc1RlamxtSjdrM1lrWkNJeXNUWXQxMmJqWlNNZ3NUZWpkbUpnRURJN1EyYnBKWFp3WnlPNU5XUW1ZVE1nc1RlalJuSjdrM1l1WnlPNU5XWnBaeU81TjJabXNUZWpGbUo3azNZbGxtSjdrM1lTWnlPcDFXWnpaQ014c1RiMTVtSjdrV2JsTm5KNE16T3RWbmJtc0RjdEZtSjdrM1kxWnlPNU5tYm1zVGVqdFdkcFp5TzVOR2Jtc1RlajltSjdrM1l0WnlPNU5XWnBaeU81TkdjbUF5TzVOR2RtOTJjbXNUZWpSbko3azNZelp5TzVOMmExbG1KN2szWXVaeU81TkdkbXNUZWpWbko3azNZelp5TzVOV2Ftc1RlakpuSjdrM1l3WkNJN2szWWhaeU81Tm1ibUF5TzVOV2Jtc1RlajltSjdrM1lzWnlPNU4yYm1zVGVqcG5KN2szWXVaeU81TldacFp5TzVObVltc1RlajltSjdrM1l5WnlPNU5HZG1zVGVqdFdkcFp5TzVObWJtc1RlamxtSjdrM1lrWkNJN2szWTZaQ0k3azNZMFp5TzVOMmNtc1RlalZXYW1zVGVqUmxK');
INSERT INTO "public"."reactiv_menu" ("id", "name", "position", "units_id", "comment") VALUES (7, 'Реактив Маркі', 0, 1, 'PXNUZWpWbko3azNZdVp5TzVOMmExbG1KN2szWXNaeU81TldZbXNUZWoxbUo3azNZeVp5TzVOMmJtc1RlalptSmdzVGVqVm5KN2szWXVaeU81TldhbXNUZWpoMlltc1RlajltSjdrM1l5WkNJN1FuYmpKWFp3WnlOekF5TzVOR2Jtc1RlajFtSmdFREk3azNZcFp5TzVOR2Rtc1RlakZtSjdrM1lrWnlPNU4yYm1zVGVqUm1KZ3NUZWpsbUo3azNZMFp5TzVOMmJtc1RlanhtSjdrM1l6WnlPNU5XYW1zVGVqdG1KZ3NUZWpsV2Vtc1RlajltSjdrM1l1WnlPNU5HZG1zVGVqRm1KN2szWW1aeU81TkdkbTkyY21zVGVqeG1KN2szWTFaeU81TjJjbUF5TzVOV2E1WnlPNU4yYm1zVGVqNW1KN2szWWhaeU81Tm1kbXNUZWo5bUo3azNZeVp5TzVOR2Rtc1RlajVtSjdrM1lsbG1KN2szWXpSbko3azNZdVp5TzVOMmJtc1RlanRtSmdzVGVqeG1KN2szWXRaQ0k1QXlPNU4yYm1zVGVqUmtK');
INSERT INTO "public"."reactiv_menu" ("id", "name", "position", "units_id", "comment") VALUES (24, 'Реагент 16D. Тест з динітробензолом', 0, 1, 'PXNqYnZ4MmJqWnlPNU5XZG1zVGVqUm5KN2szWXpaeU81TldacFp5TzVOR2RtQXlPNU5XWTVaeU81Tm1ibXNUZWo1bUo3azNZaFp5TzVObWJtc1RlajltSjdrM1lyWnlPNU5XYW1zVGVqWmxKN2tXYmxObkp3RXpPdFZuYm1zVGF0VjJjbWd6TTcwV2R1WnlPdzFXWW1zVGF0VjJjbUFUTTcwV2R1WnlPcDFXWnpaQ096c1RiMTVtSjdBWGJoWnlPazlXYXlWR2Ntc1RlakZXZW1zVGVqeG1KN2szWXZaeU81TjJhbXNUZWp0V2RwWnlPNU5HYm1zVGVqZG1KN2szWXVaeU81TldacFp5TzVOR2Jtc1RlamxtSjdrM1kwWnlPNU5XWnBaeU81TjJhMWxtSjdrM1lzWnlPNU4yYm1zVGVqQm5KZ3NUZWp4bUo3azNZdFpDSXdBVE1nc1RlalpuSmdzVGVqVm5KN2szWXNaeU81TjJibXNUZWpwbko3azNZdVp5TzVOV1pwWnlPNU5tWW1zVGVqOW1KN2szWXlaeU81TkdkbXNUZWp0V2RwWnlPNU5tYm1zVGVqbG1KN2szWWtaQ0kwQXlPaDFXYnZObUp4QXlPNU4yWm1BU01nc1RlamxtSjdrM1kwWnlPNU5XYW1zVGVqNW1KN2szWXBaeU81Tkdhalp5TzVObWVtc1RlajltSjdrM1lTWkNJRVpUTTdrV2JsTm5Kd0V6T3RWbmJtc1RhdFYyY21nek03MFdkdVp5T3cxV1ltc1RlakZXZW1zVGVqeG1KN2szWXZaeU81TjJhbXNUZWp0V2RwWnlPNU5HYm1zVGVqZG1KN2szWXVaeU81TldacFp5TzVOR2Jtc1RlamxtSjdrM1kwWnlPNU5XWnBaeU81TjJhMWxtSjdrM1lzWnlPNU4yYm1zVGVqQm5KZ3NUZWp4bUo3azNZdFpDSXdBVE1nc1RlalpuSmdzVGVqVm5KN2szWXNaeU81TjJibXNUZWpwbko3azNZdVp5TzVOV1pwWnlPNU5tWW1zVGVqOW1KN2szWXlaeU81TkdkbXNUZWp0V2RwWnlPNU5tYm1zVGVqbG1KN2szWWtaQ0l6c1RZdDEyYmpaU01nc1RlamRtSmdFREk3azNZcFp5TzVOR2Rtc1RlamxtSjdrM1l1WnlPNU5XYW1zVGVqaDJZbXNUZWpwbko3azNZdlp5TzVObVVtQXlPNU4yVW1ZVE1nc1RlalJuSjdrM1l1WnlPNU5XWnBaeU81TjJabXNUZWpGbUo3azNZbGxtSjdrM1lTWnlPcDFXWnpaQ014c1RiMTVtSjdrV2JsTm5KNE16T3RWbmJtc0RjdEZtSjdRMmJwSlhad1p5TzVOV2Ftc1RlalJtSjdrM1l2WnlPNU5tZG1BeU81TkdibXNUZWoxbUpnQURNeEF5TzVObWRtQXlPNU5XZG1zVGVqUm1KN2szWXBaeU81TjJjbXNUZWp0bUo3azNZdlp5TzVObWNtc1RlalJtSjdrM1lyVlhhbXNUZWpkbUpnc1RlanBtSjdrM1lwWnlPNU5HZG1zVGVqdFdkcFp5TzVOR2JtQUNNeEF5TzVOV2Ftc1RlalJuSjdrM1lwWnlPNU5tYm1zVGVqbG1KN2szWW9ObUo3azNZNlp5TzVOMmJtc1RlakpsSmdzRFp2bG1jbEJuSjdrM1lXWkNJMkVESTdrM1kwWnlPNU5tYm1zVGVqVldhbXNUZWpkbUo3azNZaFp5TzVOV1pwWnlPNU5tVW1zVGF0VjJjbUFUTTcwV2R1WnlPcDFXWnpaQ096c1RiMTVtSjdBWGJoWnlPazlXYXlWR2Ntc1RlakZXZW1zVGVqeG1KN2szWXZaeU81TjJhbXNUZWp0V2RwWnlPNU5HYm1zVGVqZG1KN2szWXVaeU81TldacFp5TzVOR2Jtc1RlamxtSjdrM1kwWnlPNU5XWnBaeU81TjJhMWxtSjdrM1lzWnlPNU4yYm1zVGVqQm5KZ3NUZWp4bUo3azNZdFpDSXdBVE1nc1RlalpuSmdzVGVqVm5KN2szWXNaeU81TjJibXNUZWpwbko3azNZdVp5TzVOV1pwWnlPNU5tWW1zVGVqOW1KN2szWXlaeU81TkdkbXNUZWp0V2RwWnlPNU5tYm1zVGVqbG1KN2szWWtaQ0l5c1RZdDEyYmpaU01nc1RlamRtSmdFREk3UTJicEpYWndaeU81TldRbVlUTWdzVGVqUm5KN2szWXVaeU81TldacFp5TzVOMlptc1RlakZtSjdrM1lsbG1KN2szWVNaeU9wMVdaelpDTXhzVGIxNW1KN2tXYmxObko0TXpPdFZuYm1zRGN0Rm1KN2szWTFaeU81Tm1ibXNUZWp0V2RwWnlPNU5HYm1zVGVqOW1KN2szWXRaeU81TldacFp5TzVOR2NtQXlPNU5HZG05MmNtc1RlalJuSjdrM1l6WnlPNU4yYTFsbUo3azNZdVp5TzVOR2Rtc1RlalZuSjdrM1l6WnlPNU5XYW1zVGVqSm5KN2szWXdaQ0k3azNZaFp5TzVObWJtQXlPNU5XYm1zVGVqOW1KN2szWXNaeU81TjJibXNUZWpwbko3azNZdVp5TzVOV1pwWnlPNU5tWW1zVGVqOW1KN2szWXlaeU81TkdkbXNUZWp0V2RwWnlPNU5tYm1zVGVqbG1KN2szWWtaQ0k3azNZNlpDSTdrM1kwWnlPNU4yY21zVGVqVldhbXNUZWpSbEo%3D');
INSERT INTO "public"."reactiv_menu" ("id", "name", "position", "units_id", "comment") VALUES (22, 'Реагент 16 В. Тест з динітробензолом', 0, 1, 'PXNqYnZ4MmJqWnlPNU5XZG1zVGVqUm5KN2szWXpaeU81TldacFp5TzVOR2RtQXlPNU5XWTVaeU81Tm1ibXNUZWo1bUo3azNZaFp5TzVObWJtc1RlajltSjdrM1lyWnlPNU5XYW1zVGVqWmxKN2tXYmxObkp3RXpPdFZuYm1zVGF0VjJjbWd6TTcwV2R1WnlPdzFXWW1zVGF0VjJjbUFUTTcwV2R1WnlPcDFXWnpaQ096c1RiMTVtSjdBWGJoWnlPazlXYXlWR2Ntc1RlakZXZW1zVGVqeG1KN2szWXZaeU81TjJhbXNUZWp0V2RwWnlPNU5HYm1zVGVqZG1KN2szWXVaeU81TldacFp5TzVOR2Jtc1RlamxtSjdrM1kwWnlPNU5XWnBaeU81TjJhMWxtSjdrM1lzWnlPNU4yYm1zVGVqQm5KZ3NUZWp4bUo3azNZdFpDSXdBVE1nc1RlalpuSmdzVGVqVm5KN2szWXNaeU81TjJibXNUZWpwbko3azNZdVp5TzVOV1pwWnlPNU5tWW1zVGVqOW1KN2szWXlaeU81TkdkbXNUZWp0V2RwWnlPNU5tYm1zVGVqbG1KN2szWWtaQ0kwQXlPaDFXYnZObUp4QXlPNU4yWm1BU01nc1RlamxtSjdrM1kwWnlPNU5XYW1zVGVqNW1KN2szWXBaeU81Tkdhalp5TzVObWVtc1RlajltSjdrM1lTWkNJRVpUTTdrV2JsTm5Kd0V6T3RWbmJtc1RhdFYyY21nek03MFdkdVp5T3cxV1ltc1RlakZXZW1zVGVqeG1KN2szWXZaeU81TjJhbXNUZWp0V2RwWnlPNU5HYm1zVGVqZG1KN2szWXVaeU81TldacFp5TzVOR2Jtc1RlamxtSjdrM1kwWnlPNU5XWnBaeU81TjJhMWxtSjdrM1lzWnlPNU4yYm1zVGVqQm5KZ3NUZWp4bUo3azNZdFpDSXdBVE1nc1RlalpuSmdzVGVqVm5KN2szWXNaeU81TjJibXNUZWpwbko3azNZdVp5TzVOV1pwWnlPNU5tWW1zVGVqOW1KN2szWXlaeU81TkdkbXNUZWp0V2RwWnlPNU5tYm1zVGVqbG1KN2szWWtaQ0l6c1RZdDEyYmpaU01nc1RlamRtSmdFREk3azNZcFp5TzVOR2Rtc1RlamxtSjdrM1l1WnlPNU5XYW1zVGVqaDJZbXNUZWpwbko3azNZdlp5TzVObVVtQXlPNU4yVW1ZVE1nc1RlalJuSjdrM1l1WnlPNU5XWnBaeU81TjJabXNUZWpGbUo3azNZbGxtSjdrM1lTWnlPcDFXWnpaQ014c1RiMTVtSjdrV2JsTm5KNE16T3RWbmJtc0RjdEZtSjdRMmJwSlhad1p5TzVOV2Ftc1RlalJtSjdrM1l2WnlPNU5tZG1BeU81TkdibXNUZWoxbUpnQURNeEF5TzVObWRtQXlPNU5XZG1zVGVqUm1KN2szWXBaeU81TjJjbXNUZWp0bUo3azNZdlp5TzVObWNtc1RlalJtSjdrM1lyVlhhbXNUZWpkbUpnc1RlanBtSjdrM1lwWnlPNU5HZG1zVGVqdFdkcFp5TzVOR2JtQUNNeEF5TzVOV2Ftc1RlalJuSjdrM1lwWnlPNU5tYm1zVGVqbG1KN2szWW9ObUo3azNZNlp5TzVOMmJtc1RlakpsSmdzRFp2bG1jbEJuSjdrM1lXWkNJMkVESTdrM1kwWnlPNU5tYm1zVGVqVldhbXNUZWpkbUo3azNZaFp5TzVOV1pwWnlPNU5tVW1zVGF0VjJjbUFUTTcwV2R1WnlPcDFXWnpaQ096c1RiMTVtSjdBWGJoWnlPazlXYXlWR2Ntc1RlakZXZW1zVGVqeG1KN2szWXZaeU81TjJhbXNUZWp0V2RwWnlPNU5HYm1zVGVqZG1KN2szWXVaeU81TldacFp5TzVOR2Jtc1RlamxtSjdrM1kwWnlPNU5XWnBaeU81TjJhMWxtSjdrM1lzWnlPNU4yYm1zVGVqQm5KZ3NUZWp4bUo3azNZdFpDSXdBVE1nc1RlalpuSmdzVGVqVm5KN2szWXNaeU81TjJibXNUZWpwbko3azNZdVp5TzVOV1pwWnlPNU5tWW1zVGVqOW1KN2szWXlaeU81TkdkbXNUZWp0V2RwWnlPNU5tYm1zVGVqbG1KN2szWWtaQ0l5c1RZdDEyYmpaU01nc1RlamRtSmdFREk3UTJicEpYWndaeU81TldRbVlUTWdzVGVqUm5KN2szWXVaeU81TldacFp5TzVOMlptc1RlakZtSjdrM1lsbG1KN2szWVNaeU9wMVdaelpDTXhzVGIxNW1KN2tXYmxObko0TXpPdFZuYm1zRGN0Rm1KN2szWTFaeU81Tm1ibXNUZWp0V2RwWnlPNU5HYm1zVGVqOW1KN2szWXRaeU81TldacFp5TzVOR2NtQXlPNU5HZG05MmNtc1RlalJuSjdrM1l6WnlPNU4yYTFsbUo3azNZdVp5TzVOR2Rtc1RlalZuSjdrM1l6WnlPNU5XYW1zVGVqSm5KN2szWXdaQ0k3azNZaFp5TzVObWJtQXlPNU5XYm1zVGVqOW1KN2szWXNaeU81TjJibXNUZWpwbko3azNZdVp5TzVOV1pwWnlPNU5tWW1zVGVqOW1KN2szWXlaeU81TkdkbXNUZWp0V2RwWnlPNU5tYm1zVGVqbG1KN2szWWtaQ0k3azNZNlpDSTdrM1kwWnlPNU4yY21zVGVqVldhbXNUZWpSbEo%3D');
INSERT INTO "public"."reactiv_menu" ("id", "name", "position", "units_id", "comment") VALUES (8, 'Реагент 3. Тест Мекке', 0, 1, 'PT13TzVOV2Ftc1RlalJuSjdrM1l2WnlPNU5HYm1zVGVqTm5KN2szWXBaeU81TjJhbUF5TzVOV2E1WnlPNU4yYm1zVGVqUm5KN2szWXpaeU81TldhbXNUZWo1bUo3azNZbGxtSjdrM1lzWnlPNU5XWnBaeU81TjJjbUF5TzVOMlptQVNNZ3NUZWpsbUo3azNZMFp5TzVOV2Ftc1RlajVtSjdrM1lwWnlPNU5HYWpaeU81Tm1lbXNUZWo5bUo3azNZeVpDSTdrM1lwWnlPNU5HZG1zVGVqOW1KN2szWXNaeU81TjJjbXNUZWpsbUo3azNZclpDSTdrM1lwbG5KN2szWXZaeU81Tm1ibXNUZWpSbko3azNZaFp5TzVObVptc1RlalJuWnZObko3azNZc1p5TzVOV2Rtc1Rlak5uSmdzVGVqbFdlbXNUZWo5bUo3azNZdVp5TzVOV1ltc1RlalpuSjdrM1l2WnlPNU5tY21zVGVqUm5KN2szWXVaeU81TldacFp5TzVOMmMwWnlPNU5tYm1zVGVqOW1KN2szWXJaQ0lnc1RlanhtSjdrM1l0WkNJd0FUTWdzVGVqWmxK');
INSERT INTO "public"."reactiv_menu" ("id", "name", "position", "units_id", "comment") VALUES (20, 'Реагент 15А. Тест Цімермана', 0, 1, 'PT13T2s5V2F5VkdjbXNUZWpsbUo3azNZa1p5TzVOMmJtc1RlalpuSmdzVGVqbFdlbXNUZWo5bUo3azNZdVp5TzVOV1ltc1RlalpuSjdrM1l2WnlPNU5tZW1zVGVqdFdkcFp5TzVObWJtc1RlajltSjdrM1lxWnlPNU5XWnBaeU81TkdabUF5TzVOR2Jtc1RlajFtSmdBRE14QXlPNU5tZG1BeU81TldkbXNUZWpSbUo3azNZcFp5TzVOMmNtc1RlanRtSjdrM1l2WnlPNU5tY21zVGVqUm1KN2szWXJWWGFtc1RlamRtSmdzVGVqcG1KN2szWXJWWGFtc1RlanhtSjdrM1loWnlPNU4yYW1BeU81TjJabUFTTnhBeU81TldhbXNUZWpSbko3azNZcFp5TzVObWJtc1RlamxtSjdrM1lvTm1KN2szWTZaeU81TjJibXNUZWpKbEpnc2pidngyYmpaeU81Tm1WbVVUTWdzVGVqUm5KN2szWXVaeU81TldacFp5TzVOMlptc1RlakZtSjdrM1lsbG1KN2szWVNaeU9wMVdaelpDTXhzVGIxNW1KN2tXYmxObko0TXpPdFZuYm1zRGN0Rm1KN1EyYnBKWFp3WnlPNU5XZG1zVGVqeG1KN2szWXZaeU81Tm1ibXNUZWpGbUo3azNZMFp5TzVOV1pwWnlPNU5XYm1BeU81TkdibXNUZWoxbUpnQURNeEF5TzVObWRtQXlPNU5XZG1zVGVqeG1KN2szWXZaeU81Tm1lbXNUZWo1bUo3azNZbGxtSjdrM1lpWnlPNU4yYm1zVGVqSm5KN2szWTBaeU81TjJhMWxtSjdrM1l1WnlPNU5XYW1zVGVqUm1KZ016T2gxV2J2Tm1KeEF5TzVOMlptQVNNZ3NUZWpsbUo3azNZMFp5TzVOV2Ftc1RlajVtSjdrM1lwWnlPNU5HYWpaeU81Tm1lbXNUZWo5bUo3azNZU1pDSTc0MmJzOTJZbXNUZWpGa0oxRURJN2szWTBaeU81Tm1ibXNUZWpWV2Ftc1RlamRtSjdrM1loWnlPNU5XWnBaeU81Tm1VbXNUYXRWMmNtQVRNNzBXZHVaeU9wMVdaelpDT3pzVGIxNW1KN0FYYmhaeU9rOVdheVZHY21zVGVqRm1KN2szWXVaeU81TldZbXNUZWoxbUo3azNZeVp5TzVOV1pwWnlPNU5XYm1zVGVqdFdkcFp5TzVOMlVVWkNJN2szWTBaeU81TjJjbXNUZWpWV2Ftc1RlalJsSg%3D%3D');
INSERT INTO "public"."reactiv_menu" ("id", "name", "position", "units_id", "comment") VALUES (16, 'Реагент 12А. Тест Саймона', 0, 1, 'PXNqYnZ4MmJqWnlPNU5HZG1zVGVqTm5KN2szWWxsbUo3azNZVVp5T3AxV1p6WkNNeHNUYjE1bUo3a1dibE5uSjRNek90Vm5ibXNEY3RGbUo3UTJicEpYWndaeU81TldhbXNUZWpSbUo3azNZdlp5TzVObWRtQXlPNU5HYm1zVGVqMW1KZ0FETXhBeU81Tm1kbUF5TzVOV2Rtc1RlalJuSjdrM1loWnlPNU5tYm1zVGVqOW1KN2szWWlaeU81Tm1jbXNUZWpGbUo3azNZclpDSTdrM1lxWnlPNU4yYTFsbUo3azNZeVp5TzVOR2Rtc1RlakZtSjdrM1l1WkNJN2szWW5aQ0l5QXlPNU5XYW1zVGVqUm5KN2szWXBaeU81Tm1ibXNUZWpsbUo3azNZb05tSjdrM1k2WnlPNU4yYm1zVGVqSmxKZ3NqYnZ4MmJqWnlPNU5tVm1JVE1nc1RlalJuSjdrM1l1WnlPNU5XWnBaeU81TjJabXNUZWpGbUo3azNZbGxtSjdrM1lTWnlPcDFXWnpaQ014c1RiMTVtSjdrV2JsTm5KNE16T3RWbmJtc0RjdEZtSjdRMmJwSlhad1p5TzVOV2Rtc1RlalJtSjdrM1lyVlhhbXNUZWpkbUo3azNZbGxtSjdrM1lrWnlPNU5HZG05MmNtc1RlanhtSjdrM1loWnlPNU5HZG1zVGVqVldhbXNUZWpOSGRtc1RlakZtSmdzVGVqeG1KN2szWXRaQ0l3RURJN2szWXBaeU81TkdkbXNUZWpGbUo3azNZa1p5TzVOMmJtc1RlalJtSmdzVGVqMW1KN2szWXJWWGFtc1RlalJuSjdrM1l2WnlPNU5HY21BeU9oMVdidk5tSjdrM1lwWnlPNU5HWm1zVGVqOW1KN2szWTJaQ0k3azNZcGxuSjdrM1l2WnlPNU5tYm1zVGVqRm1KN2szWTJaeU81TjJibXNUZWpwbko3azNZclZYYW1zVGVqNW1KN2szWXZaeU81Tm1hbXNUZWpWV2Ftc1RlalJtSmdzVGVqeG1KN2szWXRaQ0l3a0RJN2szWTJaQ0k3azNZaGxuSjdrM1lyVlhhbXNUZWpKbko3azNZMFp5TzVOV1ltc1RlajVtSmdzVGVqVm5KN2szWWtaeU81TldhbXNUZWpObko3azNZMVp5TzVObWNtc1RlakJuSjdrM1l2WnlPNU5tY21zVGVqUm5KN2szWXJWWGFtc1RlajVtSmdzVGVqZG1KZ2t6T2gxV2J2Tm1Kd0F5TzVOV2Ftc1RlalJuSjdrM1lwWnlPNU5tYm1zVGVqbG1KN2szWW9ObUo3azNZNlp5TzVOMmJtc1RlakpsSmdzamJ2eDJialp5TzVOV1FtSVRNZ3NUZWpSbko3azNZdVp5TzVOV1pwWnlPNU4yWm1zVGVqRm1KN2szWWxsbUo3azNZU1p5T3AxV1p6WkNNeHNUYjE1bUo3a1dibE5uSjRNek90Vm5ibXNEY3RGbUo3azNZaFp5TzVObWJtc1RlajltSjdrM1l0WnlPNU5tYW1zVGVqRm1KN2szWVRaQ0k3azNZMFp5TzVOMmNtc1RlalZXYW1zVGVqUmxK');
INSERT INTO "public"."reactiv_menu" ("id", "name", "position", "units_id", "comment") VALUES (23, 'Реагент 16с. Тест з динітробензолом', 0, 1, 'PXNqYnZ4MmJqWnlPNU5XZG1zVGVqUm5KN2szWXpaeU81TldacFp5TzVOR2RtQXlPNU5XWTVaeU81Tm1ibXNUZWo1bUo3azNZaFp5TzVObWJtc1RlajltSjdrM1lyWnlPNU5XYW1zVGVqWmxKN2tXYmxObkp3RXpPdFZuYm1zVGF0VjJjbWd6TTcwV2R1WnlPdzFXWW1zVGF0VjJjbUFUTTcwV2R1WnlPcDFXWnpaQ096c1RiMTVtSjdBWGJoWnlPazlXYXlWR2Ntc1RlakZXZW1zVGVqeG1KN2szWXZaeU81TjJhbXNUZWp0V2RwWnlPNU5HYm1zVGVqZG1KN2szWXVaeU81TldacFp5TzVOR2Jtc1RlamxtSjdrM1kwWnlPNU5XWnBaeU81TjJhMWxtSjdrM1lzWnlPNU4yYm1zVGVqQm5KZ3NUZWp4bUo3azNZdFpDSXdBVE1nc1RlalpuSmdzVGVqVm5KN2szWXNaeU81TjJibXNUZWpwbko3azNZdVp5TzVOV1pwWnlPNU5tWW1zVGVqOW1KN2szWXlaeU81TkdkbXNUZWp0V2RwWnlPNU5tYm1zVGVqbG1KN2szWWtaQ0kwQXlPaDFXYnZObUp4QXlPNU4yWm1BU01nc1RlamxtSjdrM1kwWnlPNU5XYW1zVGVqNW1KN2szWXBaeU81Tkdhalp5TzVObWVtc1RlajltSjdrM1lTWkNJRVpUTTdrV2JsTm5Kd0V6T3RWbmJtc1RhdFYyY21nek03MFdkdVp5T3cxV1ltc1RlakZXZW1zVGVqeG1KN2szWXZaeU81TjJhbXNUZWp0V2RwWnlPNU5HYm1zVGVqZG1KN2szWXVaeU81TldacFp5TzVOR2Jtc1RlamxtSjdrM1kwWnlPNU5XWnBaeU81TjJhMWxtSjdrM1lzWnlPNU4yYm1zVGVqQm5KZ3NUZWp4bUo3azNZdFpDSXdBVE1nc1RlalpuSmdzVGVqVm5KN2szWXNaeU81TjJibXNUZWpwbko3azNZdVp5TzVOV1pwWnlPNU5tWW1zVGVqOW1KN2szWXlaeU81TkdkbXNUZWp0V2RwWnlPNU5tYm1zVGVqbG1KN2szWWtaQ0l6c1RZdDEyYmpaU01nc1RlamRtSmdFREk3azNZcFp5TzVOR2Rtc1RlamxtSjdrM1l1WnlPNU5XYW1zVGVqaDJZbXNUZWpwbko3azNZdlp5TzVObVVtQXlPNU4yVW1ZVE1nc1RlalJuSjdrM1l1WnlPNU5XWnBaeU81TjJabXNUZWpGbUo3azNZbGxtSjdrM1lTWnlPcDFXWnpaQ014c1RiMTVtSjdrV2JsTm5KNE16T3RWbmJtc0RjdEZtSjdRMmJwSlhad1p5TzVOV2Ftc1RlalJtSjdrM1l2WnlPNU5tZG1BeU81TkdibXNUZWoxbUpnQURNeEF5TzVObWRtQXlPNU5XZG1zVGVqUm1KN2szWXBaeU81TjJjbXNUZWp0bUo3azNZdlp5TzVObWNtc1RlalJtSjdrM1lyVlhhbXNUZWpkbUpnc1RlanBtSjdrM1lwWnlPNU5HZG1zVGVqdFdkcFp5TzVOR2JtQUNNeEF5TzVOV2Ftc1RlalJuSjdrM1lwWnlPNU5tYm1zVGVqbG1KN2szWW9ObUo3azNZNlp5TzVOMmJtc1RlakpsSmdzRFp2bG1jbEJuSjdrM1lXWkNJMkVESTdrM1kwWnlPNU5tYm1zVGVqVldhbXNUZWpkbUo3azNZaFp5TzVOV1pwWnlPNU5tVW1zVGF0VjJjbUFUTTcwV2R1WnlPcDFXWnpaQ096c1RiMTVtSjdBWGJoWnlPazlXYXlWR2Ntc1RlakZXZW1zVGVqeG1KN2szWXZaeU81TjJhbXNUZWp0V2RwWnlPNU5HYm1zVGVqZG1KN2szWXVaeU81TldacFp5TzVOR2Jtc1RlamxtSjdrM1kwWnlPNU5XWnBaeU81TjJhMWxtSjdrM1lzWnlPNU4yYm1zVGVqQm5KZ3NUZWp4bUo3azNZdFpDSXdBVE1nc1RlalpuSmdzVGVqVm5KN2szWXNaeU81TjJibXNUZWpwbko3azNZdVp5TzVOV1pwWnlPNU5tWW1zVGVqOW1KN2szWXlaeU81TkdkbXNUZWp0V2RwWnlPNU5tYm1zVGVqbG1KN2szWWtaQ0l5c1RZdDEyYmpaU01nc1RlamRtSmdFREk3UTJicEpYWndaeU81TldRbVlUTWdzVGVqUm5KN2szWXVaeU81TldacFp5TzVOMlptc1RlakZtSjdrM1lsbG1KN2szWVNaeU9wMVdaelpDTXhzVGIxNW1KN2tXYmxObko0TXpPdFZuYm1zRGN0Rm1KN2szWTFaeU81Tm1ibXNUZWp0V2RwWnlPNU5HYm1zVGVqOW1KN2szWXRaeU81TldacFp5TzVOR2NtQXlPNU5HZG05MmNtc1RlalJuSjdrM1l6WnlPNU4yYTFsbUo3azNZdVp5TzVOR2Rtc1RlalZuSjdrM1l6WnlPNU5XYW1zVGVqSm5KN2szWXdaQ0k3azNZaFp5TzVObWJtQXlPNU5XYm1zVGVqOW1KN2szWXNaeU81TjJibXNUZWpwbko3azNZdVp5TzVOV1pwWnlPNU5tWW1zVGVqOW1KN2szWXlaeU81TkdkbXNUZWp0V2RwWnlPNU5tYm1zVGVqbG1KN2szWWtaQ0k3azNZNlpDSTdrM1kwWnlPNU4yY21zVGVqVldhbXNUZWpSbEo%3D');
INSERT INTO "public"."reactiv_menu" ("id", "name", "position", "units_id", "comment") VALUES (13, 'Реагент 7А 16% розчин хлоридної кислоти', 0, 1, 'N2szWTFaeU81TkdkbXNUZWpSblp2Tm5KN2szWXNaeU81TldZbXNUZWpKbUo3azNZdlp5TzVOMmFtQXlPNU5XYm1zVGVqOW1KN2szWTBaeU81TldZbXNUZWo1bUo3azNZdlp5TzVOMmExbG1KN2szWXpSbko3azNZdlp5TzVOMmExbG1KN2szWTBaQ0k3azNZNlpDSTdrM1kwWnlPNU4yY21zVGVqVldhbXNUZWpSbEo%3D');
INSERT INTO "public"."reactiv_menu" ("id", "name", "position", "units_id", "comment") VALUES (15, 'Реагент 10. Тест Вагнера', 0, 1, 'PXNEWnZsbWNsQm5KN2szWXBaeU81TkdabXNUZWo5bUo3azNZMlpDSTdrM1lzWnlPNU5XYm1BQ013RURJN2szWTJaQ0k3azNZcFp5TzVOR2Rtc1RlamxtSjdrM1l1WnlPNU5XYW1zVGVqaDJZbXNUZWpwbko3azNZdlp5TzVObWNtQXlPNU5HYXpaeU81TjJhMWxtSjdrM1l0WnlPNU5XZG1zVGVqTm5KZ3NUZWoxbUo3azNZclZYYW1zVGVqUm5KN2szWXZaeU81TkdjbUF5T2gxV2J2Tm1KN2szWTFaeU81TkdabXNUZWpsbUo3azNZa1p5TzVOMmJtc1RlanBtSmdzVGVqcG1KN2szWXJWWGFtc1RlanhtSjdrM1loWnlPNU4yYW1BeU81TjJabUFpTWdzVGVqRm1KN2szWTBaQ0k3azNZMVp5TzVOR1ptc1RlajltSjdrM1lxWkNJN2szWW5aQ0kzSXpPaDFXYnZObUp4QXlPNU5XYW1zVGVqUm5KN2szWWhaeU81Tkdhelp5TzVOMmExbG1KN2szWXRaeU81Tm1XbXNUYXRWMmNtQVRNNzBXZHVaeU9wMVdaelpDT3pzVGIxNW1KN0FYYmhaeU81TldZbXNUZWpKbko3azNZbGxtSjdrM1l1WnlPNU4yWm1zVGVqRm1KN2szWVdaQ0k3azNZMFp5TzVOMmNtc1RlalZXYW1zVGVqUmxK');
INSERT INTO "public"."reactiv_menu" ("id", "name", "position", "units_id", "comment") VALUES (14, 'Реагент 9. Тест з метилбензоатом', 0, 1, 'N1EyYnBKWFp3WnlPNU5XZG1zVGVqeG1KN2szWXZaeU81Tm1ibXNUZWpGbUo3azNZMFp5TzVOV1pwWnlPNU5XYm1BeU81TjJibXNUZWpkbUo3azNZdlp5TzVObWJtc1RlalJuSjdrM1kxbG5KN2szWXNaeU81TjJibXNUZWpObko3azNZaVp5TzVOV1ltQXlPNU5HYm1zVGVqMW1KZ0FETXhBeU81Tm1kbUF5TzVOV2Rtc1RlalJtSjdrM1lwWnlPNU4yY21zVGVqdG1KN2szWXZaeU81Tm1jbXNUZWpSbUo3azNZclZYYW1zVGVqZG1KZ3NUZWpwbUo3azNZclZYYW1zVGVqeG1KN2szWWhaeU81TjJhbUF5TzVOMlptQVNOZ3NUZWpsbUo3azNZMFp5TzVOV2Ftc1RlajVtSjdrM1lwWnlPNU5HYWpaeU81Tm1lbXNUZWo5bUo3azNZU1p5T3AxV1p6WkNNeHNUYjE1bUo3a1dibE5uSjRNek90Vm5ibXNEY3RGbUo3UTJicEpYWndaeU81TldibXNUZWo5bUo3azNZMFp5TzVOV1ltc1RlajltSjdrM1k2WnlPNU5tYm1zVGVqVldhbXNUZWpKbUo3azNZc1p5TzVOV2Ftc1RlalJuSjdrM1lsbG1KN2szWXRaQ0k3azNZNlpDSTdrM1kwWnlPNU4yY21zVGVqVldhbXNUZWpSbEo%3D');
INSERT INTO "public"."reactiv_menu" ("id", "name", "position", "units_id", "comment") VALUES (17, 'Реагент 12В. 2% розчин натрій карбонату (Тест Саймона)', 0, 1, 'N1EyYnBKWFp3WnlPNU5XYW1zVGVqUm1KN2szWXZaeU81Tm1kbUF5TzVOR2Jtc1RlajFtSmdBRE14QXlPNU5tZG1BeU81TldkbXNUZWpSbko3azNZaFp5TzVObWJtc1RlajltSjdrM1lpWnlPNU5tY21zVGVqRm1KN2szWXJaQ0k3azNZcVp5TzVOMmExbG1KN2szWXlaeU81TkdkbXNUZWpGbUo3azNZdVpDSTdrM1luWkNJeUF5TzVOV2Ftc1RlalJuSjdrM1lwWnlPNU5tYm1zVGVqbG1KN2szWW9ObUo3azNZNlp5TzVOMmJtc1RlakpsSmdzamJ2eDJialp5TzVObVZtSVRNZ3NUZWpSbko3azNZdVp5TzVOV1pwWnlPNU4yWm1zVGVqRm1KN2szWWxsbUo3azNZU1p5T3AxV1p6WkNNeHNUYjE1bUo3a1dibE5uSjRNek90Vm5ibXNEY3RGbUpnc0RadmxtY2xCbko3azNZaFp5TzVObWJtc1RlajltSjdrM1l0WnlPNU5tYW1zVGVqRm1KN2szWVRaQ0k3azNZMFp5TzVOMmNtc1RlalZXYW1zVGVqUmxK');
INSERT INTO "public"."reactiv_menu" ("id", "name", "position", "units_id", "comment") VALUES (19, 'Реагент. 14. Тест з галовою кислотою.', 0, 1, 'PT13T2s5V2F5VkdjbXNUZWpsbUo3azNZMFp5TzVOMmJtc1RlanhtSjdrM1l6WnlPNU5XYW1zVGVqdG1KZ3NUZWpsV2Vtc1RlajltSjdrM1l1WnlPNU5HZG1zVGVqRm1KN2szWW1aeU81TkdkbTkyY21zVGVqeG1KN2szWTFaeU81TjJjbUF5TzVOV2E1WnlPNU4yYm1zVGVqNW1KN2szWWhaeU81Tm1kbXNUZWo5bUo3azNZeVp5TzVOR2Rtc1RlajVtSjdrM1lsbG1KN2szWXpSbko3azNZdVp5TzVOMmJtc1RlanRtSmdzVGVqZG1KZ0FETXhBeU81Tm1kbUF5TzVOV2Ftc1RlalJuSjdrM1l2WnlPNU5HYm1zVGVqTm5KN2szWXBaeU81TjJhbUF5TzVOV2E1WnlPNU4yYm1zVGVqWm5KN2szWXZaeU81TkdibXNUZWpGbUo3azNZblpDSTdrM1luWkNJMXNUWXQxMmJqWkNNZ3NUZWpsbUo3azNZMFp5TzVOV2Ftc1RlajVtSjdrM1lwWnlPNU5HYWpaeU81Tm1lbXNUZWo5bUo3azNZU1pDSTc0MmJzOTJZbVFUTWdzVGVqUm5KN2szWXVaeU81TldacFp5TzVOMlptc1RlakZtSjdrM1lsbG1KN2szWVNaeU9wMVdaelpDTXhzVGIxNW1KN2tXYmxObko0TXpPdFZuYm1zRGN0Rm1KN1EyYnBKWFp3WnlPNU5XZDVaeU81TjJibXNUZWpSbko3azNZdlp5TzVOR2Jtc1Rlak5uSjdrM1lwWnlPNU4yYW1BeU81TldkNVp5TzVOMmJtc1RlalpuSjdrM1l2WnlPNU5HYm1zVGVqRm1KN2szWW5aQ0k3azNZNlpDSTdrM1kwWnlPNU4yY21zVGVqVldhbXNUZWpSbEo%3D');
INSERT INTO "public"."reactiv_menu" ("id", "name", "position", "units_id", "comment") VALUES (11, 'Реагент 6А. Тест Дюкенуа-Левіна', 0, 1, 'PT13T2s5V2F5VkdjbXNUZWpabko3azNZclZYYW1zVGVqUm1KN2szWXBsbko3azNZdlp5TzVObWJtc1RlanRXZHBaeU81Tm1ZbXNUZWpGbUo3azNZdVp5TzVObWJtc1RlakZtSjdrM1lyWkNJN2szWTBaMmJ6WnlPNU5HZG1zVGVqTm5KN2szWXJWWGFtc1RlajVtSjdrM1kwWnlPNU5XZG1zVGVqTm5KN2szWXBaeU81Tm1jbXNUZWpCbkpnc1RlalZuSjdrM1kyWnlPNU5XYW1zVGVqeG1KN2szWW9wbko3azNZdlp5TzVOV2JtQXlPNU5XWW1zVGVqNW1KZ3NUZWp0V2RxWnlPNU5XZG1zVGVqcG5KN2szWWhaeU81TjJhbXNUZWpabkpnc1RlalZuSjdrM1l5WnlPNU5XWW1zVGVqaDJjbUF5TzVOMmJtc1RlamRtSjdrM1l2WnlPNU5tYm1zVGVqMW1KN2szWXlaeU81TjJibXNUZWpabUo3azNZdlp5TzVObWNtc1RlajltSjdrM1lzWnlPNU5HYXJaQ0k3azNZdlp5TzVOMlptc1RlajltSjdrM1kwWjJielp5TzVObWJtc1RlamhtZW1zVGVqbG1KN2szWXVaQ0k3azNZaGxuSjdrM1l1WnlPNU5tYm1zVGVqVldhbXNUZWp4bUo3azNZMlp5TzVObWNtc1RlakZtSjdrM1lpWnlPNU5XWW1zVGVqcG5KZ3NUZWpWV2Ftc1RlalpuSjdrM1l2WnlPNU5HZG1zVGVqVldhbXNUZWp4bUo3azNZdlp5TzVOMmExbG1KN2szWUdaQ0k3UTJicEpYWndaeU81TkdkbXNUZWpGbUo3azNZMFp5TzVOR2RtOTJjbXNUZWp4bUo3azNZMVp5TzVObWVtc1RlalZXYW1zVGVqSmxKN2tXYmxObkp3RXpPdFZuYm1zVGF0VjJjbWd6TTcwV2R1WnlPdzFXWW1zVGF0VjJjbUFUTTcwV2R1WnlPcDFXWnpaQ096c1RiMTVtSjdBWGJoWnlPMDlXZHhaeU81TldRbVlESTdrM1kwWnlPNU5tYm1zVGVqVldhbXNUZWpkbUo3azNZaFp5TzVOV1pwWnlPNU5tY21BeU81TldacFp5TzVOR2F6WnlPNU5XYW1zVGVqeG1KZ3NUZWpGV2Vtc1Rlak5uSjdrM1kwWjJielp5TzVOR2Rtc1RlanRXZHFaeU81TldZbXNUZWpSbUo3azNZaGxuSjdrM1lzWnlPNU4yWm1zVGVqcG5KN2szWXZaeU81Tm1VbXNEZHZWWGNtc1RhdFYyY21BVE03MFdkdVp5T3AxV1p6WkNPenNUYjE1bUo3QVhiaFp5T3AxV1p6WkNNeHNUYjE1bUo3a1dibE5uSjRNek90Vm5ibXNEY3RGbUo3UTJicEpYWndaeU81TldkbXNUZWp0bUo3azNZeVp5TzVOMmExbG1KN2szWWlaeU81TjJibXNUZWpKbko3azNZd1pDSTdrM1lwWnlPNU5HZG1zVGVqbG1KN2szWXpaeU81TldkbXNUZWpKbko3azNZMFp5TzVObWVtQXlPNU4yYm1zVGVqNW1KN2szWW9wbko3azNZbGxtSjdrM1l5WnlPNU5XWnBaeU81Tm1ZbXNUZWo5bUpnc1RlakZtSjdrM1kwWkNJN2szWXpaaU5nc1RlalZuSjdrM1kwWnlPNU5tYm1zVGVqVldhbXNUZWpkbUo3azNZaFp5TzVOV1pwWnlPNU5tY21BeU81TkdibXNUZWoxbUpnSURJN2szWXBaeU81TkdkbXNUZWpGbUo3azNZa1p5TzVOMmJtc1RlalJtSmdzVFl0MTJialp5TzVOV1k1WnlPNU5tYm1zVGVqNW1KN2szWWxsbUo3azNZc1p5TzVObWRtc1RlakpuSjdrM1loWnlPNU5tWW1zVGVqRm1KN2szWTZaQ0k3azNZaGxuSjdrM1l6WnlPNU5HZG05MmNtc1RlalJuSjdrM1lwWnlPNU5tY21zVGVqOW1KN2szWTJaeU81TkdkbXNUZWpWbkpnc1RlamxtSjdrM1l1WnlPNU5XYW1zVGVqeG1KN2szWXBaeU81Tm1kbXNUZWpoMmFtQXlNdElESTdrM1loWnlPNU5tZW1BeU81TjJibXNUZWpoMllvTm5KN2szWXJaeU81TldRWlpDSTdRMmJwSlhad1pDTjdrV2JsTm5Kd0V6T3RWbmJtc1RhdFYyY21nek03MFdkdVp5T3cxV1ltc0RadmxtY2xCbko3azNZdVp5TzVOV2Ftc1RlanhtSjdrM1lwWnlPNU5tZG1zVGVqaDJhbUF5TzVOR2FyWnlPNU4yYm1zVGVqdG1KN2szWTBaMmJ6WnlPNU5HYm1zVGVqdFdkcFp5TzVOMmFtc1RlalZXYW1zVGVqUm1KZ3NUZWoxbUo3azNZdlp5TzVOMlptc1RlakZXZW1zVGVqUm5KN2szWXZaeU81Tm1jbXNUZWpCbkpnc1RlamxtSjdrM1kwWnlPNU5XYW1zVGVqTm5KN2szWTFaeU81Tm1jbXNUZWpSbko3azNZNlpDSTdrM1loWnlPNU5HZG1BeU81Tm1WbVlESTdrM1kxWnlPNU5HZG1zVGVqNW1KN2szWWxsbUo3azNZblp5TzVOV1ltc1RlalZXYW1zVGVqSm5KZ3NUZWp4bUo3azNZdFpDSXlBeU81TldhbXNUZWpSbko3azNZaFp5TzVOR1ptc1RlajltSjdrM1lFWkNJN1EyYnBKWFp3WnlNN2tXYmxObkp3RXpPdFZuYm1zVGF0VjJjbWd6TTcwV2R1WnlPdzFXWW1zRFp2bG1jbEJuSjdrM1lwWnlPNU5tYm1zVGVqbG1KN2szWXNaeU81TldhbXNUZWpabko3azNZb3RtSmdFREk3azNZdFp5TzVOMmJtc1RlamRtSjdrM1lobG5KN2szWTBaeU81TjJibXNUZWpKbko3azNZd1pDSTdrM1kxWnlPNU4yYW1zVGVqSm5KN2szWXJWWGFtc1RlakptSjdrM1l2WnlPNU5tY21zVGVqQm5KZ3NUZWpsbUo3azNZMFp5TzVOV2Ftc1Rlak5uSjdrM1kxWnlPNU5tY21zVGVqUm5KN2szWTZaQ0k3azNZaFp5TzVOR2RtQXlPNU5XUW1ZREk3azNZMVp5TzVOR2Rtc1RlajVtSjdrM1lsbG1KN2szWW5aeU81TldZbXNUZWpWV2Ftc1RlakpuSmdzVGVqeG1KN2szWXRaQ0l5QXlPNU5XYW1zVGVqUm5KN2szWWhaeU81TkdabXNUZWo5bUo3azNZRVpDSTdRMmJwSlhad1ppTTdrV2JsTm5Kd0V6T3RWbmJtc1RhdFYyY21nek03MFdkdVp5T3cxV1ltc0RadmxtY2xCbko3azNZcFp5TzVOMmFtc1RlakpuSjdrM1lyVlhhbXNUZWpKbUo3azNZdlp5TzVObWNtc1RlakJuSmdzVGVqOW1KN2szWWtaQ0k3azNZcFp5TzVOR2Rtc1RlamxtSjdrM1kwWnlPNU4yY21zVGVqdFdkcFp5TzVOV2Jtc1RlajltSjdrM1l3WkNJN2szWXBaeU81Tm1ibXNUZWpsbUo3azNZMlp5TzVOMmJtc1RlamgyWW1zVGVqVldhbXNUZWpKbkpnc1RlalJuWnZObko3azNZMFp5TzVOMmNtc1RlanRXZHBaeU81TjJhbXNUZWpSblp2Tm5KN2szWXNaeU81TjJhMWxtSjdrM1lyWkNJN2szWTFaeU81TjJhbXNUZWpsbUo3azNZc1p5TzVOV1pwWnlPNU5tZG1zVGVqVldhbXNUZWo1a0pnc0RadmxtY2xCbkp4c1RhdFYyY21BVE03MFdkdVp5T3AxV1p6WkNPenNUYjE1bUo3QVhiaFp5T3U5R2J2Tm1KN2szWTFaeU81TkdkbXNUZWpObko3azNZbGxtSjdrM1kwWkNJN2szWWhsbko3azNZdVp5TzVObWJtc1RlakZtSjdrM1l1WnlPNU4yYm1zVGVqdG1KN2szWXBaeU81Tm1WbXNUYXRWMmNtQVRNNzBXZHVaeU9wMVdaelpDT3pzVGIxNW1KN0FYYmhaeU9wMVdaelpDTXhzVGIxNW1KN2tXYmxObko0TXpPdFZuYm1zRGN0Rm1KN1EyYnBKWFp3WnlPNU5XYm1zVGVqSm5KN2szWXZaeU81Tm1abXNUZWo5bUo3azNZeVp5TzVOMmJtc1RlanhtSjdrM1lJdGtKZ3NUZWpObkoyQXlPNU5HZG1zVGVqNW1KN2szWWxsbUo3azNZblp5TzVOV1ltc1RlalZXYW1zVGVqSmxKN2tXYmxObkp3RXpPdFZuYm1zVGF0VjJjbWd6TTcwV2R1WnlPdzFXWW1zVGVqRm1KN2szWTBaeU81TjJibXNUZWp4bUo3azNZelp5TzVOV2Ftc1RlanRtSmdzVGVqRm1KN2szWXVaeU81TkdabXNUZWpsbUo3azNZeVp5TzVOMmJtc1RlanhtSjdrM1lvdG1KZ3NUZWpGbUo3azNZdVp5TzVOV1ltc1RlalpuSjdrM1l2WnlPNU5tY21zVGVqUm5KN2szWXVaeU81TldacFp5TzVOMmMwWnlPNU5tYm1zVGVqOW1KN2szWXJaQ0k3azNZV1ppTmdzVGVqUm5KN2szWXVaeU81TldacFp5TzVOMlptc1RlakZtSjdrM1lsbG1KN2szWVNaeU9wMVdaelpDTXhzVGIxNW1KN2tXYmxObko0TXpPdFZuYm1zRGN0Rm1KN2tXYmxObkp3RXpPdFZuYm1zVGF0VjJjbWd6TTcwV2R1WnlPdzFXWW1zRFp2bG1jbEJuSjdrM1kxWnlPNU5HWm1zVGVqdFdkcFp5TzVOMlptc1RlalZXYW1zVGVqUm1KN2szWTBaMmJ6WnlPNU5HYm1zVGVqRm1KN2szWTBaeU81TldacFp5TzVOMmMwWnlPNU5XWW1BeU81TkdibXNUZWoxbUpnVXpPaDFXYnZObUp5QXlPNU5XYW1zVGVqUm5KN2szWWhaeU81TkdabXNUZWo5bUo3azNZa1pDSTdrM1l0WnlPNU4yYTFsbUo3azNZMFp5TzVOMmJtc1RlakJuSmdzVFl0MTJialp5TzVOV2Rtc1RlanhtSjdrM1l2WnlPNU5tYm1zVGVqRm1KN2szWTBaeU81TldacFpDSTdRbmJqSlhad1pTTjVBeU81TkdibXNUZWoxbUpnQURNeEF5TzVObWRtQXlPNU5XZG1zVGVqNW1KN2szWXJWWGFtc1RlanhtSjdrM1lyVlhhbXNUZWo1bUo3azNZaFp5TzVObWRtQXlPNU4yWm1BaU1nc1RlamxtSjdrM1kwWnlPNU5XYW1zVGVqNW1KN2szWXBaeU81Tkdhalp5TzVObWVtc1RlajltSjdrM1lTWkNJNzQyYnM5Mlltc1RlakZrSjJBeU81TkdkbXNUZWo1bUo3azNZbGxtSjdrM1luWnlPNU5XWW1zVGVqVldhbXNUZWpKbEo%3D');
INSERT INTO "public"."reactiv_menu" ("id", "name", "position", "units_id", "comment") VALUES (18, 'Реагент 13А. Тест Саймона з ацетоном', 0, 1, 'PXNEWnZsbWNsQm5KN2szWXBaeU81TkdabXNUZWo5bUo3azNZMlpDSTdrM1lzWnlPNU5XYm1BQ013RURJN2szWTJaQ0k3azNZMVp5TzVOR2Rtc1RlakZtSjdrM1l1WnlPNU4yYm1zVGVqSm1KN2szWXlaeU81TldZbXNUZWp0bUpnc1RlanBtSjdrM1lyVlhhbXNUZWpKbko3azNZMFp5TzVOV1ltc1RlajVtSmdzVGVqZG1KZ0lESTdrM1lwWnlPNU5HZG1zVGVqbG1KN2szWXVaeU81TldhbXNUZWpoMlltc1RlanBuSjdrM1l2WnlPNU5tY21BeU95RkdjeVp5TzVObVZtSVRNZ3NUZWpSbko3azNZdVp5TzVOV1pwWnlPNU4yWm1zVGVqRm1KN2szWWxsbUo3azNZU1p5T3lGR2NzWkNJN2szWVdaeU14QXlPNU5HZG1zVGVqNW1KN2szWWxsbUo3azNZblp5TzVOV1ltc1RlalZXYW1zVGVqSmxKN2tXYmxObkp3RXpPdFZuYm1zVGF0VjJjbWd6TTcwV2R1WnlPdzFXWW1zRFp2bG1jbEJuSjdrM1kxWnlPNU5tYm1zVGVqOW1KN2szWTBaeU81TldacFp5TzVOMmMwWnlPNU5XWW1BeU81TldkbXNUZWo1bUo3azNZcFp5TzVOR2FqWnlPNU5tZW1zVGVqOW1KN2szWXlaQ0k3azNZdlp5TzVOMlptc1RlajltSjdrM1l1WnlPNU5HWm1zVGVqOW1KN2szWTJaQ0k3SVhZd0puSjdrM1l0WnlPNU4yYTFwbUo3azNZaVp5TzVOMmJtc0Ridk5uSjdrM1l0WnlPNU4yYTFwbUo3azNZaVp5TzVOMmJtQXlPNU4yYTFsbUo3azNZdVp5TzVObWJtc1RlalZXYW1zVGVqaDJjbXNUZWo5bUo3azNZdVp5TzVOR1ptc1RlanRXZHBaeU81Tm1kbUF5TzVOV2Rtc2pjaEJIYm1BeU8wNTJZeVZHY21VREk3azNZc1p5TzVOV2JtQUNNd0VESTdrM1kyWkNJN2szWTFsbko3azNZclZYYW1zVGVqSm5KN2szWTBaeU81TldZbXNUZWo1bUpnc1RlalZuSjdrM1lrWnlPNU5XYW1zVGVqTm5KN2szWTFaeU81Tm1jbXNUZWpCbko3azNZdlp5TzVObWNtc1RlalJuSjdrM1lyVlhhbXNUZWo1bUpnc1RlamRtSmdFREk3azNZcFp5TzVOR2Rtc1RlamxtSjdrM1l1WnlPNU5XYW1zVGVqaDJZbXNUZWpwbko3azNZdlp5TzVObVVtc2pidngyYmpaeU81TldRbU1UTWdzVGVqUm5KN2szWXVaeU81TldacFp5TzVOMlptc1RlakZtSjdrM1lsbG1KN2szWVNaeU9wMVdaelpDTXhzVGIxNW1KN2tXYmxObko0TXpPdFZuYm1zRGN0Rm1KN1EyYnBKWFp3WnlPNU5XYm1zVGVqOW1KN2szWXVaeU81TjJibXNUZWpSbko3azNZbGxtSjdrM1l6Um5KN2szWWhaQ0k3azNZNlpDSTdrM1loWnlPNU5tYm1zVGVqOW1KN2szWXRaeU81Tm1hbXNUZWpGbUo3azNZVFpDSTdrM1kwWnlPNU4yY21zVGVqVldhbXNUZWpSbEo%3D');
INSERT INTO "public"."reactiv_menu" ("id", "name", "position", "units_id", "comment") VALUES (26, 'Реагент 17В. Ділл- Копаній тест.', 0, 1, 'PT13T3AxV1p6WkNNeHNUYjE1bUo3a1dibE5uSjRNek90Vm5ibXNEY3RGbUo3UTJicEpYWndaeU81Tm1kbXNUZWp0V2RwWnlPNU5HZG1zVGVqRm1KN2szWXlaeU81TldkbXNUZWpSbko3azNZclZYYW1zVGVqSm1KN2szWXlaeU81TldZbXNUZWpKbUpnc1RlalJuWnZObko3azNZMFp5TzVOMmNtc1RlanRXZHBaeU81Tm1ibXNUZWpSbko3azNZMVp5TzVOMmNtc1RlamxtSjdrM1l5WnlPNU5HY21BeU81TldkbXNUZWpabko3azNZcFp5TzVOR2Jtc1RlamhtZW1zVGVqOW1KN2szWXRaQ0k3azNZaFp5TzVObWJtQXlPNU4yYTFwbUo3azNZMVp5TzVObWVtc1RlakZtSjdrM1lyWnlPNU5tZG1BeU81Tm1jbXNUZWp0V2RwWnlPNU5HYm1zVGVqOW1KN2szWXJaQ0k3azNZcVp5TzVOV2Ftc1RlalpuSjdrM1l2WnlPNU5tY21zVGVqVm5KN2szWXdaeU81Tm1jbXNUZWpWbko3azNZd1pTTDdrM1l2WnlPNU5tYm1zVGVqOW1KN2szWTJaeU81Tm1jbXNUZWpWV2Ftc1RlamgwUW1zVGF0VjJjbUFUTTcwV2R1WnlPcDFXWnpaQ096c1RiMTVtSjdBWGJoWnlPazlXYXlWR2Ntc1RlalpsSjNFRElnc1RlalZuSjdrM1kwWnlPNU5tYm1zVGVqVldhbXNUZWpkbUo3azNZaFp5TzVOV1pwWnlPNU5tY21BeU81TjJhMWxtSjdrM1lzWnlPNU5HY21zVGVqRm1KN2szWXlaeU81TjJhbUF5TWdzVFl0MTJialp5TzVOV1FtY1RNZ0F5TzVOV2Rtc1RlalJuSjdrM1l1WnlPNU5XWnBaeU81TjJabXNUZWpGbUo3azNZbGxtSjdrM1l5WkNJN2szWXJWWGFtc1RlanhtSjdrM1l3WnlPNU5XWW1zVGVqSm5KN2szWXJaQ0l6QUNJZ3NUZWpsbUo3azNZMFp5TzVOV1ltc1RlalJtSjdrM1l2WnlPNU5HWm1BeU81TldZbXNUZWp0bUo3azNZNlp5TzVOV1ltc1RlakpuSjdrM1k2WkNJN2szWXZaeU81TjJabXNUZWo5bUo3azNZdVp5TzVOV1ltc1RlalpuSjdrM1kxWnlPNU5HYTZaeU81TkdabXNUZWp0V2RwWnlPNU5HYm1zVGVqTm5KN2szWXZaeU81TkdabUF5TzVOMmJtc1RlalJrSjdrV2JsTm5Kd0V6T3RWbmJtc1RhdFYyY21nek03MFdkdVp5T3cxV1ltc2pidngyYmpaeU81TldkbXNUZWpSbko3azNZelp5TzVOV1pwWnlPNU5HZG1BeU81TldZNVp5TzVObWJtc1RlajVtSjdrM1loWnlPNU5tYm1zVGVqOW1KN2szWXJaeU81TldhbXNUZWpabEo3a1dibE5uSndFek90Vm5ibXNUYXRWMmNtZ3pNNzBXZHVaeU93MVdZbXNUYXRWMmNtQVRNNzBXZHVaeU9wMVdaelpDT3pzVGIxNW1KN0FYYmhaeU9rOVdheVZHY21zVGVqVm5KN2szWXNaeU81TjJibXNUZWo1bUo3azNZaFp5TzVOR2Rtc1RlalZXYW1zVGVqMW1KZ3NEWnZsbWNsQm5KN2szWXpaeU81Tm1ZbXNUZWpGbUpnc1RlanhtSjdrM1l0WlNONUF5TzVObWVtQXlPNU5XZG1zVGVqNW1KN2szWXJWWGFtc1RlajFtSjdrM1loWnlPNU5HYm1zVGVqdFdkcFp5TzVOR2Ntc1RlajltSjdrM1l5WnlPNU5HY21zVGVqOW1KN2szWTZaeU81TjJhMWxtSmdzVGVqeG1KN2szWXRaU05nc1RlamxtSjdrM1kwWnlPNU5XWW1zVGVqaDJjbXNUZWp0V2RwWnlPNU5XYm1zVGVqcGxKZ3NEWnZsbWNsQm5KN2szWVdaeU54QXlPNU5HZG1zVGVqNW1KN2szWWxsbUo3azNZblp5TzVOV1ltc1RlalZXYW1zVGVqSmxKN2tXYmxObkp3RXpPdFZuYm1zVGF0VjJjbWd6TTcwV2R1WnlPdzFXWW1zRFp2bG1jbEJuSjdrM1lwWnlPNU5HZG1zVGVqOW1KN2szWXNaeU81TjJjbXNUZWpsbUo3azNZclpDSTdrM1lwbG5KN2szWXZaeU81Tm1kbXNUZWo5bUo3azNZMFp5TzVOMmMwWnlPNU4yYm1BeU81TldhNVp5TzVOMmJtc1RlajVtSjdrM1lobG5KN2szWWtaeU81TjJibXNUZWpSblp2Tm5KN2szWXNaQ0k3azNZc1p5TzVOV2JtSXpPaDFXYnZObUp3QXlPNU5XYW1zVGVqUm5KN2szWWhaeU81TkdabXNUZWo5bUo3azNZa1pDSTdFV2J0OTJZbXNUZWpWbko3azNZc1p5TzVOMmJtc1RlajVtSjdrM1loWnlPNU5HZG1zVGVqVldhbXNUZWoxbUpnc0RadmxtY2xCbko3azNZelp5TzVObVltc1RlakZtSmdzVGVqeG1KN2szWXRaQ013RURJN2szWTJaQ0k3SVhZd0puSjdrM1kxWnlPNU5HZG1zVGVqRm1KN2szWXlaeU81TkdabXNUZWp0V2RwWnlPNU4yWm1zVGVqRm1KN2szWXlaeU81TkdkbXNUZWpWV2Ftc1RlalJuSjdJWFl3eG1KZ3NUZWpWbko3azNZMFp5TzVOR2RtOTJjbXNUZWp4bUo3azNZaFp5TzVObVltc1RlajltSjdrM1lyWkNJN2szWTFaeU81TkdkbXNUZWpGbUo3azNZMFp5TzVOV1pwWnlPNU4yYzBaeU81TldZbUF5TzVOMlptQVNNN0VXYnQ5MlltQURJN2szWXBaeU81TkdkbXNUZWpsbUo3azNZdVp5TzVOV2Ftc1RlamgyWW1zVGVqcG5KN2szWXZaeU81Tm1VbUF5T2s5V2F5VkdjbXNUZWpGa0ozRURJN2szWTBaeU81Tm1ibXNUZWpWV2Ftc1RlamRtSjdrM1loWnlPNU5XWnBaeU81Tm1VbXNUYXRWMmNtQVRNNzBXZHVaeU9wMVdaelpDT3pzVGIxNW1KN0FYYmhaeU9rOVdheVZHY21zVGVqUm5KN2szWXpaeU81TldacFp5TzVOR2RtQXlPNU5tYW1zVGVqdFdkcFp5TzVObWJtc1RlakZtSjdrM1l3WnlPNU4yYm1zVGVqdGtKZzB5TzVOR2Jtc1RlanhtSjdrM1lyVlhhbXNUZWpSa0o%3D');
INSERT INTO "public"."reactiv_menu" ("id", "name", "position", "units_id", "comment") VALUES (27, 'Реагент 19с. Тест Віталі-Моріна.', 0, 1, 'PXNUYXRWMmNtQVRNNzBXZHVaeU9wMVdaelpDT3pzVGIxNW1KN0FYYmhaeU81Tkdhclp5TzVOV2Ftc1RlajVtSjdrM1lrWnlPNU4yYTFsbUo3azNZb3RtSjdrM1l2WnlPNU5HY21BeU81Tkdhclp5TzVOV2Ftc1RlalpuSjdrM1l2WnlPNU5tYm1zVGVqdFdkcFp5TzVOR2Ntc1RlalZXYW1zVGVqcG5KN2szWWhaeU81TjJhMWxtSjdrM1lrWnlPNU4yYm1zVGVqcG5KN2szWXVaeU81TldacFp5TzVObVltQXlPNU5HYXJaeU81TldhbXNUZWpoMmNtc1RlajVtSjdrM1lyVlhhbUF5TzVOV1ltc1RlalJuSmdzVGVqVm5KN2szWXRaeU81TldZbXNUZWpCbko3azNZbGxtSjdrM1k2WnlPNU5XWW1zVGVqdFdkcFp5TzVOR1ptQXlPNU5HZG05MmNtc1RlalJuSjdrM1l6WnlPNU4yYTFsbUo3azNZdVp5TzVOR2Rtc1RlalZuSjdrM1l6WnlPNU5XYW1zVGVqSm5KN2szWXdaQ0k3azNZMVp5TzVObWRtc1RlamxtSjdrM1lzWnlPNU5HYTZaeU81TjJibXNUZWoxbUpnc1RlakZtSjdrM1l1WkNJN2szWXJWbmFtc1RlalZuSjdrM1k2WnlPNU5XWW1zVGVqdG1KN2szWTJaQ0k3azNZeVp5TzVOMmExbG1KN2szWXNaeU81TjJibXNUZWp0bUpnc1RlanBtSjdrM1lwWnlPNU5HZG1zVGVqWm5KN2szWXZaeU81TkdTYVp5T3AxV1p6WkNNeHNUYjE1bUo3a1dibE5uSjRNek90Vm5ibXNEY3RGbUo3UTJicEpYWndaeU81TjJjbWtUTWdBeU81TldkbXNUZWpSbko3azNZdVp5TzVOV1pwWnlPNU4yWm1zVGVqRm1KN2szWWxsbUo3azNZeVpDSTdrM1lzWnlPNU5XYm1FREk3RVdidDkyWW1zVGVqWmxKNUVESWdzVGVqVm5KN2szWTBaeU81Tm1ibXNUZWpWV2Ftc1RlamRtSjdrM1loWnlPNU5XWnBaeU81Tm1jbUF5TzVOR2Jtc1RlajFtSjFBeU81TldhbXNUZWpSbko3azNZaFp5TzVOR1ptc1RlajltSjdrM1lrWkNJN2tXYmxObko3azNZMVp5TzVOMmFtc1RlamgyY21zVGVqbG1KN2szWXNaeU81TldZbXNUZWpwbkpnc1RlajltSjdrM1luWnlPNU4yYm1zVGVqaDJhbXNUZWpWbko3azNZelpDSTdrM1l2WnlPNU5HWm1BeU81TjJhMWxtSjdrM1l1WnlPNU5XWW1zVGVqSm1KZ3NUZWpwbUo3azNZclZYYW1zVGVqNW1KN2szWWhsbko3azNZa1p5TzVOMmJtc1RlalpuSmdzVGVqRm1KN2szWXVaQ0k3azNZcFp5TzVOR2Rtc1RlanRXZHBaeU81Tm1jbXNUZWpkbUo3azNZaFp5TzVObWJtQXlPNU4yYTFsbUpnc1RlakZrSjVFRElnc1RlalZuSjdrM1kwWnlPNU5tYm1zVGVqVldhbXNUZWpkbUo3azNZaFp5TzVOV1pwWnlPNU5tY21BeU81TkdibXNUZWoxbUoxc1RZdDEyYmpaQ01nc1RlamxtSjdrM1kwWnlPNU5XWW1zVGVqUm1KN2szWXZaeU81TkdabUF5TzVOMmExbG1KN2szWXpSbko3azNZeVp5TzVOMmExbG1KN2szWWlaeU81TjJibXNUZWpKbko3azNZd1pDSTdrM1kyWkNJN2szWWhaeU81TjJhbXNUZWpwbko3azNZaFp5TzVObWNtc1RlanBuSmdzVGVqOW1KN2szWW5aeU81TjJibXNUZWo1bUo3azNZaFp5TzVObWRtc1RlalZuSjdrM1lvcG5KN2szWWtaeU81TjJhMWxtSjdrM1lzWnlPNU4yY21zVGVqOW1KN2szWWtaQ0k3azNZdlp5TzVOR1Jtc1RhdFYyY21BVE03MFdkdVp5T3AxV1p6WkNPenNUYjE1bUo3QVhiaFp5T3U5R2J2Tm1KN2szWTFaeU81TkdkbXNUZWpObko3azNZbGxtSjdrM1kwWkNJN2szWWhsbko3azNZdVp5TzVObWJtc1RlakZtSjdrM1l1WnlPNU4yYm1zVGVqdG1KN2szWXBaeU81Tm1WbXNUYXRWMmNtQVRNNzBXZHVaeU9wMVdaelpDT3pzVGIxNW1KN0FYYmhaeU9rOVdheVZHY21zVGVqRm1KN2szWXNaeU81TjJibXNUZWo1bUo3azNZaFp5TzVOR2Rtc1RlalZXYW1BeU81TkdibXNUZWoxbUpnQURNeEF5TzVObWRtQXlPNU5XZG1zVGVqUm1KN2szWXBaeU81TjJjbXNUZWp0bUo3azNZdlp5TzVObWNtc1RlalJtSjdrM1lyVlhhbXNUZWpkbUpnc1RlanBtSjdrM1lyVlhhbXNUZWp4bUo3azNZaFp5TzVOMmFtQXlPNU4yWm1BaU4xc1RZdDEyYmpaQ01nc0RadmxtY2xCbko3azNZelpTT3hBeU81TkdkbXNUZWo1bUo3azNZbGxtSjdrM1luWnlPNU5XWW1zVGVqVldhbXNUZWpKbEo3a1dibE5uSndFek90Vm5ibXNUYXRWMmNtZ3pNNzBXZHVaeU93MVdZbXNEWnZsbWNsQm5KN2szWXVaeU81TjJibXNUZWpSbko3azNZbGxtSjdrM1l6Um5KN2szWUJaQ0k3UTJicEpYWndaeU81Tm1WbWtUTWdzVGVqUm5KN2szWXVaeU81TldacFp5TzVOMlptc1RlakZtSjdrM1lsbG1KN2szWVNaeU9wMVdaelpDTXhzVGIxNW1KN2tXYmxObko0TXpPdFZuYm1zRGN0Rm1KN1EyYnBKWFp3WnlPNU5XWW1zVGVqUm5KN2szWXZaeU81TkdibXNUZWpObko3azNZcFp5TzVOMmFtQXlPNU5XWW1zVGVqNW1KN2szWTBaeU81TjJibXNUZWpwbko3azNZaFpDSTdrM1loWnlPNU5tYm1zVGVqRm1KN2szWTJaeU81TjJibXNUZWpKbko3azNZMFp5TzVObWJtc1RlalZXYW1zVGVqTkhkbXNUZWo1bUo3azNZdlp5TzVOMlNtQXlPazlXYXlWR2Ntc1RlakZrSjVFREk3azNZMFp5TzVObWJtc1RlalZXYW1zVGVqZG1KN2szWWhaeU81TldacFp5TzVObVVtc1RhdFYyY21BVE03MFdkdVp5T3AxV1p6WkNPenNUYjE1bUo3QVhiaFp5T2s5V2F5VkdjbXNUZWpGbUo3azNZdVp5TzVOMmExbG1KN2szWXlaeU81TjJibXNUZWoxa0p0c1RlanRXZHBaeU81TkdibXNUZWpGbUo3azNZMFp5TzVOMmExbG1KN2szWVdaQ0k3azNZMFp5TzVOMmNtc1RlalZXYW1zVGVqUmxK');
INSERT INTO "public"."reactiv_menu" ("id", "name", "position", "units_id", "comment") VALUES (28, 'Реагент 20. Тест Ерліха', 0, 1, 'PT13T3AxV1p6WkNNeHNUYjE1bUo3a1dibE5uSjRNek90Vm5ibXNEY3RGbUo3UTJicEpYWndaeU95RkdjeVpDUlR4ME95Rkdjc1pDSTdrM1kxWnlPNU5HWm1zVGVqdFdkcFp5TzVOMlptc1RlakpuSjdrM1lsbG1KN2szWTZaeU81TjJhMWxtSjdrM1lzWkNJN2szWTBaMmJ6WnlPNU5HZG1zVGVqTm5KN2szWXJWWGFtc1RlajVtSjdrM1kwWnlPNU5XZG1zVGVqTm5KN2szWXBaeU81Tm1jbXNUZWpCbkpnc1RlalZuSjdrM1kyWnlPNU5XYW1zVGVqeG1KN2szWW9wbko3azNZdlp5TzVOV2JtQXlPNU5XWW1zVGVqNW1KZ3NUZWp0V2RxWnlPNU5XZG1zVGVqcG5KN2szWWhaeU81TjJhbXNUZWpabkpnc1RlajVtSjdrM1lwWnlPNU5HYm1zVGVqbG1KN2szWTJaeU81TkdhclpDSTdrM1loWnlPNU4yYW1zVGVqUm5adk5uSjdrM1lzWnlPNU4yYTFsbUo3azNZclp5TzVOV1pwWnlPNU5HWm1BeU81TldZbXNUZWpwbkpnc1RlakZXZW1zVGVqTm5KN2szWTBaMmJ6WnlPNU5HZG1zVGVqdFdkcVp5TzVOV1k1WnlPNU5HYm1zVGVqWm5KN2szWWhsbko3OFdkeE5uY21zVGVqcG5KZ3NUZWo5bUo3azNZb05HYXpaQ0k3RVdidDkyWW1zVGVqRldlbXNUZWo1bUo3azNZdVp5TzVOV1pwWnlPNU5HYm1zVGVqWm5KN2szWXlaeU81TldZbXNUZWpKbUo3azNZaFp5TzVObWVtQXlPNU5XWnBaeU81Tm1kbXNUZWo5bUo3azNZMFp5TzVOV1pwWnlPNU5HYm1zVGVqOW1KN2szWXJWWGFtc1RlalprSjdrV2JsTm5Kd0V6T3RWbmJtc1RhdFYyY21nek03MFdkdVp5T3cxV1ltc0RadmxtY2xCbkp3SURJN2szWTFaeU81TkdkbXNUZWo1bUo3azNZbGxtSjdrM1luWnlPNU5XWW1zVGVqVldhbXNUZWpKbkpnc1RlanRXZHBaeU81TkdibXNUZWpCbko3azNZaFp5TzVObWNtc1RlanRtSmdJREk3azNZcFp5TzVOR2Rtc1RlakZtSjdrM1lrWnlPNU4yYm1zVGVqUm1KZ3NUZWpGbUo3azNZclp5TzVObWVtc1RlakZtSjdrM1l5WnlPNU5tZW1BeU81TjJibXNUZWpkbUo3azNZdlp5TzVObWJtc1RlakZtSjdrM1kyWnlPNU5XZG1zVGVqaG1lbXNUZWpSbUo3azNZclZYYW1zVGVqeG1KN2szWXpaeU81TjJibXNUZWpSbUpnc1RlajltSjdrM1lFWkNJNzQyYnM5Mlltc1RlalZuSjdrM1kwWnlPNU4yY21zVGVqVldhbXNUZWpSbkpnc1RlakZXZW1zVGVqNW1KN2szWXVaeU81TldZbXNUZWo1bUo3azNZdlp5TzVOMmFtc1RlamxtSjdrM1lXWnlPcDFXWnpaQ014c1RiMTVtSjdrV2JsTm5KNE16T3RWbmJtc0RjdEZtSjdrV2JsTm5Kd0V6T3RWbmJtc1RhdFYyY21nek03MFdkdVp5T3cxV1ltc0RadmxtY2xCbko3azNZcFp5TzVOR2Rtc1RlajltSjdrM1lzWnlPNU4yY21zVGVqbG1KN2szWXJaQ0k3azNZcGxuSjdrM1l2WnlPNU5tYm1zVGVqSm5KN2szWXZaeU81Tm1abXNUZWpObko3azNZdlp5TzVObVptc1RlajltSjdrM1kwWnlPNU5tY21zVGVqOW1KZ3NUZWp4bUo3azNZdFpDSXdFREk3azNZcFp5TzVOR2Rtc1RlakZtSjdrM1lrWnlPNU4yYm1zVGVqUm1KZ3NUZWo5bUo3azNZdVp5TzVOR2E2WnlPNU5XWnBaeU81Tm1jbXNUZWpWV2Ftc1RlakptSjdrM1l2WkNJN2szWXRaeU81TjJhMWxtSjdrM1kwWnlPNU4yYm1zVGVqQm5KZ3NUWXQxMmJqWnlPNU5XZG1zVGVqeG1KN2szWXZaeU81Tm1ibXNUZWpGbUo3azNZMFp5TzVOV1pwWnlPNU5XYm1BeU81TkdibXNUZWoxbUpnQVRNZ3NUZWpabkpnc1RlalZuSjdrM1lrWnlPNU4yYTFsbUo3azNZblp5TzVOV1pwWnlPNU5HWm1zVGVqUm5adk5uSjdrM1lzWnlPNU5XWW1zVGVqcG5KN2szWXVaeU81TldacFp5TzVObVltc1RlajltSjdrM1l1WnlPNU4yYTFsbUo3azNZdFp5TzVOV1ltc1RlanhtSjdrM1lwWnlPNU5HZG1zVGVqVldhbXNUZWoxbUo3azNZcFp5TzVOR1ptMENOZ3NUZWpkbUpnRURJN2szWXBaeU81TkdkbXNUZWpsbUo3azNZdVp5TzVOV2Ftc1RlamgyWW1zVGVqcG5KN2szWXZaeU81Tm1VbUF5T2s5V2F5VkdjbUFqTWdzVGVqUm5KN2szWXVaeU81TldacFp5TzVOMlptc1RlakZtSjdrM1lsbG1KN2szWVNaeU9wMVdaelpDTXhzVGIxNW1KN2tXYmxObko0TXpPdFZuYm1zRGN0Rm1KZ3NUZWpGbUo3azNZb3RtSjdrM1lyVlhhbXNUZWp4bUo3azNZeVp5TzVOV1JKWkNJN2szWTBaeU81TjJjbXNUZWpWV2Ftc1RlalJsSg%3D%3D');
INSERT INTO "public"."reactiv_menu" ("id", "name", "position", "units_id", "comment") VALUES (25, 'Реагент 17А. Ділл- Копаній тест', 0, 1, 'PT13T3AxV1p6WkNNeHNUYjE1bUo3a1dibE5uSjRNek90Vm5ibXNEY3RGbUo3UTJicEpYWndaeU81Tm1kbXNUZWp0V2RwWnlPNU5HZG1zVGVqRm1KN2szWXlaeU81TldkbXNUZWpSbko3azNZclZYYW1zVGVqSm1KN2szWXlaeU81TldZbXNUZWpKbUpnc1RlalJuWnZObko3azNZMFp5TzVOMmNtc1RlanRXZHBaeU81Tm1ibXNUZWpSbko3azNZMVp5TzVOMmNtc1RlamxtSjdrM1l5WnlPNU5HY21BeU81TldkbXNUZWpabko3azNZcFp5TzVOR2Jtc1RlamhtZW1zVGVqOW1KN2szWXRaQ0k3azNZaFp5TzVObWJtQXlPNU4yYTFwbUo3azNZMVp5TzVObWVtc1RlakZtSjdrM1lyWnlPNU5tZG1BeU81Tm1jbXNUZWp0V2RwWnlPNU5HYm1zVGVqOW1KN2szWXJaQ0k3azNZcVp5TzVOV2Ftc1RlalpuSjdrM1l2WnlPNU5tY21zVGVqVm5KN2szWXdaeU81Tm1jbXNUZWpWbko3azNZd1pTTDdrM1l2WnlPNU5tYm1zVGVqOW1KN2szWTJaeU81Tm1jbXNUZWpWV2Ftc1RlamgwUW1zVGF0VjJjbUFUTTcwV2R1WnlPcDFXWnpaQ096c1RiMTVtSjdBWGJoWnlPazlXYXlWR2Ntc1RlalpsSjNFRElnc1RlalZuSjdrM1kwWnlPNU5tYm1zVGVqVldhbXNUZWpkbUo3azNZaFp5TzVOV1pwWnlPNU5tY21BeU81TjJhMWxtSjdrM1lzWnlPNU5HY21zVGVqRm1KN2szWXlaeU81TjJhbUF5TWdzVFl0MTJialp5TzVOV1FtY1RNZ0F5TzVOV2Rtc1RlalJuSjdrM1l1WnlPNU5XWnBaeU81TjJabXNUZWpGbUo3azNZbGxtSjdrM1l5WkNJN2szWXJWWGFtc1RlanhtSjdrM1l3WnlPNU5XWW1zVGVqSm5KN2szWXJaQ0l6QUNJZ3NUZWpsbUo3azNZMFp5TzVOV1ltc1RlalJtSjdrM1l2WnlPNU5HWm1BeU81TldZbXNUZWp0bUo3azNZNlp5TzVOV1ltc1RlakpuSjdrM1k2WkNJN2szWXZaeU81TjJabXNUZWo5bUo3azNZdVp5TzVOV1ltc1RlalpuSjdrM1kxWnlPNU5HYTZaeU81TkdabXNUZWp0V2RwWnlPNU5HYm1zVGVqTm5KN2szWXZaeU81TkdabUF5TzVOMmJtc1RlalJrSjdrV2JsTm5Kd0V6T3RWbmJtc1RhdFYyY21nek03MFdkdVp5T3cxV1ltc2pidngyYmpaeU81TldkbXNUZWpSbko3azNZelp5TzVOV1pwWnlPNU5HZG1BeU81TldZNVp5TzVObWJtc1RlajVtSjdrM1loWnlPNU5tYm1zVGVqOW1KN2szWXJaeU81TldhbXNUZWpabEo3a1dibE5uSndFek90Vm5ibXNUYXRWMmNtZ3pNNzBXZHVaeU93MVdZbXNUYXRWMmNtQVRNNzBXZHVaeU9wMVdaelpDT3pzVGIxNW1KN0FYYmhaeU9rOVdheVZHY21zVGVqVm5KN2szWXNaeU81TjJibXNUZWo1bUo3azNZaFp5TzVOR2Rtc1RlalZXYW1zVGVqMW1KZ3NEWnZsbWNsQm5KN2szWXpaeU81Tm1ZbXNUZWpGbUpnc1RlanhtSjdrM1l0WlNONUF5TzVObWVtQXlPNU5XZG1zVGVqNW1KN2szWXJWWGFtc1RlajFtSjdrM1loWnlPNU5HYm1zVGVqdFdkcFp5TzVOR2Ntc1RlajltSjdrM1l5WnlPNU5HY21zVGVqOW1KN2szWTZaeU81TjJhMWxtSmdzVGVqeG1KN2szWXRaU05nc1RlamxtSjdrM1kwWnlPNU5XWW1zVGVqaDJjbXNUZWp0V2RwWnlPNU5XYm1zVGVqcGxKZ3NEWnZsbWNsQm5KN2szWVdaeU54QXlPNU5HZG1zVGVqNW1KN2szWWxsbUo3azNZblp5TzVOV1ltc1RlalZXYW1zVGVqSmxKN2tXYmxObkp3RXpPdFZuYm1zVGF0VjJjbWd6TTcwV2R1WnlPdzFXWW1zRFp2bG1jbEJuSjdrM1lwWnlPNU5HZG1zVGVqOW1KN2szWXNaeU81TjJjbXNUZWpsbUo3azNZclpDSTdrM1lwbG5KN2szWXZaeU81Tm1kbXNUZWo5bUo3azNZMFp5TzVOMmMwWnlPNU4yYm1BeU81TldhNVp5TzVOMmJtc1RlajVtSjdrM1lobG5KN2szWWtaeU81TjJibXNUZWpSblp2Tm5KN2szWXNaQ0k3azNZc1p5TzVOV2JtSXpPaDFXYnZObUp3QXlPNU5XYW1zVGVqUm5KN2szWWhaeU81TkdabXNUZWo5bUo3azNZa1pDSTdFV2J0OTJZbXNUZWpWbko3azNZc1p5TzVOMmJtc1RlajVtSjdrM1loWnlPNU5HZG1zVGVqVldhbXNUZWoxbUpnc0RadmxtY2xCbko3azNZelp5TzVObVltc1RlakZtSmdzVGVqeG1KN2szWXRaQ013RURJN2szWTJaQ0k3SVhZd0puSjdrM1kxWnlPNU5HZG1zVGVqRm1KN2szWXlaeU81TkdabXNUZWp0V2RwWnlPNU4yWm1zVGVqRm1KN2szWXlaeU81TkdkbXNUZWpWV2Ftc1RlalJuSjdJWFl3eG1KZ3NUZWpWbko3azNZMFp5TzVOR2RtOTJjbXNUZWp4bUo3azNZaFp5TzVObVltc1RlajltSjdrM1lyWkNJN2szWTFaeU81TkdkbXNUZWpGbUo3azNZMFp5TzVOV1pwWnlPNU4yYzBaeU81TldZbUF5TzVOMlptQVNNN0VXYnQ5MlltQURJN2szWXBaeU81TkdkbXNUZWpsbUo3azNZdVp5TzVOV2Ftc1RlamgyWW1zVGVqcG5KN2szWXZaeU81Tm1VbUF5T2s5V2F5VkdjbXNUZWpGa0ozRURJN2szWTBaeU81Tm1ibXNUZWpWV2Ftc1RlamRtSjdrM1loWnlPNU5XWnBaeU81Tm1VbXNUYXRWMmNtQVRNNzBXZHVaeU9wMVdaelpDT3pzVGIxNW1KN0FYYmhaeU9rOVdheVZHY21zVGVqUm5KN2szWXpaeU81TldacFp5TzVOR2RtQXlPNU5tYW1zVGVqdFdkcFp5TzVObWJtc1RlakZtSjdrM1l3WnlPNU4yYm1zVGVqdGtKZzB5TzVOR2Jtc1RlanhtSjdrM1lyVlhhbXNUZWpSa0o%3D');
INSERT INTO "public"."reactiv_menu" ("id", "name", "position", "units_id", "comment") VALUES (12, 'Реагент 7В 2,5% розчин тіоціонату кобальту', 0, 1, 'PT13T3AxV1p6WkNNeHNUYjE1bUo3a1dibE5uSjRNek90Vm5ibXNEY3RGbUo3a1dibE5uSndFek90Vm5ibXNUYXRWMmNtZ3pNNzBXZHVaeU93MVdZbXNUYXRWMmNtQVRNNzBXZHVaeU9wMVdaelpDT3pzVGIxNW1KN0FYYmhaeU9rOVdheVZHY21zVGVqVm5KN2szWXVaeU81TldhNVp5TzVOV1ltc1RlanRtSjdrM1l2WnlPNU4yYW1BeU81TkdkbTkyY21zVGVqUm5KN2szWXpaeU81TjJhMWxtSjdrM1l1WnlPNU5HZG1zVGVqVm5KN2szWXpaeU81TldhbXNUZWpKbko3azNZd1pDSTdrM1kxWnlPNU5tZG1zVGVqbG1KN2szWXNaeU81TkdhNlp5TzVOMmJtc1RlajFtSmdzVGVqRm1KN2szWXVaQ0k3azNZclZuYW1zVGVqVm5KN2szWTZaeU81TldZbXNUZWp0bUo3azNZMlpDSTdrM1lobG5KN2szWXVaeU81Tm1ibXNUZWpWV2Ftc1RlanhtSjdrM1kyWnlPNU5tY21zVGVqRm1KN2szWWlaeU81TldZbXNUZWpwbkpnc1RlanRXZHFaeU81Tm1ibXNUZWpsbUo3azNZVFp5T2s5V2F5VkdjbXNUZWpSbko3azNZaFp5TzVOR2Rtc1RlalJuWnZObko3azNZc1p5TzVOV2Rtc1RlanBuSjdrM1lsbG1KN2szWVNaeU9wMVdaelpDTXhzVGIxNW1KN2tXYmxObko0TXpPdFZuYm1zRGN0Rm1KN2tXYmxObkp3RXpPdFZuYm1zVGF0VjJjbWd6TTcwV2R1WnlPdzFXWW1zRFp2bG1jbEJuSjdrM1kxWnlPNU4yYW1zVGVqSm5KN2szWXJWWGFtc1RlakptSjdrM1l2WnlPNU5tY21zVGVqQm5KZ3NUZWpsbUo3azNZMFp5TzVOV2Ftc1Rlak5uSjdrM1kxWnlPNU5tY21zVGVqUm5KN2szWTZaQ0k3azNZaFp5TzVOR2RtQXlPNU5tVm1jREk3azNZaFp5TzVOR2Rtc1RlajVtSjdrM1lsbG1KN2szWW5aeU81TldZbXNUZWpWV2Ftc1RlakpuSmdzVGVqVlhlbXNUZWp4bUo3azNZd1p5TzVOV1ltc1RlakpuSjdrM1lyWkNJeEF5TzVOV2Ftc1RlalJuSjdrM1loWnlPNU5HWm1zVGVqOW1KN2szWUVaQ0k3UTJicEpYWndaeU03a1dibE5uSndFek90Vm5ibXNUYXRWMmNtZ3pNNzBXZHVaeU93MVdZbXNEWnZsbWNsQm5KN2szWWtaeU81Tm1ibXNUZWpWbko3azNZclp5TzVOV1pwWnlPNU4yY21BeU81Tkdhclp5TzVOMmJtc1RlanRtSjdrM1kwWjJielp5TzVOR2Jtc1RlanRXZHBaeU81TjJhbXNUZWpWV2Ftc1RlalJtSmdzVGVqMW1KN2szWXZaeU81TjJabXNUZWpGV2Vtc1RlalJuSjdrM1l2WnlPNU5tY21zVGVqQm5KZ3NUZWpWbko3azNZclp5TzVObWNtc1RlanRXZHBaeU81Tm1ZbXNUZWo5bUo3azNZeVp5TzVOR2NtQXlPNU5XYW1zVGVqUm5KN2szWXBaeU81TjJjbXNUZWpWbko3azNZeVp5TzVOR2Rtc1RlanBuSmdzVGVqRm1KN2szWTBaQ0k3azNZQlp5TmdzVGVqVm5KN2szWTBaeU81Tm1ibXNUZWpWV2Ftc1RlamRtSjdrM1loWnlPNU5XWnBaeU81Tm1jbUF5TzVOV2Q1WnlPNU5HYm1zVGVqQm5KN2szWWhaeU81Tm1jbXNUZWp0bUpnRURJN2szWXBaeU81TkdkbXNUZWpGbUo3azNZa1p5TzVOMmJtc1RlalJrSmdzRFp2bG1jbEJuSnlzVGF0VjJjbUFUTTcwV2R1WnlPcDFXWnpaQ096c1RiMTVtSjdBWGJoWnlPazlXYXlWR2Ntc1RlamxtSjdrM1lyWnlPNU5tY21zVGVqdFdkcFp5TzVObVltc1RlajltSjdrM1l5WnlPNU5HY21BeU81TjJibXNUZWpSbUpnc1RlamxtSjdrM1kwWnlPNU5XYW1zVGVqUm5KN2szWXpaeU81TjJhMWxtSjdrM1l0WnlPNU4yYm1zVGVqQm5KZ3NUZWpWbko3azNZc1p5TzVOV1ltc1RlanRXZHBaeU81Tm1jbXNUZWpWV2Ftc1RlalJuSjdrM1loWnlPNU5XYm1BeU81TkdkbTkyY21zVGVqUm5KN2szWXpaeU81TjJhMWxtSjdrM1lyWnlPNU5HZG05MmNtc1RlanhtSjdrM1lyVlhhbXNUZWp0bUpnc1RlalZuSjdrM1lyWnlPNU5XYW1zVGVqeG1KN2szWWxsbUo3azNZMlp5TzVOV1pwWnlPNU5tVG1BeU9rOVdheVZHY21Fek9wMVdaelpDTXhzVGIxNW1KN2tXYmxObko0TXpPdFZuYm1zRGN0Rm1KNzQyYnM5Mlltc1RlalJuSjdrM1l6WnlPNU5XWnBaeU81TkdWbXNUYXRWMmNtQVRNNzBXZHVaeU9wMVdaelpDT3pzVGIxNW1KN0FYYmhaeU9wMVdaelpDTXhzVGIxNW1KN2tXYmxObko0TXpPdFZuYm1zRGN0Rm1KN1EyYnBKWFp3WnlPNU5XYW1zVGVqUm1KN2szWXZaeU81Tm1kbUF5TzVOV2E1WnlPNU4yYm1zVGVqNW1KN2szWWhaeU81Tm1kbXNUZWo5bUo3azNZNlp5TzVOMmExbG1KN2szWXVaeU81TjJibXNUZWpwbUo3azNZbGxtSjdrM1lrWkNJN2szWXNaeU81TldibUFDTXdFREk3azNZMlpDSTdJWFl3Sm5KN2szWXJWWFNtc1RlanRXZEpaeU95Rkdjc1pDSTdrM1loWnlPNU5HZG1zVGVqeG1KN2szWWhaeU81Tm1ZbXNUZWo5bUo3azNZclpDSTdrM1kxWnlPNU5HZG1zVGVqRm1KN2szWXVaeU81TjJibXNUZWp0V2RwWnlPNU4yYzBaeU81TjJibXNUZWp0V2RwWnlPNU5HZG1BeU81TjJabUFTTjdFV2J0OTJZbUlESTdrM1lwWnlPNU5HZG1zVGVqbG1KN2szWXVaeU81TldhbXNUZWpoMlltc1RlanBuSjdrM1l2WnlPNU5tVW1BeU91OUdidk5tSjdrM1lXWnlOZ3NUZWpSbko3azNZdVp5TzVOV1pwWnlPNU4yWm1zVGVqRm1KN2szWWxsbUo3azNZU1p5T3AxV1p6WkNNeHNUYjE1bUo3a1dibE5uSjRNek90Vm5ibXNEY3RGbUo3azNZcFp5TzVOR2Rtc1RlajltSjdrM1lzWnlPNU4yY21zVGVqbG1KN2szWXJaQ0k3azNZcGxuSjdrM1l2WnlPNU5tYm1zVGVqUm1KN2szWXBaeU81Tm1jbXNUZWo5bUo3azNZc1p5TzVOR2FyWkNJN2szWXVaeU81TldhbXNUZWpoMlltc1RlanBuSjdrM1l2WnlPNU5tY21BeU81Tm1hbXNUZWpsbUo3azNZdVp5TzVOR1ptc1RlajltSjdrM1kyWkNJN1FuYmpKWFp3WmlOeEF5T3U5R2J2Tm1KN2szWWhaeU5nc1RlalJuSjdrM1l1WnlPNU5XWnBaeU81TjJabXNUZWpGbUo3azNZbGxtSjdrM1lTWnlPcDFXWnpaQ014c1RiMTVtSjdrV2JsTm5KNE16T3RWbmJtc0RjdEZtSjdrM1kxWnlPNU5HZG1zVGVqUm5adk5uSjdrM1lzWnlPNU5XWW1zVGVqSm1KN2szWXZaeU81TjJhbUF5TzVOV2Jtc1RlajltSjdrM1kwWnlPNU5XWW1zVGVqNW1KN2szWXZaeU81TjJhMWxtSjdrM1l6Um5KN2szWXZaeU81TjJhMWxtSjdrM1kwWkNJN2szWTZaQ0k3azNZMFp5TzVOMmNtc1RlalZXYW1zVGVqUmxK');
INSERT INTO "public"."reactiv_menu" ("id", "name", "position", "units_id", "comment") VALUES (10, 'Реагент 8А. Модифікований тест з тіоціонатом кобальту (ІІ)', 0, 1, 'PXNUZWoxbUo3azNZeVp5TzVOMmJtc1RlalptSjdrM1l2WnlPNU5tY21zVGVqOW1KN2szWXNaeU81TkdTTFpDSTdrM1l6WkNPZ3NUZWpSbko3azNZdVp5TzVOV1pwWnlPNU4yWm1zVGVqRm1KN2szWWxsbUo3azNZU1p5T3AxV1p6WkNNeHNUYjE1bUo3a1dibE5uSjRNek90Vm5ibXNEY3RGbUo3azNZaFp5TzVOR2Rtc1RlajltSjdrM1lzWnlPNU4yY21zVGVqbG1KN2szWXJaQ0k3azNZaFp5TzVObWJtc1RlalJtSjdrM1lwWnlPNU5tY21zVGVqOW1KN2szWXNaeU81TkdhclpDSTdrM1loWnlPNU5tYm1zVGVqRm1KN2szWTJaeU81TjJibXNUZWpKbko3azNZMFp5TzVObWJtc1RlalZXYW1zVGVqTkhkbXNUZWo1bUo3azNZdlp5TzVOMmFtQXlPNU5tVm1nREk3azNZMFp5TzVObWJtc1RlalZXYW1zVGVqZG1KN2szWWhaeU81TldacFp5TzVObVVtc1RhdFYyY21BVE03MFdkdVp5T3AxV1p6WkNPenNUYjE1bUo3QVhiaFp5T2s5V2F5VkdjbXNUZWpWbko3azNZdVp5TzVOV2Ftc1RlakpuSjdrM1lsbG1KN2szWXpSbko3azNZclZYYW1zVGVqeG1KN2szWW5aQ0k3azNZc1p5TzVOV2JtQUNNMUF5TzVOV2Ftc1RlalJuSjdrM1loWnlPNU5HWm1zVGVqOW1KN2szWWtaQ0k3azNZdFp5TzVOMmExbG1KN2szWTBaeU81TjJibXNUZWpCbkpnc1RZdDEyYmpaeU81TldhbXNUZWpSbko3azNZdlp5TzVOR2Jtc1Rlak5uSjdrM1lwWnlPNU4yYW1BeU81TldhNVp5TzVOMmJtc1RlalpuSjdrM1l2WnlPNU5HZG1zVGVqTkhkbXNUZWo5bUo3SVhZd0puSjdrM1l0WnlPNU4yYTFwbUo3azNZaVp5TzVOMmJtc0Ridk5uSjdrM1l0WnlPNU4yYTFwbUo3azNZaVp5TzVOMmJtQXlPNU4yYTFsbUo3azNZdVp5TzVOV1pwWnlPNU5HYXpaeU81TjJibXNUZWo1bUo3azNZa1p5TzVOMmExbG1KN2szWTJaQ0k3azNZMVp5T3lGR2NzWkNJN1FuYmpKWFp3WkNNeEFDSTdrM1lzWnlPNU5XYm1BQ00xQXlPNU5tZG1BeU95RkdjeVp5TzVOMmExbGtKN2szWXJWWFNtc2pjaEJIYm1BeU81TldZbXNUZWpSbko3azNZMFoyYnpaeU81TkdibXNUZWpGbUo3azNZaVp5TzVOMmJtc1RlanRtSmdzVGVqVm5KN2szWTBaeU81TldZbXNUZWo1bUo3azNZdlp5TzVOMmExbG1KN2szWXpSbko3azNZdlp5TzVOMmExbG1KN2szWTBaQ0k3azNZblpDSXhBeU81TldhbXNUZWpSbko3azNZcFp5TzVObWJtc1RlamxtSjdrM1lvTm1KN2szWTZaeU81TjJibXNUZWpKbEpnc0RadmxtY2xCbko3azNZQlpDT2dzVGVqUm5KN2szWXVaeU81TldacFp5TzVOMlptc1RlakZtSjdrM1lsbG1KN2szWVNaeU9wMVdaelpDTXhzVGIxNW1KN2tXYmxObko0TXpPdFZuYm1zRGN0Rm1KN1EyYnBKWFp3WnlPNU5XWW1zVGVqUm5KN2szWTBaeU81TjJibXNUZWp0bUo3azNZVFpDSTdrM1kwWnlPNU4yY21zVGVqVldhbXNUZWpSbEo%3D');


--
-- Data for Name: reactiv_menu_ingredients; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO "public"."reactiv_menu_ingredients" ("reagent_id", "reactiv_menu_id", "unique_index") VALUES (57, 8, '97dcd152ceb2613a6f02c4e12cc45591');
INSERT INTO "public"."reactiv_menu_ingredients" ("reagent_id", "reactiv_menu_id", "unique_index") VALUES (82, 8, '3af85f32db0dcd0caf0c2ddff843ad4b');
INSERT INTO "public"."reactiv_menu_ingredients" ("reagent_id", "reactiv_menu_id", "unique_index") VALUES (6, 11, '49805866fb4f23211d88a193f2e57f5a');
INSERT INTO "public"."reactiv_menu_ingredients" ("reagent_id", "reactiv_menu_id", "unique_index") VALUES (16, 11, '69b3906739cc2855b347066eb6dd8bc5');
INSERT INTO "public"."reactiv_menu_ingredients" ("reagent_id", "reactiv_menu_id", "unique_index") VALUES (22, 11, '96311d4f17c594b0a810f5066090ab5d');
INSERT INTO "public"."reactiv_menu_ingredients" ("reagent_id", "reactiv_menu_id", "unique_index") VALUES (63, 13, '91b8452d01765acf65983f1d973365f0');
INSERT INTO "public"."reactiv_menu_ingredients" ("reagent_id", "reactiv_menu_id", "unique_index") VALUES (29, 12, 'ed11e899101a24808324f52aef550826');
INSERT INTO "public"."reactiv_menu_ingredients" ("reagent_id", "reactiv_menu_id", "unique_index") VALUES (18, 10, '92394cbc0df84c9be44e88480281491e');
INSERT INTO "public"."reactiv_menu_ingredients" ("reagent_id", "reactiv_menu_id", "unique_index") VALUES (29, 10, '78274efadf61e0edf96a5cee8d138ade');
INSERT INTO "public"."reactiv_menu_ingredients" ("reagent_id", "reactiv_menu_id", "unique_index") VALUES (51, 10, 'a0dbb792aae8f065286520f861a438af');
INSERT INTO "public"."reactiv_menu_ingredients" ("reagent_id", "reactiv_menu_id", "unique_index") VALUES (26, 14, 'a4968457938d3db4d37fd9930d1934f9');
INSERT INTO "public"."reactiv_menu_ingredients" ("reagent_id", "reactiv_menu_id", "unique_index") VALUES (32, 14, '8c64922e116896605a72b0bf03198a04');
INSERT INTO "public"."reactiv_menu_ingredients" ("reagent_id", "reactiv_menu_id", "unique_index") VALUES (57, 7, 'e16c066a7fff0b028ee67ddda7ebb310');
INSERT INTO "public"."reactiv_menu_ingredients" ("reagent_id", "reactiv_menu_id", "unique_index") VALUES (62, 7, 'f227dda84f830026f4d6eb57d5c1a615');
INSERT INTO "public"."reactiv_menu_ingredients" ("reagent_id", "reactiv_menu_id", "unique_index") VALUES (40, 17, 'd05130f3c4d5381ad95b6f3bfb4a3f4c');
INSERT INTO "public"."reactiv_menu_ingredients" ("reagent_id", "reactiv_menu_id", "unique_index") VALUES (27, 15, '63c60fb2d19a9f36c33ee0de1d5a36d2');
INSERT INTO "public"."reactiv_menu_ingredients" ("reagent_id", "reactiv_menu_id", "unique_index") VALUES (86, 15, '37ae67b74ff7331f09a3a9e2fb5ae191');
INSERT INTO "public"."reactiv_menu_ingredients" ("reagent_id", "reactiv_menu_id", "unique_index") VALUES (84, 9, '0d18f7cbd46f131ac70a11a9c818b035');
INSERT INTO "public"."reactiv_menu_ingredients" ("reagent_id", "reactiv_menu_id", "unique_index") VALUES (6, 16, '36b00917068fdd42776ed4715c547cab');
INSERT INTO "public"."reactiv_menu_ingredients" ("reagent_id", "reactiv_menu_id", "unique_index") VALUES (43, 16, '131badea4b0981702ddf6e9ea071aed3');
INSERT INTO "public"."reactiv_menu_ingredients" ("reagent_id", "reactiv_menu_id", "unique_index") VALUES (10, 18, 'fff03b0e00917d84a5fdfe25854cf156');
INSERT INTO "public"."reactiv_menu_ingredients" ("reagent_id", "reactiv_menu_id", "unique_index") VALUES (43, 18, 'f02e2d51428fe2b0a6b25890760835eb');
INSERT INTO "public"."reactiv_menu_ingredients" ("reagent_id", "reactiv_menu_id", "unique_index") VALUES (57, 19, 'efa3d271ea7ff9851090276c18b157a7');
INSERT INTO "public"."reactiv_menu_ingredients" ("reagent_id", "reactiv_menu_id", "unique_index") VALUES (87, 19, 'ad91554f8cb37cdf144750324e0d2ee5');
INSERT INTO "public"."reactiv_menu_ingredients" ("reagent_id", "reactiv_menu_id", "unique_index") VALUES (2, 20, '481cd9a1cf31edae440d1b94fbf55bc9');
INSERT INTO "public"."reactiv_menu_ingredients" ("reagent_id", "reactiv_menu_id", "unique_index") VALUES (32, 20, '330419b62dfbb182963943f483547795');
INSERT INTO "public"."reactiv_menu_ingredients" ("reagent_id", "reactiv_menu_id", "unique_index") VALUES (88, 24, '93d4bd2bb258f81f2dbe8d2122e7e5bb');
INSERT INTO "public"."reactiv_menu_ingredients" ("reagent_id", "reactiv_menu_id", "unique_index") VALUES (91, 24, '1e38609776c64a561b005e61096d2e90');
INSERT INTO "public"."reactiv_menu_ingredients" ("reagent_id", "reactiv_menu_id", "unique_index") VALUES (81, 21, '2041799c79047bc8d23cf55800471665');
INSERT INTO "public"."reactiv_menu_ingredients" ("reagent_id", "reactiv_menu_id", "unique_index") VALUES (88, 21, '50c3df4bfbca963a7eb133f0b80c6125');
INSERT INTO "public"."reactiv_menu_ingredients" ("reagent_id", "reactiv_menu_id", "unique_index") VALUES (89, 22, '65694ec66f64e5ffffc33fb23cdaf0bb');
INSERT INTO "public"."reactiv_menu_ingredients" ("reagent_id", "reactiv_menu_id", "unique_index") VALUES (2, 23, '12a32992180ae9275aec0cb4577b8f83');
INSERT INTO "public"."reactiv_menu_ingredients" ("reagent_id", "reactiv_menu_id", "unique_index") VALUES (88, 23, '47c5ca7010e2b29f7b28599a94e78af9');
INSERT INTO "public"."reactiv_menu_ingredients" ("reagent_id", "reactiv_menu_id", "unique_index") VALUES (32, 25, '6dfd7ac41991f0fc03501864d4c7cd6f');
INSERT INTO "public"."reactiv_menu_ingredients" ("reagent_id", "reactiv_menu_id", "unique_index") VALUES (51, 25, 'd5268a7f6126e313b694a53e8261fd33');
INSERT INTO "public"."reactiv_menu_ingredients" ("reagent_id", "reactiv_menu_id", "unique_index") VALUES (92, 25, 'd9a4472d125676846f6e69d6975c087c');
INSERT INTO "public"."reactiv_menu_ingredients" ("reagent_id", "reactiv_menu_id", "unique_index") VALUES (32, 26, '0f0dcb4950097014e14eac9dd2dedf56');
INSERT INTO "public"."reactiv_menu_ingredients" ("reagent_id", "reactiv_menu_id", "unique_index") VALUES (90, 26, '771922666aabcfd406d3eacedab53869');
INSERT INTO "public"."reactiv_menu_ingredients" ("reagent_id", "reactiv_menu_id", "unique_index") VALUES (22, 27, '0f1fd5a7d717a59e08ba450530ebf4b3');
INSERT INTO "public"."reactiv_menu_ingredients" ("reagent_id", "reactiv_menu_id", "unique_index") VALUES (26, 27, '2a385da0cbc254bbca2680482f889036');
INSERT INTO "public"."reactiv_menu_ingredients" ("reagent_id", "reactiv_menu_id", "unique_index") VALUES (32, 28, '2cbc2729770d560fc8849b0909d1c12d');
INSERT INTO "public"."reactiv_menu_ingredients" ("reagent_id", "reactiv_menu_id", "unique_index") VALUES (50, 28, 'fa3816d777590d69dc1f74aa914d72c1');
INSERT INTO "public"."reactiv_menu_ingredients" ("reagent_id", "reactiv_menu_id", "unique_index") VALUES (93, 28, 'ff722993ba63d9621a346c76a8898f7c');


--
-- Data for Name: reagent; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (113, '2020-04-07 14:18:43.640017', 'Циліндр мірний 3-50-2', 3, 9);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (2, '2020-01-02 15:39:01.529732', '1,3-динітробензол', 3, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (21, '2020-01-02 15:39:01.529732', 'Діетиловий ефір', 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (24, '2020-01-02 15:39:01.529732', 'Ефір диізопропіловий', 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (25, '2020-01-02 15:39:01.529732', 'Ізопропанол', 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (115, '2020-04-07 14:19:17.871653', 'Колба круглодонна К-1-1000-29/32 ТС', 3, 9);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (23, '2020-01-02 15:39:01.529732', 'Етилацетат', 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (20, '2020-01-02 15:39:01.529732', 'Діетиламін', 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (145, '2020-04-07 16:37:25.612425', 'Фіксанал рН-метрія', 3, 9);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (82, '2020-03-17 12:38:38.461639', 'Селениста кислота', 2, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (10, '2020-01-02 15:39:01.529732', 'Ацетон', 1, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (22, '2020-01-02 15:39:01.529732', 'Етанол', 1, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (84, '2020-03-18 12:58:32.313461', 'Сульфат заліза (ІІІ)', 1, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (85, '2020-03-18 15:48:39.161596', 'Хлоридна кислота розбавлена (Реагент)', 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (86, '2020-03-18 17:58:42.08735', 'Йод кристалічний', 2, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (138, '2020-04-07 15:55:39.189422', '1-Нафтиламін', 3, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (87, '2020-03-18 18:20:35.233556', 'Галова кислота', 2, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (88, '2020-03-19 10:33:04.64491', 'Поліетиленгліколь', 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (90, '2020-03-19 10:39:52.749282', 'ізопропіламін', 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (93, '2020-03-19 11:41:30.12809', '4-диметиламінобензальдегід', 2, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (109, '2020-04-07 14:17:33.276378', 'Піпетка мірна з градуювавнням (клас А) 50 мл (повний злив)', 3, 9);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (11, '2020-01-02 15:39:01.529732', 'Ацетонітрил', 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (12, '2020-01-02 15:39:01.529732', 'Барій сульфат', 2, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (3, '2020-01-02 15:39:01.529732', '1,4-Диоксан', 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (4, '2020-01-02 15:39:01.529732', 'N, N - диметилформамід', 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (116, '2020-04-07 14:40:35.767479', 'Циліндр мірний 1-2000-2', 3, 9);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (6, '2020-01-02 15:39:01.529732', 'Альдегід оцтовий', 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (7, '2020-01-02 15:39:01.529732', 'Аміак 25%', 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (8, '2020-01-02 15:39:01.529732', 'Амоній молібденовокислий', 2, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (9, '2020-01-02 15:39:01.529732', 'Аргентум нітрат', 2, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (13, '2020-01-02 15:39:01.529732', 'Барію хлорид', 2, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (14, '2020-01-02 15:39:01.529732', 'Бензол', 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (118, '2020-04-07 14:41:11.678451', 'Колба мірна КМ-1-1000-2 ХС', 3, 9);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (0, '2019-12-28 11:10:26.287818', '--', 0, 0);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (15, '2020-01-02 15:39:01.529732', 'Бутанол', 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (119, '2020-04-07 14:41:25.455194', 'Колба мірна КМ-1-500-2 ХС', 3, 9);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (120, '2020-04-07 14:41:45.689113', 'Колба мірна КМ-1-100-2 ТС', 3, 9);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (122, '2020-04-07 14:42:06.665785', 'Колба мірна КМ-1-50-2 ТС', 3, 9);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (124, '2020-04-07 14:42:57.619121', 'Стакан високий з носиком і градуюванням В-1-250 ТС', 3, 9);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (16, '2020-01-02 15:39:01.529732', 'Ванілін', 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (126, '2020-04-07 14:44:53.634798', 'Воронка лабораторна В-25-38 ТС', 3, 9);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (17, '2020-01-02 15:39:01.529732', 'Вісмут нітрат', 2, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (128, '2020-04-07 15:16:36.487966', 'Алізарин', 3, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (91, '2020-03-19 10:43:04.659486', '1,4-динітробензол', 3, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (99, '2020-04-07 11:20:24.436048', 'Гексан', 3, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (100, '2020-04-07 12:03:13.452631', 'Плавікова (фтороводнева) кислота', 3, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (5, '2020-01-02 15:39:01.529732', 'Азотна (нітратна) кислота', 3, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (101, '2020-04-07 13:56:07.159233', 'Воронка лабораторна B-150-230 ТС', 3, 9);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (129, '2020-04-07 15:26:10.841277', 'Гідроксиламін солянокислий', 3, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (131, '2020-04-07 15:38:10.815295', 'Калій двохромовокислий', 3, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (102, '2020-04-07 14:08:22.95967', 'Колба конічна КН-1-250-29/32 ТС з градуюванням', 3, 9);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (133, '2020-04-07 15:43:18.99065', 'Метиленовий синій', 3, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (103, '2020-04-07 14:09:18.312054', 'Піпетка мірна (Мора) з однією міткою 2-2-2 мл', 3, 9);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (135, '2020-04-07 15:43:52.221984', 'Натрій гексанітрокобальтат, 0,5-водн.', 3, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (105, '2020-04-07 14:10:19.676107', 'Піпетка мірна з градуювавнням 2-2-2-2 мл (повний злив)', 3, 9);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (107, '2020-04-07 14:11:08.117704', 'Піпетка мірна з градуювавнням 2-2-2-10 мл (повний злив)', 3, 9);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (18, '2020-01-02 15:39:01.529732', 'Гліцерин', 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (136, '2020-04-07 15:52:59.34017', 'Натрій сірчистокислий', 3, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (83, '2020-03-17 12:43:19.841877', 'Дистильована вода', 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (19, '2020-01-02 15:39:01.529732', 'Дифенілкарбазон', 2, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (92, '2020-03-19 11:06:13.688529', 'ацетат кобальту (ІІ)', 1, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (111, '2020-04-07 14:18:07.574614', 'Пробірка з притертою пробкою 25 мл', 3, 9);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (139, '2020-04-07 16:06:14.901219', '8-Оксихінолін', 3, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (141, '2020-04-07 16:08:44.760134', 'Пероксид водню 35%', 3, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (143, '2020-04-07 16:09:47.31349', 'Ртуть (ІІ) сірчанокисла', 3, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (81, '2020-03-16 22:23:10.617711', '1,2-динітробензол', 3, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (147, '2020-04-07 16:37:53.933174', 'Фіксанал натрій гідроксид ПЕ, 0,1 Н', 3, 9);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (149, '2020-04-07 16:38:25.763858', 'Фіксанал соляної (хлоридної) кислоти 0,1 Н', 3, 9);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (150, '2020-04-07 16:46:42.807242', 'Цинк сірчанокислий, 7-водн.', 3, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (151, '2020-04-07 16:51:42.502585', 'Амоній оцтовокислий (ацетат)', 3, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (153, '2020-04-07 17:08:10.789344', 'Метиловий оранжевий', 3, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (155, '2020-04-07 17:20:53.028185', 'Вазелінова олія', 3, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (156, '2020-04-07 17:24:38.219001', 'Парафін нафтовий', 3, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (56, '2020-01-02 15:39:01.529732', 'Сульфанілова кислота', 0, 0);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (65, '2020-01-02 15:39:01.529732', 'Циклогексан', 1, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (59, '2020-01-02 15:39:01.529732', 'Тривкий синій Б', 2, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (89, '2020-03-19 10:39:07.096009', 'Літій гідроксид', 2, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (26, '2020-01-02 15:39:01.529732', 'Калій гідроксид', 2, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (27, '2020-01-02 15:39:01.529732', 'Калію йодид', 2, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (28, '2020-01-02 15:39:01.529732', 'Кальцію хлорид б/в', 2, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (29, '2020-01-02 15:39:01.529732', 'Кобальт тіоціонат', 2, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (30, '2020-01-02 15:39:01.529732', 'Магній сульфат', 2, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (31, '2020-01-02 15:39:01.529732', 'Меркурій (ІІ) хлорид', 2, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (32, '2020-01-02 15:39:01.529732', 'Метанол', 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (33, '2020-01-02 15:39:01.529732', 'Метилен хлористий', 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (34, '2020-01-02 15:39:01.529732', 'Метилстеарат для ГХ', 2, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (36, '2020-01-02 15:39:01.529732', 'Мурашина кислота', 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (158, '2020-04-07 17:29:34.885205', 'Тимол', 3, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (37, '2020-01-02 15:39:01.529732', 'Натрій ванадат', 2, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (38, '2020-01-02 15:39:01.529732', 'Натрій гідрокарбонат', 2, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (39, '2020-01-02 15:39:01.529732', 'Натрій гідроксид', 2, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (40, '2020-01-02 15:39:01.529732', 'Натрій карбонат', 2, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (41, '2020-01-02 15:39:01.529732', 'Натрій молібдат', 2, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (42, '2020-01-02 15:39:01.529732', 'Натрій нітрит', 2, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (43, '2020-01-02 15:39:01.529732', 'Натрій нітропрусид', 2, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (44, '2020-01-02 15:39:01.529732', 'Натрій сульфат б/в', 2, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (45, '2020-01-02 15:39:01.529732', 'Натрію хлорид', 2, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (46, '2020-01-02 15:39:01.529732', 'Нафтол альфа', 2, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (47, '2020-01-02 15:39:01.529732', 'н-Гексан', 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (48, '2020-01-02 15:39:01.529732', 'Нінгідрин', 2, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (49, '2020-01-02 15:39:01.529732', 'о-Ксилол', 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (50, '2020-01-02 15:39:01.529732', 'Ортофосфорна кислота', 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (51, '2020-01-02 15:39:01.529732', 'Оцтова кислота, льодяна', 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (52, '2020-01-02 15:39:01.529732', 'п-Диметиламінобензальдегід', 2, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (54, '2020-01-02 15:39:01.529732', 'Піридин', 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (55, '2020-01-02 15:39:01.529732', 'Платина VI хлорид', 2, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (57, '2020-01-02 15:39:01.529732', 'Сульфатна кислота концентрована', 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (58, '2020-01-02 15:39:01.529732', 'Толуол', 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (60, '2020-01-02 15:39:01.529732', 'Фенолфталеїн', 2, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (61, '2020-01-02 15:39:01.529732', 'Ферум (ІІІ) хлорид', 2, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (62, '2020-01-02 15:39:01.529732', 'Формальдегід', 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (63, '2020-01-02 15:39:01.529732', 'Хлоридна кислота концентрована', 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (64, '2020-01-02 15:39:01.529732', 'Хлороформ', 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (104, '2020-04-07 14:09:36.33392', 'Піпетка мірна (Мора) з однією міткою 2-2-5 мл', 3, 9);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (106, '2020-04-07 14:10:33.319837', 'Піпетка мірна з градуювавнням 2-2-2-5 мл (повний злив)', 3, 9);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (108, '2020-04-07 14:16:54.367161', 'Піпетка мірна з градуювавнням 2-2-2-25 мл (повний злив)', 3, 9);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (110, '2020-04-07 14:17:54.142579', 'Колба конічна КН-1-50-14/23 ТС з градуюванням', 3, 9);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (112, '2020-04-07 14:18:26.685373', 'Циліндр мірний 1-10-2', 3, 9);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (114, '2020-04-07 14:18:58.561129', 'Колба круглодонна К-1-500-29/32 ТС', 3, 9);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (117, '2020-04-07 14:40:56.633385', 'Циліндр мірний 3-500-2', 3, 9);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (121, '2020-04-07 14:41:55.932974', 'Колба мірна КМ-1-250-2 ТС', 3, 9);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (123, '2020-04-07 14:42:42.185927', 'Пробка гумова до флакону пеніцилінового', 3, 9);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (125, '2020-04-07 14:44:22.970071', 'Стакан високий з носиком і градуюванням В-1-100 ТС', 3, 9);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (127, '2020-04-07 14:45:04.690687', 'Воронка лабораторна В-36-50 ТС', 3, 9);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (130, '2020-04-07 15:26:32.541169', 'Гідроксиламін сірчанокислий', 3, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (132, '2020-04-07 15:38:30.369715', 'Калій хромовокислий', 3, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (137, '2020-04-07 15:53:16.728547', 'Натрій сірчанокислий', 3, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (140, '2020-04-07 16:08:17.594711', 'Пероксид водню 60%', 3, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (142, '2020-04-07 16:08:52.472055', 'Пероксид водню 50%', 3, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (144, '2020-04-07 16:13:05.193681', 'Срібло азотнокисле', 3, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (146, '2020-04-07 16:37:43.50034', 'Фіксанал калій гідроксид ПЕ, 0,1 Н', 3, 9);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (148, '2020-04-07 16:38:12.998664', 'Фіксанал сірчаної (сульфатної) кислоти 0,1 Н', 3, 9);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (152, '2020-04-07 16:52:58.665474', 'Вазелін білий', 3, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (134, '2020-04-07 15:43:34.98952', 'Мідь (ІІ) сульфат', 3, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (154, '2020-04-07 17:16:58.382986', 'Метиловий червоний', 3, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (157, '2020-04-07 17:29:20.373593', 'Пікринова кислота', 3, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (159, '2020-04-07 17:29:39.806902', 'Тимолфталеїн', 3, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (160, '2020-04-07 17:41:49.552188', 'Флакон пеніциліновий 10 мл', 3, 9);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (161, '2020-04-07 17:42:18.761341', 'Циліндр мірний 1-1000-2', 3, 9);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (162, '2020-04-07 17:42:31.182155', 'Воронка лабораторна B-100-150 ТС', 3, 9);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (163, '2020-04-07 17:42:45.426515', 'Воронка лабораторна B-75-110 ТС', 3, 9);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (164, '2020-04-07 17:42:55.315041', 'Воронка лабораторна B-56-80 ТС', 3, 9);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (165, '2020-04-09 09:19:52.7962', 'Калій марганцевокислий (перманганат)', 3, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (166, '2020-04-09 09:26:56.684775', 'Пульверизатор скляний для ТШХ з грушею', 3, 9);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (167, '2020-04-09 12:05:00.822686', 'Кювета кварцева, 10 мм', 3, 9);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (169, '2020-04-09 12:05:58.964821', 'Кришки, що загвинчуються, 9 мм, септа PTFE/red silicone', 3, 9);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (170, '2020-04-09 12:06:11.908371', 'Маркер для надпису на склі', 3, 9);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (171, '2020-04-09 12:06:47.117751', 'Накінечник для дозаторів на 10 мкл', 3, 9);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (172, '2020-04-09 12:06:54.994581', 'Накінечник для дозаторів на 1000 мкл', 3, 9);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (173, '2020-04-09 12:07:37.903984', 'Пластини фірми "Сорбфіл" ПТСХ АФ-А 100*100', 3, 9);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (174, '2020-04-09 12:08:58.877455', 'Пластини фірми "Merck" TLC Silica gel 60 F254 200*200', 3, 9);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (175, '2020-04-09 12:10:01.207508', 'Хлороформ для хроматографії', 3, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (176, '2020-04-09 12:10:14.717966', 'Метанол для хроматографії', 3, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (168, '2020-04-09 12:05:37.199314', 'Віали на 1,5 мл, під кришку, що загвинчується, прозоре скло', 3, 9);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (177, '2020-04-09 12:11:24.436478', 'Гексан для хроматографії', 3, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (178, '2020-04-09 12:17:16.817598', 'ЕДТА (Етилендиамін-N,N,N;N;-тетраоцтова кислота) (Трилон БС)', 3, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (179, '2020-04-09 13:20:56.330109', 'Циліндр Генера на 160 мл з краником', 3, 9);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (180, '2020-04-09 13:30:48.499437', 'Корок гумовий 19 мм', 3, 9);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (181, '2020-04-09 13:30:57.988016', 'Корок гумовий 24 мм', 3, 9);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (182, '2020-04-09 13:31:07.909363', 'Корок гумовий 29 мм', 3, 9);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (183, '2020-04-09 13:31:22.208571', 'Корок гумовий 34,5 мм', 3, 9);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (184, '2020-04-09 13:31:29.486679', 'Корок гумовий 40 мм', 3, 9);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (185, '2020-04-09 13:31:36.96349', 'Корок гумовий 45 мм', 3, 9);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (186, '2020-04-09 13:32:00.662133', 'Банка 250 світле скло, закрутка, мітки ТС', 3, 9);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (187, '2020-04-09 13:32:15.638934', 'Банка 500 світле скло, закрутка, мітки ТС', 3, 9);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (188, '2020-04-09 13:43:54.771545', 'Гептан', 3, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (189, '2020-04-09 14:05:50.071627', 'Лакмус', 3, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (190, '2020-04-09 14:09:15.993379', 'Папір індикаторний універсальний', 3, 9);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (191, '2020-04-09 14:11:38.820383', 'Віала на 1,5 мл з кришкою та септою', 3, 9);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (192, '2020-04-09 14:12:27.483558', 'Гелій підвищеної чистоти (99,999%)', 3, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (193, '2020-04-09 14:12:51.672115', 'Мікровіала на 0,250 мл', 3, 9);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (194, '2020-04-09 14:13:03.64907', 'Піпетка Пастера 1 мл стерильна (поліетилен)', 3, 9);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (195, '2020-04-09 14:13:14.392996', 'Азур-Еозин по Романовському (розчин, чда)', 3, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (196, '2020-04-09 14:46:46.857086', 'Скляний бюкс 35*70 мм', 3, 9);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (197, '2020-04-09 14:52:22.816605', 'Свинець оцтовокислий', 3, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (198, '2020-04-09 14:53:30.079908', 'Калій залізосинєродистий (червона кровяна сіль)', 3, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (199, '2020-04-09 14:57:51.610883', 'Барбітурова кислота', 3, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (200, '2020-04-09 15:12:52.664766', 'Скляний бюкс ТС 25*40 мм', 3, 9);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (201, '2020-04-09 15:13:07.552699', 'Скляний бюкс ТС 30*50 мм', 3, 9);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (202, '2020-04-09 15:17:50.23803', 'Сахароза', 3, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (203, '2020-04-09 15:18:10.646736', 'Крохмаль водорозчинний', 3, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (204, '2020-04-09 15:18:39.790954', 'L-пролін', 3, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (205, '2020-04-09 15:18:52.189436', 'р-Толуїдин', 3, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (206, '2020-04-09 15:19:06.945606', 'Камера хроматографіна 10*10 см', 3, 9);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (207, '2020-04-09 15:20:02.463922', 'Калію хлорид', 3, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (208, '2020-04-09 15:21:10.661681', 'Накінечник для дозаторів на 200 мкл з фільтром', 3, 9);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (209, '2020-04-09 15:35:59.784094', 'Етиленгліколь', 3, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (210, '2020-04-09 15:44:22.280739', 'Натрій оцтовокислий 3-водн.', 3, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (211, '2020-04-09 15:47:53.458324', '2,4-динітрофенол', 3, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (212, '2020-04-09 15:59:12.201136', 'Етилацетат для хроматографії', 3, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (213, '2020-04-09 16:28:26.836657', 'Бутилацетат (марка А)', 3, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (214, '2020-04-09 16:28:38.19252', 'Бутилацетат', 3, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (53, '2020-01-02 15:39:01.529732', 'Петролейний ефір (40-65)', 3, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (215, '2020-04-09 17:04:02.905419', 'Петролейний ефір (80-110)', 3, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (216, '2020-04-10 09:26:05.328257', 'Сульфатна кислота концентрована МЕРК', 3, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (217, '2020-04-10 09:27:05.769414', 'Дифеніламін Мерк', 3, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (218, '2020-04-10 09:27:21.080255', 'Балон для піпеток з трьома клапанами та перехідником', 3, 9);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (219, '2020-04-10 09:27:34.389864', 'Буферний розчин рН-4,01', 3, 9);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (221, '2020-04-10 09:28:07.900171', 'Йоршик для пробірок 20-25 мм', 3, 9);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (222, '2020-04-10 09:28:15.966537', 'Йоршик для пробірок 15 мм', 3, 9);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (224, '2020-04-10 09:33:58.051931', 'Октан', 3, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (225, '2020-04-10 09:35:58.547571', 'Калій бромистий', 3, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (226, '2020-04-10 10:09:10.230599', 'Накінечник для дозаторів на 200 мкл жовтий', 3, 9);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (227, '2020-04-10 10:57:34.195357', 'Мікропробірка Еппендорфа 1,5 мл', 3, 9);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (220, '2020-04-10 09:27:50.112313', 'Мікропробірка Епендорфа 0,5 мл', 3, 9);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (228, '2020-04-10 10:58:17.860513', 'Мікропробірка Амед 2,0 мл', 3, 9);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (229, '2020-04-10 10:58:36.326367', 'Скло покривне 18*18 мм', 3, 9);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (230, '2020-04-10 10:58:46.536301', 'Стакан високий з носиком і градуюванням В-1-50 ТС', 3, 9);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (231, '2020-04-10 10:58:57.092576', 'Ексикатор скляний без крану діаметром 240 мм', 3, 9);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (232, '2020-04-10 10:59:09.74763', 'Стакан високий з носиком і градуюванням В-1-500 ТС', 3, 9);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (233, '2020-04-10 10:59:18.279786', 'Затискач Мора 50 мм (металевий)', 3, 9);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (234, '2020-04-10 10:59:45.790335', 'Чашка випарювальна порцелянова 100 мл', 3, 9);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (235, '2020-04-10 10:59:52.179173', 'Чашка випарювальна порцелянова 50 мл', 3, 9);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (236, '2020-04-10 11:00:08.800507', 'Чашка випарювальна порцелянова 35 мл', 3, 9);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (237, '2020-04-10 11:00:17.100233', 'Чашка випарювальна порцелянова 25 мл', 3, 9);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (238, '2020-04-10 11:00:34.110825', 'КалійНатрій виннокислий', 3, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (239, '2020-04-10 11:01:07.710927', 'Малахітовий зелений', 3, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (240, '2020-04-10 11:01:18.976689', 'Калій роданистий', 3, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (241, '2020-04-10 11:01:33.632249', 'Алюмінію окис (б/в)', 3, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (242, '2020-04-10 11:01:43.776577', 'Глюкоза', 3, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (243, '2020-04-10 11:02:02.709261', 'Метилетилкетон', 3, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (244, '2020-04-10 11:02:10.998929', 'Хромотропової кислоти динатрієва сіль', 3, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (245, '2020-04-10 11:02:18.854128', 'Каплевловлювач КО-14/23-100 ТС', 3, 9);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (246, '2020-04-10 11:04:07.538708', 'Папір фільтрувальний', 3, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (247, '2020-04-10 11:28:47.328486', 'Фільтри лабораторні знезолені стрічка синя діаметром 110 мм', 3, 9);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (248, '2020-04-10 12:05:29.164264', 'Циліндр мірний 1-100-2', 3, 9);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (249, '2020-04-10 12:12:15.415278', 'Колба мірна КМ-1-25-2 ХС', 3, 9);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (250, '2020-04-10 12:20:45.695631', 'Піпетка мірна з градуювавнням 2-2-2-1 мл (повний злив)', 3, 9);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (251, '2020-04-10 12:28:13.800152', 'Циліндр мірний 1-250-2', 3, 9);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (252, '2020-04-10 14:15:01.262026', 'Цинк хлорид', 3, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (253, '2020-04-10 14:18:39.291098', 'Анілін', 3, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (254, '2020-04-10 14:26:08.116848', 'Ацетонітрил для хроматографії', 3, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (255, '2020-04-10 14:27:20.415585', 'Дихлорметан для хроматографії', 3, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (256, '2020-04-10 14:35:38.301785', 'Амоній роданистий', 3, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (257, '2020-04-10 14:36:03.610512', 'Бензидин гідрохлорид', 3, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (258, '2020-04-10 14:54:12.110034', 'Бромтимоловий синій (водорозчинний)', 3, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (259, '2020-04-10 14:54:37.196764', 'Калій вуглекислий (б/в)', 3, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (260, '2020-04-10 15:10:36.096905', 'Гідразин солянокислий', 3, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (261, '2020-04-10 15:18:53.049626', 'Винна кислота', 3, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (262, '2020-04-10 15:20:47.256281', 'Фільтри лабораторні знезолені стрічка синя діаметром 150 мм', 3, 9);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (263, '2020-04-10 15:36:09.198999', 'Бензидин', 3, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (264, '2020-04-10 15:50:40.141042', 'Калій хлорат (бертолетова сіль)', 3, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (265, '2020-04-10 16:07:34.189621', 'Скляний бюкс ТС 50*30 мм', 3, 9);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (266, '2020-04-10 16:10:29.549645', 'Септа для 9 мм кришок, що загвинчуються', 3, 9);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (267, '2020-04-14 15:29:54.289746', 'Піпетка мірна з градуювавнням 2-2-2-0,2 мл (повний злив)', 3, 9);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (268, '2020-04-14 15:31:46.97469', 'Піпетка мірна (Мора) з однією міткою 2-2-1 мл', 3, 9);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (269, '2020-04-14 15:31:57.185954', 'Піпетка мірна (Мора) з однією міткою 2-2-10 мл', 3, 9);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (270, '2020-04-14 16:31:53.504347', 'Тигель порцеляновий низький з кришкою на 50 мл', 3, 9);


--
-- Data for Name: reagent_state; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO "public"."reagent_state" ("id", "name", "position") VALUES (0, '--', 0);
INSERT INTO "public"."reagent_state" ("id", "name", "position") VALUES (1, 'Рідка', 0);
INSERT INTO "public"."reagent_state" ("id", "name", "position") VALUES (2, 'Тверда', 0);
INSERT INTO "public"."reagent_state" ("id", "name", "position") VALUES (4, 'Розхідний матеріал', 0);


--
-- Data for Name: region; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO "public"."region" ("id", "ts", "name", "position") VALUES (0, '2019-12-28 11:09:22.894212', '--', 0);
INSERT INTO "public"."region" ("id", "ts", "name", "position") VALUES (1, '2019-12-29 23:22:02.645034', 'Черкаська область', 0);


--
-- Data for Name: stock; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (27, '2020-04-07 14:07:20.605885', 101, 2, '2016-04-01', 3, 1, 2, 1, '2015-01-20', '2025-01-20', 1, '', 4, 6, 1, '', 'лабораторія 317', 'В сухому захищеному від пошкодження місці', '2020-04-07 14:07:20.605885', '8-2016', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0011571', '2016-04-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (31, '2020-04-07 14:33:38.395216', 106, 2, '2016-04-01', 3, 1, 2, 1, '2015-01-20', '2025-01-20', 0, '', 4, 6, 1, '', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-07 14:33:38.395216', '12-2016', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0011571', '2016-04-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (23, '2020-04-07 12:04:39.369609', 100, 9000, '2016-03-28', 3, 1, 9000, 8, '2015-04-01', '2018-04-01', 1, '', 1, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-07 12:04:39.369609', '4-2016', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№ 495', '2016-03-28');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (25, '2020-04-07 12:11:47.104727', 51, 6000, '2016-03-28', 3, 1, 6000, 7, '2015-09-01', '2016-09-01', 1, '', 1, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-07 12:11:47.104727', '6-2016', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№ 495', '2016-03-28');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (28, '2020-04-07 14:23:56.09256', 103, 12, '2016-04-01', 3, 1, 12, 1, '2015-01-20', '2025-01-20', 0, '', 4, 6, 1, '', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-07 14:23:56.09256', '9-2016', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0011571', '2016-04-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (21, '2020-04-07 11:28:26.356087', 99, 4000, '2016-03-14', 3, 1, 4000, 8, '2016-03-01', '2018-03-01', 1, '', 1, 5, 1, 'розчин (4 пляшок)', 'Лабораторія 317, Шафа для реактивів в к.318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-07 11:28:26.356087', '2-2016', 'Сфера СІМ', 'РН-01884', '2016-03-14');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (0, '2020-01-02 15:37:14.580544', 0, 0, '2020-01-01', 0, 0, 0, 0, '1970-01-01', '1970-01-01', 0, '', 0, 0, 0, '', '', '', '2020-03-12 09:48:19.879959', '0-0', '', '', '1970-01-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (22, '2020-04-07 11:59:02.539443', 50, 2000, '2016-03-28', 3, 1, 2000, 1, '2015-09-01', '2017-09-01', 1, '', 1, 5, 1, 'Прозора рідина в 4 пляшках (по 1.0 л)', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-07 11:59:02.539443', '3-2016', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№495', '2016-03-28');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (30, '2020-04-07 14:31:42.401235', 105, 2, '2016-04-01', 3, 1, 2, 1, '2015-01-20', '2025-01-20', 0, '', 4, 6, 1, '', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-07 14:31:42.401235', '11-2016', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0011571', '2016-04-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (32, '2020-04-07 14:35:13.246786', 109, 4, '2016-04-01', 3, 1, 4, 1, '2015-01-20', '2025-01-20', 0, '', 4, 6, 1, '', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-07 14:35:13.246786', '13-2016', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0011571', '2016-04-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (24, '2020-04-07 12:09:34.710777', 5, 2000, '2016-03-28', 3, 1, 2000, 9, '2016-02-01', '2018-10-31', 0, '', 1, 5, 1, '(МЕРК) 65%', 'лабораторія 317', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-07 12:09:34.710777', '5-2016', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№ 495', '2016-03-28');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (33, '2020-04-07 14:36:49.84224', 112, 2, '2016-04-01', 3, 1, 2, 1, '2015-01-20', '2025-01-20', 0, '', 4, 6, 1, '', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-07 14:36:49.84224', '14-2016', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0011571', '2016-04-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (34, '2020-04-07 14:38:30.448822', 114, 3, '2016-04-01', 3, 1, 3, 1, '2015-01-20', '2025-01-20', 0, '', 4, 6, 1, '', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-07 14:38:30.448822', '15-2016', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0011571', '2016-04-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (35, '2020-04-07 14:46:40.87389', 117, 1, '2016-04-01', 3, 1, 1, 1, '2015-01-20', '2025-01-20', 0, '', 4, 6, 1, '', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-07 14:46:40.87389', '16-2016', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0011571', '2016-04-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (36, '2020-04-07 14:48:21.145929', 118, 2, '2016-04-01', 3, 1, 2, 1, '2015-01-20', '2025-01-20', 0, '', 4, 6, 1, '', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-07 14:48:21.145929', '17-2016', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0011571', '2016-04-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (37, '2020-04-07 14:49:24.131686', 119, 2, '2016-04-01', 3, 1, 2, 1, '2015-01-20', '2025-01-20', 0, '', 4, 6, 1, '', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-07 14:49:24.131686', '18-2016', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0011571', '2016-04-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (38, '2020-04-07 14:50:34.217215', 120, 4, '2016-04-01', 3, 1, 4, 1, '2015-01-20', '2025-01-20', 0, '', 4, 6, 1, '', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-07 14:50:34.217215', '19-2016', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0011571', '2016-04-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (29, '2020-04-07 14:26:14.451686', 104, 10, '2016-04-01', 3, 1, 10, 1, '2015-01-20', '2025-01-20', 0, '', 4, 6, 1, '', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-07 14:26:14.451686', '10-2016', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0011571', '2016-04-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (26, '2020-04-07 12:26:10.400873', 57, 2500, '2016-03-31', 3, 1, 2500, 9, '2016-02-15', '2018-09-30', 0, '', 1, 5, 1, '(МЕРК) 95-97%', 'лабораторія 317', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-07 12:26:10.400873', '7-2016', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0012078', '2016-03-31');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (46, '2020-04-07 15:28:04.956658', 129, 500, '2016-04-04', 3, 1, 500, 7, '2015-12-01', '2016-12-01', 1, '', 2, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-07 15:28:04.956658', '27-2016', 'Сфера СІМ', '№РН-04122', '2016-04-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (49, '2020-04-07 15:39:45.131441', 131, 9000, '2016-04-04', 3, 1, 9000, 8, '2016-01-01', '2019-01-01', 1, '', 2, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-07 15:39:45.131441', '30-2016', 'Сфера СІМ', '№РН-04122', '2016-04-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (50, '2020-04-07 15:41:00.972129', 132, 1000, '2016-04-04', 3, 1, 1000, 8, '2015-12-01', '2016-12-01', 1, '', 2, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-07 15:41:00.972129', '31-2016', 'Сфера СІМ', '№РН-04122', '2016-04-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (40, '2020-04-07 14:54:01.629548', 123, 400, '2016-04-01', 3, 1, 400, 1, '2015-01-20', '2025-01-20', 0, '', 4, 6, 1, '', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-07 14:54:01.629548', '21-2016', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0011571', '2016-04-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (41, '2020-04-07 14:56:35.888848', 126, 2, '2016-04-01', 3, 1, 2, 1, '2015-01-20', '2025-01-20', 1, '', 4, 6, 1, '', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-07 14:56:35.888848', '22-2016', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0011571', '2016-04-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (42, '2020-04-07 14:57:38.185797', 127, 2, '2016-04-01', 3, 1, 2, 1, '2015-01-20', '2025-01-20', 1, '', 4, 6, 1, '', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-07 14:57:38.185797', '23-2016', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0011571', '2016-04-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (43, '2020-04-07 15:18:04.914966', 128, 100, '2016-04-04', 3, 1, 100, 7, '2016-03-01', '2019-03-01', 1, '', 2, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-07 15:18:04.914966', '24-2016', 'Сфера СІМ', '№РН-04122', '2016-04-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (44, '2020-04-07 15:20:18.031106', 8, 50, '2016-04-04', 3, 1, 50, 8, '2016-02-01', '2019-02-01', 1, '', 2, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-07 15:20:18.031106', '25-2016', 'Сфера СІМ', '№РН-04122', '2016-04-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (45, '2020-04-07 15:21:59.106707', 8, 200, '2016-04-04', 3, 1, 200, 7, '2016-03-01', '2018-03-01', 1, '', 2, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-07 15:21:59.106707', '26-2016', 'Сфера СІМ', '№РН-04122', '2016-04-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (47, '2020-04-07 15:29:40.540673', 19, 50, '2016-04-04', 3, 1, 50, 7, '2015-10-01', '2018-10-01', 1, '', 2, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-07 15:29:40.540673', '28-2016', 'Сфера СІМ', '№РН-04122', '2016-04-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (51, '2020-04-07 15:44:51.983584', 133, 20, '2016-04-04', 3, 1, 20, 7, '2015-11-01', '2018-11-01', 1, '', 2, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-07 15:44:51.983584', '32-2016', 'Сфера СІМ', '№РН-04122', '2016-04-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (52, '2020-04-07 15:47:17.675812', 134, 400, '2016-04-04', 3, 1, 400, 7, '2016-03-01', '2017-03-01', 1, '', 2, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-07 15:47:17.675812', '33-2016', 'Сфера СІМ', '№РН-04122', '2016-04-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (53, '2020-04-07 15:48:32.483153', 135, 100, '2016-04-04', 3, 1, 100, 7, '2016-01-01', '2019-01-01', 1, '', 2, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-07 15:48:32.483153', '34-2016', 'Сфера СІМ', '№РН-04122', '2016-04-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (54, '2020-04-07 15:54:12.79237', 136, 800, '2016-04-04', 3, 1, 800, 7, '2016-03-01', '2018-03-01', 1, '', 2, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-07 15:54:12.79237', '35-2016', 'Сфера СІМ', '№РН-04122', '2016-04-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (55, '2020-04-07 15:57:11.749814', 138, 100, '2016-04-04', 3, 1, 100, 7, '2016-03-01', '2018-03-01', 1, '', 2, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-07 15:57:11.749814', '36-2016', 'Сфера СІМ', '№РН-04122', '2016-04-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (56, '2020-04-07 16:07:23.074711', 139, 100, '2016-04-04', 3, 1, 100, 7, '2016-03-01', '2019-03-01', 1, '', 2, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-07 16:07:23.074711', '37-2016', 'Сфера СІМ', '№РН-04122', '2016-04-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (57, '2020-04-07 16:12:16.19492', 143, 50, '2016-04-04', 3, 1, 50, 7, '2016-03-01', '2019-03-01', 1, '', 2, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-07 16:12:16.19492', '38-2016', 'Сфера СІМ', '№РН-04122', '2016-04-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (39, '2020-04-07 14:51:41.236859', 121, 4, '2016-04-01', 3, 1, 4, 1, '2015-01-20', '2025-01-20', 0, '', 4, 6, 1, '', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-07 14:51:41.236859', '20-2016', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0011571', '2016-04-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (58, '2020-04-07 16:17:15.625372', 144, 50, '2016-04-04', 3, 1, 50, 7, '2016-03-01', '2018-03-01', 1, '', 2, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-07 16:17:15.625372', '39-2016', 'Сфера СІМ', '№РН-04122', '2016-04-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (59, '2020-04-07 16:19:23.107373', 56, 500, '2016-04-04', 3, 1, 500, 7, '2016-02-01', '2018-02-01', 1, '', 2, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-07 16:19:23.107373', '40-2016', 'Сфера СІМ', '№РН-04122', '2016-04-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (60, '2020-04-07 16:40:08.546274', 145, 5, '2016-04-04', 3, 1, 5, 2, '2015-05-01', '2022-05-01', 1, '', 2, 5, 1, '', 'лабораторія к. 317', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-07 16:40:08.546274', '41-2016', 'Сфера СІМ', '№РН-04122', '2016-04-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (61, '2020-04-07 16:41:31.199469', 146, 5, '2016-04-04', 3, 1, 5, 2, '2015-09-01', '2016-09-01', 1, '', 2, 5, 1, '', 'лабораторія к. 317', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-07 16:41:31.199469', '42-2016', 'Сфера СІМ', '№РН-04122', '2016-04-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (62, '2020-04-07 16:42:33.495558', 147, 5, '2016-04-04', 3, 1, 5, 2, '2016-03-01', '2017-03-01', 1, '', 2, 5, 1, '', 'лабораторія к. 317', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-07 16:42:33.495558', '43-2016', 'Сфера СІМ', '№РН-04122', '2016-04-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (63, '2020-04-07 16:43:42.714447', 148, 5, '2016-04-04', 3, 1, 5, 2, '2016-02-01', '2023-02-01', 1, '', 1, 5, 1, '', 'лабораторія к. 317', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-07 16:43:42.714447', '44-2016', 'Сфера СІМ', '№РН-04122', '2016-04-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (64, '2020-04-07 16:44:51.556009', 149, 5, '2016-04-04', 3, 1, 5, 2, '2016-02-01', '2026-02-01', 1, '', 1, 5, 1, '', 'лабораторія к. 317', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-07 16:44:51.556009', '45-2016', 'Сфера СІМ', '№РН-04122', '2016-04-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (65, '2020-04-07 16:50:04.572352', 150, 100, '2016-04-04', 3, 1, 100, 7, '2016-03-01', '2017-03-01', 1, '', 2, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-07 16:50:04.572352', '46-2016', 'Сфера СІМ', '№РН-04122', '2016-04-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (66, '2020-04-07 16:56:29.852527', 151, 1000, '2016-04-06', 3, 1, 1000, 8, '2016-03-01', '2017-03-01', 1, '', 2, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-07 16:56:29.852527', '47-2016', 'Сфера СІМ', '№РН-04444', '2016-04-06');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (67, '2020-04-07 16:58:06.335822', 152, 4000, '2016-04-06', 3, 1, 4000, 11, '2016-01-01', '2020-01-01', 1, '', 2, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-07 16:58:06.335822', '48-2016', 'Сфера СІМ', '№РН-04444', '2016-04-06');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (68, '2020-04-07 17:01:17.793885', 61, 4000, '2016-04-06', 3, 1, 4000, 2, '2016-03-01', '2017-03-01', 1, '', 2, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-07 17:01:17.793885', '49-2016', 'Сфера СІМ', '№РН-04444', '2016-04-06');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (69, '2020-04-07 17:06:43.400915', 27, 1000, '2016-04-06', 3, 1, 1000, 11, '2016-03-01', '2021-03-01', 1, '', 2, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-07 17:06:43.400915', '50-2016', 'Сфера СІМ', '№РН-04444', '2016-04-06');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (70, '2020-04-07 17:09:40.238525', 153, 10, '2016-04-06', 3, 1, 10, 7, '2015-07-01', '2018-07-01', 1, '', 2, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-07 17:09:40.238525', '51-2016', 'Сфера СІМ', '№РН-04444', '2016-04-06');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (71, '2020-04-07 17:18:25.755861', 154, 10, '2016-04-06', 3, 1, 10, 7, '2015-12-01', '2018-12-01', 1, '', 2, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-07 17:18:25.755861', '52-2016', 'Сфера СІМ', '№РН-04444', '2016-04-06');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (72, '2020-04-07 17:19:57.81801', 46, 100, '2016-04-06', 3, 1, 100, 7, '2015-12-01', '2018-12-01', 1, '', 2, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-07 17:19:57.81801', '53-2016', 'Сфера СІМ', '№РН-04444', '2016-04-06');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (73, '2020-04-07 17:22:05.548014', 155, 2000, '2016-04-06', 3, 1, 2000, 11, '2015-06-01', '2017-06-01', 1, '', 1, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-07 17:22:05.548014', '54-2016', 'Сфера СІМ', '№РН-04444', '2016-04-06');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (75, '2020-04-07 17:31:32.500673', 157, 50, '2016-04-06', 3, 1, 50, 2, '2016-01-01', '2019-01-01', 1, '', 2, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-07 17:31:32.500673', '56-2016', 'Сфера СІМ', '№РН-04444', '2016-04-06');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (76, '2020-04-07 17:33:23.816878', 158, 100, '2016-04-06', 3, 1, 100, 2, '2016-02-01', '2019-02-01', 1, '', 2, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-07 17:33:23.816878', '57-2016', 'Сфера СІМ', '№РН-04444', '2016-04-06');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (77, '2020-04-07 17:35:05.37929', 159, 30, '2016-04-06', 3, 1, 30, 7, '2016-03-01', '2019-03-01', 1, '', 2, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-07 17:35:05.37929', '58-2016', 'Сфера СІМ', '№РН-04444', '2016-04-06');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (78, '2020-04-07 17:36:51.307268', 138, 100, '2016-04-06', 3, 1, 100, 7, '2016-03-01', '2018-03-01', 1, '', 2, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-07 17:36:51.307268', '59-2016', 'Сфера СІМ', '№РН-04444', '2016-04-06');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (79, '2020-04-07 17:40:08.209606', 56, 500, '2016-04-06', 3, 1, 500, 7, '2016-02-01', '2018-02-01', 1, '', 2, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-07 17:40:08.209606', '60-2016', 'Сфера СІМ', '№РН-04444', '2016-04-06');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (80, '2020-04-09 09:12:20.912667', 161, 2, '2016-04-01', 3, 1, 2, 1, '2015-01-20', '2025-01-20', 0, '', 4, 6, 1, '', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-09 09:12:20.912667', '61-2016', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0011571', '2016-04-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (97, '2020-04-09 13:33:25.422899', 162, 8, '2017-05-04', 3, 1, 8, 1, '2017-03-30', '2027-03-30', 0, '', 4, 6, 1, '', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-09 13:33:25.422899', '6-2017', 'Сфера СІМ', '№СФ-07280', '2017-05-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (98, '2020-04-09 13:35:09.507535', 180, 30, '2017-05-04', 3, 1, 30, 1, '2017-03-30', '2027-03-30', 0, '', 4, 6, 1, '', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-09 13:35:09.507535', '7-2017', 'Сфера СІМ', '№СФ-07280', '2017-05-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (99, '2020-04-09 13:35:39.705846', 181, 30, '2017-05-04', 3, 1, 30, 1, '2017-03-30', '2027-03-30', 0, '', 4, 6, 1, '', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-09 13:35:39.705846', '8-2017', 'Сфера СІМ', '№СФ-07280', '2017-05-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (100, '2020-04-09 13:36:10.337698', 182, 30, '2017-05-04', 3, 1, 30, 1, '2017-03-30', '2027-03-30', 0, '', 4, 6, 1, '', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-09 13:36:10.337698', '9-2017', 'Сфера СІМ', '№СФ-07280', '2017-05-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (101, '2020-04-09 13:36:50.180227', 183, 10, '2017-05-04', 3, 1, 10, 1, '2017-03-30', '2027-03-30', 0, '', 4, 6, 1, '', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-09 13:36:50.180227', '10-2017', 'Сфера СІМ', '№СФ-07280', '2017-05-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (102, '2020-04-09 13:39:13.696724', 184, 10, '2017-05-04', 3, 1, 10, 1, '2017-03-30', '2027-03-30', 0, '', 4, 6, 1, '', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-09 13:39:13.696724', '11-2017', 'Сфера СІМ', '№СФ-07280', '2017-05-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (103, '2020-04-09 13:39:52.361329', 185, 10, '2017-05-04', 3, 1, 10, 1, '2017-03-30', '2027-03-30', 0, '', 4, 6, 1, '', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-09 13:39:52.361329', '12-2017', 'Сфера СІМ', '№СФ-07280', '2017-05-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (82, '2020-04-09 09:13:54.975473', 163, 1, '2016-04-01', 3, 1, 1, 1, '2015-01-20', '2025-01-20', 1, '', 4, 6, 1, '', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-09 09:13:54.975473', '63-2016', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0011571', '2016-04-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (83, '2020-04-09 09:14:28.607363', 164, 2, '2016-04-01', 3, 1, 2, 1, '2015-01-20', '2025-01-20', 1, '', 4, 6, 1, '', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-09 09:14:28.607363', '64-2016', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0011571', '2016-04-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (84, '2020-04-09 09:21:17.325851', 165, 14000, '2016-07-14', 3, 1, 14000, 11, '2016-02-01', '2018-02-01', 1, '', 2, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-09 09:21:17.325851', '65-2016', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0029174', '2016-07-14');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (85, '2020-04-09 09:25:04.776397', 14, 2000, '2016-09-07', 3, 1, 2000, 7, '2016-08-01', '2019-08-01', 1, '', 1, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-09 09:25:04.776397', '66-2016', 'Сфера СІМ', '№РН-12870', '2016-09-07');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (86, '2020-04-09 09:27:43.18168', 166, 2, '2016-09-07', 3, 1, 2, 1, '2015-01-20', '2025-01-20', 0, '', 4, 6, 1, '', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-09 09:27:43.18168', '67-2016', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№РН-12861', '2016-09-07');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (87, '2020-04-09 09:28:59.523024', 21, 1000, '2016-09-09', 3, 1, 1000, 11, '2015-08-01', '2018-08-01', 0, '', 1, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-09 09:28:59.523024', '68-2016', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0039331', '2016-09-09');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (89, '2020-04-09 12:03:02.072428', 10, 2000, '2016-12-05', 3, 1, 2000, 7, '2016-07-01', '2019-07-01', 1, '', 1, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-09 12:03:02.072428', '70-2016', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0054476', '2016-12-05');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (90, '2020-04-09 12:15:19.488423', 167, 4, '2016-12-08', 3, 1, 4, 1, '2015-01-20', '2025-01-20', 0, '', 4, 6, 1, '', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-09 12:15:19.488423', '71-2016', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№426', '2016-12-08');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (91, '2020-04-09 12:18:20.290294', 178, 1000, '2016-12-05', 3, 1, 1000, 8, '2016-05-01', '2018-05-01', 1, '', 2, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-09 12:18:20.290294', '72-2016', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№РН-19294', '2016-12-05');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (92, '2020-04-09 13:22:07.52569', 58, 2000, '2017-05-01', 3, 1, 2000, 7, '2017-03-01', '2018-03-01', 1, '', 1, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-09 13:22:07.52569', '1-2017', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0018647', '2017-05-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (93, '2020-04-09 13:23:09.078762', 21, 2000, '2017-05-04', 3, 1, 2000, 11, '2017-03-01', '2020-03-01', 1, '', 1, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-09 13:23:09.078762', '2-2017', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0018647', '2017-05-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (94, '2020-04-09 13:24:25.230106', 57, 4000, '2017-05-04', 3, 1, 4000, 8, '2017-03-01', '2020-03-01', 1, '', 1, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-09 13:24:25.230106', '3-2017', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0018647', '2017-05-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (96, '2020-04-09 13:29:18.269615', 171, 2000, '2017-05-04', 3, 1, 2000, 1, '2017-03-30', '2027-03-30', 0, '', 4, 6, 1, '', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-09 13:29:18.269615', '5-2017', 'Сфера СІМ', '№СФ-07280', '2017-05-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (105, '2020-04-09 13:45:28.967249', 14, 1000, '2017-05-04', 3, 1, 1000, 7, '2016-11-01', '2018-11-01', 1, '', 1, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-09 13:45:28.967249', '14-2017', 'Сфера СІМ', '№СФ-07467', '2017-05-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (106, '2020-04-09 13:46:37.496588', 178, 1000, '2017-05-04', 3, 1, 1000, 7, '2017-01-01', '2018-01-02', 1, '', 2, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-09 13:46:37.496588', '15-2017', 'Сфера СІМ', '№СФ-07467', '2017-05-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (107, '2020-04-09 13:49:40.586847', 18, 2000, '2017-05-04', 3, 1, 2000, 11, '2017-04-01', '2019-04-01', 1, '', 1, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-09 13:49:40.586847', '16-2017', 'Сфера СІМ', '№СФ-07467', '2017-05-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (108, '2020-04-09 13:55:47.812069', 155, 2000, '2017-05-04', 3, 1, 2000, 11, '2017-01-01', '2019-01-02', 1, '', 1, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-09 13:55:47.812069', '17-2017', 'Сфера СІМ', '№СФ-07467', '2017-05-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (109, '2020-04-09 13:59:40.888994', 145, 5, '2017-05-04', 3, 1, 5, 7, '2014-04-01', '2021-04-01', 1, '', 2, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-09 13:59:40.888994', '18-2017', 'Сфера СІМ', '№СФ-07467', '2017-05-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (110, '2020-04-09 14:01:02.573613', 65, 1000, '2017-05-04', 3, 1, 1000, 7, '2016-01-01', '2018-01-02', 1, '', 1, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-09 14:01:02.573613', '19-2017', 'Сфера СІМ', '№Х0019816', '2017-05-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (112, '2020-04-09 14:07:00.577002', 189, 50, '2017-06-02', 3, 1, 50, 7, '2017-04-01', '2020-07-01', 0, '', 2, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-09 14:07:00.577002', '21-2017', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0024870', '2017-06-02');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (113, '2020-04-09 14:10:11.48926', 190, 500, '2017-06-02', 3, 1, 500, 1, '2017-03-30', '2027-03-30', 0, '', 4, 6, 1, '', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-09 14:10:11.48926', '22-2017', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0024870', '2017-06-02');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (114, '2020-04-09 14:14:45.797554', 126, 4, '2017-06-02', 3, 1, 4, 1, '2017-03-30', '2027-03-30', 0, '', 4, 6, 1, '', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-09 14:14:45.797554', '23-2017', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0024870', '2017-06-02');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (115, '2020-04-09 14:16:12.981853', 48, 400, '2017-09-25', 3, 1, 400, 7, '2017-01-25', '2018-01-25', 1, '', 2, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-09 14:16:12.981853', '24-2017', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0046369', '2017-09-25');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (116, '2020-04-09 14:21:51.286525', 20, 800, '2017-09-25', 3, 1, 800, 7, '2016-12-10', '2017-12-10', 1, '', 1, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-09 14:21:51.286525', '25-2017', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0046369', '2017-09-25');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (117, '2020-04-09 14:27:08.537654', 191, 300, '2017-10-27', 3, 1, 300, 1, '2017-03-30', '2027-03-30', 0, '', 4, 6, 1, '', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-09 14:27:08.537654', '26-2017', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0046369', '2017-10-27');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (118, '2020-04-09 14:28:54.542809', 58, 2000, '2017-11-30', 3, 1, 2000, 7, '2017-07-01', '2018-07-01', 1, '', 1, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-09 14:28:54.542809', '27-2017', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0076913', '2017-11-30');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (120, '2020-04-09 14:31:04.335791', 57, 12000, '2017-11-30', 3, 1, 12000, 8, '2017-11-01', '2019-11-01', 1, '', 1, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-09 14:31:04.335791', '29-2017', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0076913', '2017-11-30');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (121, '2020-04-09 14:32:04.778502', 63, 10000, '2017-11-30', 3, 1, 10000, 8, '2017-11-01', '2018-11-01', 1, '', 1, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-09 14:32:04.778502', '30-2017', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0076913', '2017-11-30');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (122, '2020-04-09 14:54:29.642096', 197, 1000, '2017-12-04', 3, 1, 1000, 7, '2017-05-01', '2018-05-01', 1, '', 2, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-09 14:54:29.642096', '31-2017', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0059681', '2017-12-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (123, '2020-04-09 14:55:27.472514', 178, 1000, '2017-12-04', 3, 1, 1000, 7, '2017-07-01', '2019-07-01', 1, '', 2, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-09 14:55:27.472514', '32-2017', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0059681', '2017-12-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (124, '2020-04-09 14:56:24.136342', 150, 200, '2017-12-04', 3, 1, 200, 8, '2016-12-01', '2019-12-01', 1, '', 2, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-09 14:56:24.136342', '33-2017', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0059681', '2017-12-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (125, '2020-04-09 14:58:29.173799', 199, 100, '2017-12-04', 3, 1, 100, 2, '2015-08-01', '2018-08-01', 1, '', 2, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-09 14:58:29.173799', '34-2017', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0059681', '2017-12-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (131, '2020-04-09 15:17:11.994251', 171, 3000, '2017-12-04', 3, 1, 3000, 1, '2017-03-30', '2027-03-30', 0, '', 4, 6, 1, '', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-09 15:17:11.994251', '40-2017', 'Сфера СІМ', '№РН-17697', '2017-12-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (133, '2020-04-09 15:30:32.931901', 188, 2000, '2017-12-04', 3, 1, 2000, 2, '2017-05-01', '2019-05-01', 1, '', 1, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-09 15:30:32.931901', '42-2017', 'Сфера СІМ', '№РН-17718', '2017-12-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (126, '2020-04-09 14:59:12.31648', 14, 1000, '2017-12-04', 3, 1, 1000, 7, '2017-09-01', '2019-09-01', 1, '', 2, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-09 14:59:12.31648', '35-2017', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0059681', '2017-12-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (127, '2020-04-09 14:59:50.069975', 36, 2000, '2017-12-04', 3, 1, 2000, 2, '2017-09-01', '2018-09-01', 1, '', 2, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-09 14:59:50.069975', '36-2017', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0059681', '2017-12-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (128, '2020-04-09 15:11:20.723332', 175, 3000, '2017-12-04', 3, 1, 3000, 9, '2017-03-24', '2020-03-31', 1, '', 1, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-09 15:11:20.723332', '37-2017', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0059681', '2017-12-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (129, '2020-04-09 15:14:27.568964', 200, 10, '2017-12-04', 3, 1, 10, 1, '2017-03-30', '2027-03-30', 0, '', 4, 6, 1, '', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-09 15:14:27.568964', '38-2017', 'Сфера СІМ', '№РН-17697', '2017-12-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (130, '2020-04-09 15:15:01.167613', 201, 10, '2017-12-04', 3, 1, 10, 1, '2017-03-30', '2027-03-30', 0, '', 4, 6, 1, '', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-09 15:15:01.167613', '39-2017', 'Сфера СІМ', '№РН-17697', '2017-12-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (132, '2020-04-09 15:21:31.747916', 208, 1500, '2017-12-04', 3, 1, 1500, 1, '2017-03-30', '2027-03-30', 0, '', 4, 6, 1, '', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-09 15:21:31.747916', '41-2017', 'Сфера СІМ', '№РН-17697', '2017-12-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (134, '2020-04-09 15:32:17.40475', 153, 120, '2017-12-04', 3, 1, 120, 7, '2017-11-01', '2018-11-01', 1, '', 2, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-09 15:32:17.40475', '43-2017', 'Сфера СІМ', '№РН-17718', '2017-12-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (136, '2020-04-09 15:36:54.946433', 209, 2000, '2017-12-04', 3, 1, 2000, 2, '2017-11-01', '2019-11-01', 1, '', 1, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-09 15:36:54.946433', '45-2017', 'Сфера СІМ', '№РН-17718', '2017-12-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (137, '2020-04-09 15:38:21.741368', 198, 3000, '2017-12-04', 3, 1, 3000, 2, '2017-05-01', '2019-05-01', 1, '', 2, 5, 1, '3 уп. з червоною порошкоподібною речовиною по 1.0 кг', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-09 15:38:21.741368', '46-2017', 'Сфера СІМ', '№РН-17718', '2017-12-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (138, '2020-04-09 15:41:28.566112', 202, 3000, '2017-12-04', 3, 1, 3000, 7, '2017-10-01', '2019-10-01', 1, '', 2, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-09 15:41:28.566112', '47-2017', 'Сфера СІМ', '№РН-17718', '2017-12-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (139, '2020-04-09 15:43:10.171664', 203, 3000, '2017-12-04', 3, 1, 3000, 7, '2017-07-01', '2020-07-01', 1, '', 2, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-09 15:43:10.171664', '48-2017', 'Сфера СІМ', '№РН-17718', '2017-12-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (140, '2020-04-09 15:45:37.386097', 210, 2000, '2017-12-04', 3, 1, 2000, 11, '2017-02-01', '2019-02-01', 1, '', 2, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-09 15:45:37.386097', '49-2017', 'Сфера СІМ', '№РН-17718', '2017-12-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (141, '2020-04-09 15:47:07.770281', 45, 2000, '2017-12-04', 3, 1, 2000, 7, '2017-11-01', '2019-11-01', 1, '', 2, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-09 15:47:07.770281', '50-2017', 'Сфера СІМ', '№РН-17718', '2017-12-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (142, '2020-04-09 15:48:36.721055', 211, 100, '2017-12-04', 3, 1, 100, 7, '2017-03-01', '2020-03-01', 1, '', 2, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-09 15:48:36.721055', '51-2017', 'Сфера СІМ', '№РН-17718', '2017-12-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (143, '2020-04-09 15:50:13.071858', 207, 1000, '2017-12-04', 3, 1, 1000, 8, '2017-04-01', '2020-04-01', 1, '', 2, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-09 15:50:13.071858', '52-2017', 'Сфера СІМ', '№РН-17718', '2017-12-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (144, '2020-04-09 15:52:14.343262', 204, 1000, '2017-12-04', 3, 1, 1000, 2, '2017-08-01', '2018-08-01', 1, '', 2, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-09 15:52:14.343262', '53-2017', 'Сфера СІМ', '№РН-17718', '2017-12-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (146, '2020-04-09 16:00:03.986051', 212, 10000, '2017-12-04', 3, 1, 10000, 9, '2017-09-04', '2020-09-30', 1, '', 1, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-09 16:00:03.986051', '55-2017', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0059686', '2017-12-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (147, '2020-04-09 16:29:32.199286', 213, 2000, '2018-06-04', 3, 1, 2000, 1, '2017-08-15', '2019-08-15', 1, '', 1, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-09 16:29:32.199286', '2-2018', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0023632', '2018-06-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (158, '2020-04-09 17:12:19.200525', 20, 4000, '2018-06-04', 3, 1, 4000, 7, '2018-02-28', '2019-02-28', 1, '', 1, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-09 17:12:19.200525', '13-2018', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0023632', '2018-06-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (159, '2020-04-09 17:17:06.884751', 48, 500, '2018-06-04', 3, 1, 500, 7, '2017-12-27', '2018-12-27', 1, '', 2, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-09 17:17:06.884751', '14-2018', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0023632', '2018-06-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (148, '2020-04-09 16:30:43.617861', 65, 2000, '2018-06-04', 3, 1, 2000, 7, '2017-10-10', '2019-10-10', 1, '', 1, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-09 16:30:43.617861', '3-2018', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0023632', '2018-06-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (149, '2020-04-09 16:54:50.876749', 99, 5000, '2018-06-04', 3, 1, 5000, 8, '2018-04-03', '2019-04-03', 1, '', 1, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-09 16:54:50.876749', '4-2018', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0023632', '2018-06-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (150, '2020-04-09 16:58:46.98614', 62, 4000, '2018-06-04', 3, 1, 4000, 1, '2018-04-04', '2018-10-19', 1, '', 1, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-09 16:58:46.98614', '5-2018', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0023632', '2018-06-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (151, '2020-04-09 17:00:24.480241', 7, 10000, '2018-06-04', 3, 1, 10000, 7, '2018-05-04', '2019-05-04', 1, '', 1, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-09 17:00:24.480241', '6-2018', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0023632', '2018-06-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (152, '2020-04-09 17:01:35.633607', 33, 1000, '2018-06-04', 3, 1, 1000, 1, '2018-03-08', '2020-03-08', 1, '', 1, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-09 17:01:35.633607', '7-2018', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0023632', '2018-06-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (153, '2020-04-09 17:04:49.524917', 53, 7000, '2018-06-04', 3, 1, 7000, 7, '2018-04-23', '2019-04-23', 1, '', 1, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-09 17:04:49.524917', '8-2018', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0023632', '2018-06-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (154, '2020-04-09 17:06:34.65202', 14, 5000, '2018-06-04', 3, 1, 5000, 7, '2018-01-18', '2020-01-18', 1, '', 1, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-09 17:06:34.65202', '9-2018', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0023632', '2018-06-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (155, '2020-04-09 17:08:27.123998', 64, 5000, '2018-06-04', 3, 1, 5000, 11, '2017-05-05', '2022-05-05', 1, '', 1, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-09 17:08:27.123998', '10-2018', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0023632', '2018-06-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (156, '2020-04-09 17:09:56.985965', 137, 1000, '2018-06-04', 3, 1, 1000, 7, '2017-08-09', '2020-08-08', 1, '', 2, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-09 17:09:56.985965', '11-2018', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0023632', '2018-06-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (160, '2020-04-10 09:34:45.981696', 224, 1000, '2018-06-04', 3, 1, 1000, 7, '2018-01-12', '2024-01-12', 1, '', 1, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 09:34:45.981696', '15-2018', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0023632', '2018-06-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (161, '2020-04-10 09:37:08.798268', 225, 100, '2018-06-04', 3, 1, 100, 7, '2017-03-16', '2022-03-31', 1, '', 2, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 09:37:08.798268', '16-2018', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0023632', '2018-06-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (162, '2020-04-10 09:39:01.215385', 217, 100, '2018-06-04', 3, 1, 100, 7, '2015-08-17', '2020-08-31', 1, '', 2, 5, 1, '', 'лабораторія к. 317', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 09:39:01.215385', '17-2018', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0023632', '2018-06-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (163, '2020-04-10 09:40:06.201022', 141, 2000, '2018-06-04', 3, 1, 2000, 11, '2018-05-02', '2018-11-02', 1, '', 1, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 09:40:06.201022', '18-2018', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0023632', '2018-06-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (164, '2020-04-10 09:40:45.099831', 142, 2000, '2018-06-04', 3, 1, 2000, 11, '2018-05-02', '2018-11-02', 1, '', 1, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 09:40:45.099831', '19-2018', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0023632', '2018-06-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (165, '2020-04-10 09:42:49.0516', 218, 3, '2018-06-04', 3, 1, 3, 1, '2018-04-11', '2028-04-11', 0, '', 4, 6, 1, '', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-10 09:42:49.0516', '20-2018', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0023632', '2018-06-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (166, '2020-04-10 09:48:01.281584', 119, 8, '2018-06-04', 3, 1, 8, 1, '2018-04-11', '2028-04-11', 0, '', 4, 6, 1, '', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-10 09:48:01.281584', '21-2018', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0023632', '2018-06-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (170, '2020-04-10 09:58:29.637276', 58, 2000, '2018-06-04', 3, 1, 2000, 7, '2018-04-25', '2019-04-25', 1, '', 1, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 09:58:29.637276', '25-2018', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0023783', '2018-06-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (171, '2020-04-10 09:59:49.71204', 10, 4000, '2018-06-19', 3, 1, 4000, 7, '2018-04-25', '2021-04-25', 1, '', 1, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 09:59:49.71204', '26-2018', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0026587', '2018-06-19');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (172, '2020-04-10 10:01:02.920973', 175, 3000, '2018-06-04', 3, 1, 3000, 9, '2018-03-28', '2021-03-31', 1, '', 1, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 10:01:02.920973', '27-2018', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0023632', '2018-06-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (173, '2020-04-10 10:10:06.748404', 226, 4000, '2018-06-04', 3, 1, 4000, 1, '2018-04-11', '2028-04-11', 0, '', 4, 6, 1, '', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-10 10:10:06.748404', '28-2018', 'Сфера СІМ', '№РН-07494', '2018-06-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (180, '2020-04-10 10:25:18.199639', 217, 100, '2018-06-05', 3, 1, 100, 7, '2018-05-01', '2019-05-01', 1, '', 2, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 10:25:18.199639', '35-2018', 'Сфера СІМ', '№РН-07496', '2018-06-05');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (181, '2020-04-10 10:26:36.919933', 33, 2000, '2018-06-05', 3, 1, 2000, 1, '2018-04-01', '2019-04-01', 1, '', 1, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 10:26:36.919933', '36-2018', 'Сфера СІМ', '№РН-07496', '2018-06-05');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (174, '2020-04-10 10:11:42.555496', 220, 2000, '2018-06-04', 3, 1, 2000, 1, '2018-04-11', '2028-04-11', 0, '', 4, 6, 1, '', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-10 10:11:42.555496', '29-2018', 'Сфера СІМ', '№РН-07494', '2018-06-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (175, '2020-04-10 10:12:54.496434', 221, 10, '2018-06-04', 3, 1, 10, 1, '2018-04-11', '2028-04-11', 0, '', 4, 6, 1, '', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-10 10:12:54.496434', '30-2018', 'Сфера СІМ', '№РН-07494', '2018-06-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (176, '2020-04-10 10:13:39.050138', 222, 10, '2018-06-04', 3, 1, 10, 1, '2018-04-11', '2028-04-11', 0, '', 4, 6, 1, '', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-10 10:13:39.050138', '31-2018', 'Сфера СІМ', '№РН-07494', '2018-06-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (177, '2020-04-10 10:20:51.085822', 175, 3000, '2018-06-05', 3, 1, 3000, 9, '2018-03-28', '2021-03-31', 1, '', 1, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 10:20:51.085822', '32-2018', 'Сфера СІМ', '№РН-07496', '2018-06-05');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (179, '2020-04-10 10:24:00.413844', 20, 4000, '2018-06-05', 3, 1, 4000, 7, '2018-03-28', '2019-03-28', 1, '', 1, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 10:24:00.413844', '34-2018', 'Сфера СІМ', '№РН-07496', '2018-06-05');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (182, '2020-04-10 10:33:02.56979', 62, 4000, '2018-06-05', 3, 1, 4000, 1, '2018-04-04', '2018-10-04', 1, '', 1, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 10:33:02.56979', '37-2018', 'Сфера СІМ', '№РН-07496', '2018-06-05');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (168, '2020-04-10 09:54:44.112937', 216, 2500, '2018-06-04', 3, 1, 2500, 9, '2017-12-19', '2022-12-19', 1, 'МЕРК', 1, 5, 1, '', 'лабораторія к. 317', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 09:54:44.112937', '23-2018', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0026585', '2018-06-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (169, '2020-04-10 09:57:28.018004', 21, 5000, '2018-06-08', 3, 1, 5000, 11, '2018-04-25', '2021-04-25', 1, '', 1, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 09:57:28.018004', '24-2018', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0025045', '2018-06-08');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (183, '2020-04-10 10:34:30.454895', 213, 1000, '2018-06-05', 3, 1, 1000, 1, '2018-02-02', '2020-02-02', 1, '', 1, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 10:34:30.454895', '38-2018', 'Сфера СІМ', '№РН-07496', '2018-06-05');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (184, '2020-04-10 10:35:39.829666', 65, 2000, '2018-06-05', 3, 1, 2000, 7, '2018-04-03', '2020-04-03', 1, '', 1, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 10:35:39.829666', '39-2018', 'Сфера СІМ', '№РН-07496', '2018-06-05');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (185, '2020-04-10 10:36:43.715801', 53, 8000, '2018-06-05', 3, 1, 8000, 7, '2018-04-19', '2019-04-19', 1, '', 1, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 10:36:43.715801', '40-2018', 'Сфера СІМ', '№РН-07496', '2018-06-05');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (186, '2020-04-10 10:37:43.65824', 215, 5000, '2018-06-05', 3, 1, 5000, 7, '2018-04-07', '2020-04-07', 1, '', 1, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 10:37:43.65824', '41-2018', 'Сфера СІМ', '№РН-07496', '2018-06-05');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (187, '2020-04-10 10:38:37.189325', 137, 1000, '2018-06-05', 3, 1, 1000, 7, '2018-05-04', '2021-05-04', 1, '', 2, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 10:38:37.189325', '42-2018', 'Сфера СІМ', '№РН-07496', '2018-06-05');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (188, '2020-04-10 10:40:10.485391', 27, 1000, '2018-06-05', 3, 1, 1000, 11, '2017-04-20', '2022-04-20', 1, '', 2, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 10:40:10.485391', '43-2018', 'Сфера СІМ', '№РН-07496', '2018-06-05');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (198, '2020-04-10 11:23:52.371074', 160, 500, '2019-07-01', 3, 1, 500, 1, '2019-04-03', '2029-04-03', 0, '', 4, 6, 1, '', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-10 11:23:52.371074', '3-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (201, '2020-04-10 11:32:53.440508', 228, 1000, '2019-07-01', 3, 1, 1000, 1, '2019-04-03', '2029-04-03', 0, '', 4, 6, 1, '2 упаковки (по 500 шт) з мікропробірками Амед на 2,0 мл', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-10 11:32:53.440508', '6-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (190, '2020-04-10 10:43:36.813298', 64, 6000, '2018-06-05', 3, 1, 6000, 11, '2018-04-05', '2022-04-05', 1, '', 1, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 10:43:36.813298', '45-2018', 'Сфера СІМ', '№РН-07496', '2018-06-05');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (191, '2020-04-10 10:44:33.867153', 14, 6000, '2018-06-05', 3, 1, 6000, 7, '2018-04-18', '2020-04-18', 1, '', 1, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 10:44:33.867153', '46-2018', 'Сфера СІМ', '№РН-07496', '2018-06-05');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (192, '2020-04-10 10:46:44.384985', 99, 9000, '2018-06-05', 3, 1, 9000, 8, '2018-05-03', '2021-05-03', 1, '', 1, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 10:46:44.384985', '47-2018', 'Сфера СІМ', '№РН-07496', '2018-06-05');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (193, '2020-04-10 10:48:15.747678', 33, 2000, '2018-06-05', 3, 1, 2000, 2, '2018-04-01', '2020-04-01', 1, '', 1, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 10:48:15.747678', '48-2018', 'Сфера СІМ', '№РН-07496', '2018-06-05');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (195, '2020-04-10 10:51:04.586354', 214, 2000, '2018-06-05', 3, 1, 2000, 8, '2018-02-02', '2020-02-02', 1, '', 1, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 10:51:04.586354', '50-2018', 'Сфера СІМ', '№РН-07496', '2018-06-05');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (196, '2020-04-10 10:52:30.393839', 165, 1000, '2018-08-21', 3, 1, 1000, 1, '2018-02-02', '2020-02-02', 1, '', 2, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 10:52:30.393839', '51-2018', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№18-309', '2018-08-21');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (197, '2020-04-10 11:22:42.91856', 246, 10000, '2019-07-01', 3, 1, 10000, 1, '2019-04-03', '2029-04-03', 0, '', 4, 6, 1, '10000 г це 400 листів фільтрувального паперу білого кольору', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-10 11:22:42.91856', '2-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (199, '2020-04-10 11:29:39.880289', 247, 1000, '2019-07-01', 3, 1, 1000, 1, '2019-04-03', '2029-04-03', 0, '', 4, 6, 1, '10 упаковок по 100 штук', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-10 11:29:39.880289', '4-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (200, '2020-04-10 11:32:11.553537', 227, 1000, '2019-07-01', 3, 1, 1000, 1, '2019-04-03', '2029-04-03', 0, '', 4, 6, 1, '2 упаковки (по 500 шт) з мікропробірками Еппендорф на 1,5 мл', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-10 11:32:11.553537', '5-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (202, '2020-04-10 11:34:53.092034', 226, 2000, '2019-07-01', 3, 1, 2000, 1, '2019-04-03', '2029-04-03', 0, '', 4, 6, 1, '2 упаковки (по 1000 шт) з жовтими накінечниками до піпет-дозатору на 10-200 мкл', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-10 11:34:53.092034', '7-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (203, '2020-04-10 11:37:06.230716', 112, 10, '2019-07-01', 3, 1, 10, 1, '2019-04-03', '2029-04-03', 0, '', 4, 6, 1, 'Скляні мірні циліндри місткістю по 10 мл (10 шт)', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-10 11:37:06.230716', '8-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (204, '2020-04-10 11:39:42.234948', 221, 10, '2019-07-01', 3, 1, 10, 1, '2019-04-03', '2029-04-03', 0, '', 4, 6, 1, 'йоржі для миття посуду 10 шт', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-10 11:39:42.234948', '9-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (205, '2020-04-10 11:40:40.880091', 123, 500, '2019-07-01', 3, 1, 500, 1, '2019-04-03', '2029-04-03', 0, '', 4, 6, 1, 'полімерні пробки до флаконів 1000 шт', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-10 11:40:40.880091', '10-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (206, '2020-04-10 11:42:00.144962', 127, 10, '2019-07-01', 3, 1, 10, 1, '2019-04-03', '2029-04-03', 0, '', 4, 6, 1, '10 скляних лабюораторних воронок', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-10 11:42:00.144962', '11-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (207, '2020-04-10 11:51:29.926029', 229, 2, '2019-07-01', 3, 1, 2, 1, '2019-04-03', '2029-04-03', 0, '', 4, 6, 1, '2 упаковок покривних скелець по 100 шт', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-10 11:51:29.926029', '12-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (208, '2020-04-10 11:56:35.91521', 230, 10, '2019-07-01', 3, 1, 10, 1, '2019-04-03', '2029-04-03', 0, '', 4, 6, 1, '10 скляних стаканів на 50 мл', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-10 11:56:35.91521', '13-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (210, '2020-04-10 12:02:34.591543', 231, 1, '2019-07-01', 3, 1, 1, 1, '2019-04-03', '2029-04-03', 0, '', 4, 6, 1, '', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-10 12:02:34.591543', '15-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (211, '2020-04-10 12:06:10.682859', 248, 10, '2019-07-01', 3, 1, 10, 1, '2019-04-03', '2029-04-03', 0, '', 4, 6, 1, 'Скляні мірні циліндри місткістю по 100 мл (10 шт)', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-10 12:06:10.682859', '16-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (212, '2020-04-10 12:08:46.655305', 120, 20, '2019-07-01', 3, 1, 20, 1, '2019-04-03', '2029-04-03', 1, '', 4, 6, 1, '20 скляних мірних колб на 100 мл', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-10 12:08:46.655305', '17-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (213, '2020-04-10 12:09:54.109029', 115, 3, '2019-07-01', 3, 1, 3, 1, '2019-04-03', '2029-04-03', 0, '', 4, 6, 1, '3 круглодонні скляні колби на 1000 мл', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-10 12:09:54.109029', '18-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (214, '2020-04-10 12:10:53.328858', 113, 10, '2019-07-01', 3, 1, 10, 1, '2019-04-03', '2029-04-03', 1, '', 4, 6, 1, 'Скляні мірні циліндри місткістю по 50 мл (10 шт)', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-10 12:10:53.328858', '19-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (215, '2020-04-10 12:13:10.901754', 249, 14, '2019-07-01', 3, 1, 14, 1, '2019-04-03', '2029-04-03', 1, '', 4, 6, 1, '14 скляних мірних колб на 25 мл', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-10 12:13:10.901754', '20-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (216, '2020-04-10 12:14:01.099473', 232, 5, '2019-07-01', 3, 1, 5, 1, '2019-04-03', '2029-04-03', 0, '', 4, 6, 1, '5 скляних стаканів на 500 мл', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-10 12:14:01.099473', '21-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (218, '2020-04-10 12:16:39.414931', 121, 18, '2019-07-01', 3, 1, 18, 1, '2019-04-03', '2029-04-03', 1, '', 4, 6, 1, '18 скляних мірних колб на 250 мл', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-10 12:16:39.414931', '23-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (219, '2020-04-10 12:17:26.891079', 233, 5, '2019-07-01', 3, 1, 5, 1, '2019-04-03', '2029-04-03', 0, '', 4, 6, 1, '5 металевих затискачів Мора', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-10 12:17:26.891079', '24-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (220, '2020-04-10 12:19:30.452341', 108, 20, '2019-07-01', 3, 1, 20, 1, '2019-04-03', '2029-04-03', 1, '', 4, 6, 1, '20 скляних піпеток на 25 мл', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-10 12:19:30.452341', '25-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (221, '2020-04-10 12:21:39.426452', 250, 19, '2019-07-01', 3, 1, 19, 1, '2019-04-03', '2029-04-03', 1, '', 4, 6, 1, '19 скляних піпеток на 1 мл', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-10 12:21:39.426452', '26-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (222, '2020-04-10 12:23:42.921085', 106, 20, '2019-07-01', 3, 1, 20, 1, '2019-04-03', '2029-04-03', 1, '', 4, 6, 1, '20 скляних піпеток на 5 мл', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-10 12:23:42.921085', '27-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (223, '2020-04-10 12:24:20.897095', 107, 20, '2019-07-01', 3, 1, 20, 1, '2019-04-03', '2029-04-03', 1, '', 4, 6, 1, '20 скляних піпеток на 10 мл', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-10 12:24:20.897095', '28-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (224, '2020-04-10 12:25:32.39411', 118, 5, '2019-07-01', 3, 1, 5, 1, '2019-04-03', '2029-04-03', 1, '', 4, 6, 1, '5 скляних мірних колб на 1000 мл', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-10 12:25:32.39411', '29-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (225, '2020-04-10 12:26:58.445804', 125, 10, '2019-07-01', 3, 1, 10, 1, '2019-04-03', '2029-04-03', 0, '', 4, 6, 1, '10 скляних стаканів на 100 мл', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-10 12:26:58.445804', '30-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (227, '2020-04-10 14:00:21.964335', 119, 5, '2019-07-01', 3, 1, 5, 1, '2019-04-03', '2029-04-03', 0, '', 4, 6, 1, '5 скляних мірних колб на 500 мл', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-10 14:00:21.964335', '32-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (226, '2020-04-10 12:28:45.386434', 251, 5, '2019-07-01', 3, 1, 4, 1, '2019-04-03', '2029-04-03', 0, '', 4, 6, 1, 'Скляні мірні циліндри місткістю по 250 мл (5 шт)', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-10 12:28:45.386434', '31-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (235, '2020-04-10 14:15:55.376142', 252, 250, '2019-07-01', 3, 1, 250, 9, '2019-02-04', '2021-02-28', 1, '', 2, 5, 1, 'пляшка з кристалічною речовиною масою 250 г', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 14:15:55.376142', '40-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (229, '2020-04-10 14:02:35.92522', 234, 10, '2019-07-01', 3, 1, 10, 1, '2019-04-03', '2029-04-03', 1, '', 4, 6, 1, '10 порцелянових чашок на 100 мл', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-10 14:02:35.92522', '34-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (230, '2020-04-10 14:03:09.568617', 235, 10, '2019-07-01', 3, 1, 10, 1, '2019-04-03', '2029-04-03', 1, '', 4, 6, 1, '10 порцелянових чашок на 50 мл', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-10 14:03:09.568617', '35-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (231, '2020-04-10 14:03:52.100986', 236, 5, '2019-07-01', 3, 1, 5, 1, '2019-04-03', '2029-04-03', 1, '', 4, 6, 1, '5 порцелянових чашок на 35 мл', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-10 14:03:52.100986', '36-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (232, '2020-04-10 14:05:31.028873', 237, 10, '2019-07-01', 3, 1, 10, 1, '2019-04-03', '2029-04-03', 1, '', 4, 6, 1, '10 порцелянових чашок на 25 мл', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-10 14:05:31.028873', '37-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (233, '2020-04-10 14:08:30.576456', 212, 4000, '2019-07-01', 3, 1, 4000, 9, '2019-01-14', '2022-01-31', 1, '', 1, 5, 1, '4 пляшок з прозорою безбарвною рідиною по 1 л', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 14:08:30.576456', '38-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (234, '2020-04-10 14:13:06.851175', 29, 10, '2019-07-01', 3, 1, 10, 9, '2019-01-14', '2020-01-14', 1, '', 1, 5, 1, 'пляшка з кристалічною речовиною масою 10 г', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 14:13:06.851175', '39-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (236, '2020-04-10 14:17:32.193619', 36, 1000, '2019-07-01', 3, 1, 1000, 2, '2018-06-08', '2020-06-08', 0, '', 1, 5, 1, 'пляшка з прозорою рідиною 1 л (1,2 кг)', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 14:17:32.193619', '41-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (237, '2020-04-10 14:19:57.252968', 253, 1000, '2019-07-01', 3, 1, 1000, 7, '2018-06-13', '2020-06-13', 0, '', 1, 5, 1, 'пляшка з прозорою рідиною 1 л (1 кг)', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 14:19:57.252968', '42-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (238, '2020-04-10 14:20:58.638797', 14, 2000, '2019-07-01', 3, 1, 2000, 7, '2019-04-03', '2021-04-03', 0, '', 1, 5, 1, '2 пляшки з прозорою рідиною по 1 л (по 0,9 кг)', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 14:20:58.638797', '43-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (239, '2020-04-10 14:29:30.551369', 141, 2000, '2019-07-01', 3, 1, 2000, 11, '2019-05-02', '2019-11-02', 0, '', 1, 5, 1, '2 пляшки з прозорою рідиною по 1 л (по 1,15 кг)', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 14:29:30.551369', '44-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (240, '2020-04-10 14:30:37.915592', 255, 7500, '2019-07-01', 3, 1, 7500, 9, '2019-02-06', '2022-02-06', 1, '', 1, 5, 1, '3 пляшки з прозорою рідиною по 2,5 л', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 14:30:37.915592', '45-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (242, '2020-04-10 14:33:49.727596', 238, 200, '2019-07-01', 3, 1, 200, 7, '2019-04-15', '2021-04-15', 1, '', 2, 5, 1, '2 пакети з кристалічною речовиною білого кольору по 0,1 кг', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 14:33:49.727596', '47-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (243, '2020-04-10 14:34:44.025202', 239, 25, '2019-07-01', 3, 1, 25, 7, '2017-12-21', '2021-12-21', 1, '', 2, 5, 1, '1 банка з кристалічною речовиною 0,025 кг', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 14:34:44.025202', '48-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (244, '2020-04-10 14:37:00.040792', 256, 100, '2019-07-01', 3, 1, 100, 2, '2019-02-13', '2020-02-13', 1, '', 2, 5, 1, '1 банка з кристалічною речовиною 0,100 кг', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 14:37:00.040792', '49-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (245, '2020-04-10 14:43:35.012862', 257, 10, '2019-07-01', 3, 1, 10, 7, '2019-04-04', '2020-04-04', 1, '', 2, 5, 1, '1 банка з кристалічною речовиною 0,010 кг', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 14:43:35.012862', '50-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (256, '2020-04-10 15:03:18.009671', 175, 6000, '2019-07-01', 3, 1, 6000, 9, '2018-03-28', '2024-01-31', 1, '', 1, 5, 1, '6 пляшок з прозорою рідиною по 1 л', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 15:03:18.009671', '61-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (247, '2020-04-10 14:47:26.702316', 134, 300, '2019-07-01', 3, 1, 300, 7, '2018-12-24', '2020-12-24', 1, '', 2, 5, 1, '3 пакети з кристалічною речовиною по 0,100 кг (Мідь сірчанокисла)', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 14:47:26.702316', '52-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (248, '2020-04-10 14:49:58.906276', 207, 100, '2019-07-01', 3, 1, 100, 8, '2019-03-28', '2020-03-28', 1, '', 2, 5, 1, '1 пакет з кристалічною речовиною 0,100 кг', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 14:49:58.906276', '53-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (249, '2020-04-10 14:51:15.114433', 39, 400, '2019-07-01', 3, 1, 400, 8, '2019-01-11', '2021-01-11', 1, '', 2, 5, 1, '4 банки з кристалічною речовиною по 0,100 кг', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 14:51:15.114433', '54-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (250, '2020-04-10 14:53:29.887537', 26, 300, '2019-07-01', 3, 1, 300, 11, '2018-09-25', '2020-09-25', 1, '', 2, 5, 1, '3 банки з кристалічною речовиною по 0,100 кг', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 14:53:29.887537', '55-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (251, '2020-04-10 14:55:39.004658', 258, 50, '2019-07-01', 3, 1, 50, 7, '2018-03-28', '2021-03-28', 1, '', 2, 5, 1, '1 банка з кристалічною речовиною 0,050 кг', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 14:55:39.004658', '56-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (252, '2020-04-10 14:57:21.310835', 259, 200, '2019-07-01', 3, 1, 200, 7, '2018-11-14', '2020-11-14', 1, '', 2, 5, 1, '2 пакети з кристалічною речовиною по 0,100 кг', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 14:57:21.310835', '57-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (253, '2020-04-10 14:58:29.186057', 241, 300, '2019-07-01', 3, 1, 300, 7, '2019-03-22', '2020-03-22', 1, '', 2, 5, 1, '3 пакети з кристалічною речовиною по 0,100 кг', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 14:58:29.186057', '58-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (254, '2020-04-10 15:00:23.781137', 50, 1000, '2019-07-01', 3, 1, 1000, 11, '2018-12-05', '2020-12-04', 0, '', 1, 5, 1, 'пляшка з прозорою рідиною 1 л (1,8 кг)', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 15:00:23.781137', '59-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (258, '2020-04-10 15:06:02.980852', 178, 1000, '2019-07-01', 3, 1, 1000, 7, '2019-03-29', '2022-03-29', 1, '', 2, 5, 1, '1 пакет з речовиною 1,000 кг', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 15:06:02.980852', '63-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (259, '2020-04-10 15:08:43.508399', 28, 100, '2019-07-01', 3, 1, 100, 11, '2019-03-28', '2021-03-28', 1, '', 2, 5, 1, '1 пакет з речовиною 0,100 кг', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 15:08:43.508399', '64-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (260, '2020-04-10 15:10:02.996369', 150, 100, '2019-07-01', 3, 1, 100, 8, '2018-12-25', '2019-12-25', 1, '', 2, 5, 1, '1 пакет з речовиною 0,100 кг', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 15:10:02.996369', '65-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (261, '2020-04-10 15:14:57.457556', 260, 200, '2019-07-01', 3, 1, 200, 7, '2019-02-18', '2020-02-18', 1, '', 2, 5, 1, '2 пакети з речовиною по 0,100 кг', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 15:14:57.457556', '66-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (262, '2020-04-10 15:16:02.032921', 136, 300, '2019-07-01', 3, 1, 300, 7, '2019-04-18', '2019-10-18', 1, '', 2, 5, 1, '3 пакети з порошкоподібною речовиною по 0,100 кг', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 15:16:02.032921', '67-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (263, '2020-04-10 15:17:48.728412', 8, 200, '2019-07-01', 3, 1, 200, 7, '2019-05-29', '2021-05-29', 1, '', 2, 5, 1, '2 пакети з порошкоподібною речовиною по 0,100 кг', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 15:17:48.728412', '68-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (257, '2020-04-10 15:04:48.216681', 242, 300, '2019-07-01', 3, 1, 300, 11, '2019-03-22', '2020-03-22', 1, '', 2, 5, 1, '3 пакетів з речовиною по 0,100 кг', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 15:04:48.216681', '62-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (265, '2020-04-10 15:21:54.566181', 159, 30, '2019-07-01', 3, 1, 30, 7, '2017-02-10', '2020-02-10', 1, '', 2, 5, 1, '1 банка з речовиною 0,030 кг', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 15:21:54.566181', '70-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (266, '2020-04-10 15:22:49.95371', 27, 200, '2019-07-01', 3, 1, 200, 11, '2018-11-01', '2023-10-30', 1, '', 2, 5, 1, '2 банки з речовиною по 0,100 кг', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 15:22:49.95371', '71-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (267, '2020-04-10 15:23:36.729835', 152, 10000, '2019-07-01', 3, 1, 10000, 11, '2018-06-10', '2020-06-10', 1, '', 2, 5, 1, '10 пакетів з білою речовиною по 1,000 кг', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 15:23:36.729835', '72-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (268, '2020-04-10 15:27:28.729871', 18, 5000, '2019-07-01', 3, 1, 5000, 11, '2019-03-20', '2020-03-20', 0, '', 1, 5, 1, '5 пляшок з прозорою рідиною по 1 л (по 1,26 кг)', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 15:27:28.729871', '73-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (269, '2020-04-10 15:28:36.160761', 243, 1000, '2019-07-01', 3, 1, 1000, 9, '2017-04-26', '2022-04-30', 1, '', 1, 5, 1, '1 пляшка з прозорою рідиною 1 л', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 15:28:36.160761', '74-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023257', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (270, '2020-04-10 15:30:19.267089', 10, 5000, '2019-07-01', 3, 1, 5000, 7, '2019-03-29', '2022-03-29', 1, '', 1, 5, 1, '5 пляшок з прозорою рідиною по 1 л (по 0,8 кг)', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 15:30:19.267089', '75-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023257', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (271, '2020-04-10 15:32:10.14039', 244, 200, '2019-07-01', 3, 1, 200, 7, '2018-11-16', '2021-11-16', 1, '', 2, 5, 1, '2 банки з кристалічною речовиною по 0,100 кг', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 15:32:10.14039', '76-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (272, '2020-04-10 15:33:08.87157', 262, 1000, '2019-07-01', 3, 1, 1000, 1, '2019-04-03', '2029-04-03', 1, '', 4, 6, 1, 'Фільтри лабораторні знезолені стрічка синя діаметром 150 мм 100 шт/уп', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-10 15:33:08.87157', '77-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (273, '2020-04-10 15:34:12.95766', 122, 20, '2019-07-01', 3, 1, 20, 1, '2019-04-03', '2029-04-03', 1, '', 4, 6, 1, '20 скляних мірних колб на 50 мл', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-10 15:34:12.95766', '78-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (274, '2020-04-10 15:35:13.832431', 245, 2, '2019-07-01', 3, 1, 2, 1, '2019-04-03', '2029-04-03', 1, '', 4, 6, 1, '2 скляних каплеуловлювача', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-10 15:35:13.832431', '79-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (275, '2020-04-10 15:37:04.084195', 263, 10, '2019-07-01', 3, 1, 10, 7, '2019-06-15', '2022-07-15', 1, '', 2, 5, 1, '1 банка з кристалічною речовиною 0,010 кг', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 15:37:04.084195', '80-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (276, '2020-04-10 15:38:00.937462', 129, 500, '2019-07-01', 3, 1, 500, 7, '2019-04-06', '2020-04-05', 1, '', 2, 5, 1, '5 банок з кристалічною речовиною по 0,100 кг', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 15:38:00.937462', '81-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (278, '2020-04-10 15:41:16.241666', 224, 2000, '2019-07-30', 3, 1, 2000, 7, '2018-01-12', '2024-01-12', 1, '', 1, 5, 1, '2 пляшки з рідиною по 1.0 л', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 15:41:16.241666', '83-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№ХМ000537', '2019-07-30');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (279, '2020-04-10 15:43:01.203513', 215, 10000, '2019-07-30', 3, 1, 10000, 7, '2018-10-15', '2020-10-15', 0, '', 1, 5, 1, '10 пляшок з рідиною по 0.7 кг (по 1.0 л)', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 15:43:01.203513', '84-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№ХМ000537', '2019-07-30');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (280, '2020-04-10 15:45:53.59556', 99, 7000, '2019-07-30', 3, 1, 7000, 8, '2019-04-04', '2020-04-04', 0, '', 1, 5, 1, '7 пляшок з рідиною по 0.6 кг (по 1.0 л)', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 15:45:53.59556', '85-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№ХМ000537', '2019-07-30');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (281, '2020-04-10 15:47:50.69122', 176, 7500, '2019-07-30', 3, 1, 7500, 7, '2017-09-28', '2020-09-30', 1, '', 1, 5, 1, '3 пляшки з рідиною по 2,5 л (7,5 л в загальному)', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 15:47:50.69122', '86-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№ХМ000537', '2019-07-30');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (299, '2020-04-13 10:02:56.639907', 193, 200, '2019-12-17', 3, 1, 200, 1, '2019-10-31', '2029-10-31', 1, '', 4, 6, 1, '2 упаковки з мікровіалами по 100 шт/уп', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-13 10:02:56.639907', '104-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х046154', '2019-12-17');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (311, '2020-04-13 12:16:59.931642', 192, 22400, '2020-02-24', 3, 1, 22400, 9, '2020-02-20', '2022-02-20', 0, '', 1, 5, 1, 'балони із стиснутим гелієм 4 шт по 5,6 л', 'лабораторія к. 317', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-13 12:16:59.931642', '1-2020', 'ТОВ "Кріогенсервіс"', '№3067', '2020-02-24');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (283, '2020-04-10 15:51:23.359012', 264, 100, '2019-09-18', 3, 1, 100, 7, '2017-11-08', '2022-11-30', 1, '', 2, 5, 1, '1 упаковка (банка з речовиною масою 100 г)', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 15:51:23.359012', '88-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х034463', '2019-09-18');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (284, '2020-04-10 15:52:54.977859', 176, 10000, '2019-12-18', 3, 1, 10000, 9, '2019-07-03', '2022-07-31', 1, '', 1, 5, 1, '4 пляшки з прозорою рідиною по 2,5 л', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 15:52:54.977859', '89-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х046208', '2019-12-18');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (286, '2020-04-10 15:54:54.227929', 63, 2000, '2019-12-18', 3, 1, 2000, 8, '2019-11-15', '2020-11-15', 1, '', 1, 5, 1, '2 пляшки з прозорою рідиною обємом по 1.0 л (по 1,2 кг)', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 15:54:54.227929', '91-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х046210', '2019-12-18');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (287, '2020-04-10 15:55:57.659911', 165, 1000, '2019-12-18', 3, 1, 1000, 11, '2018-05-25', '2021-05-25', 1, '', 2, 5, 1, '1 упаковка з кристалічною речовиною масою 1,0 кг', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 15:55:57.659911', '92-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х046210', '2019-12-18');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (288, '2020-04-10 15:57:17.390362', 136, 4000, '2019-12-17', 3, 1, 4000, 2, '2019-05-25', '2021-05-25', 1, '', 2, 5, 1, '4 упаковки з речовиною масою по 1,0 кг', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 15:57:17.390362', '93-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х046146', '2019-12-17');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (289, '2020-04-10 15:58:58.763756', 51, 1000, '2019-12-17', 3, 1, 1000, 2, '2019-03-18', '2021-03-17', 1, '', 1, 5, 1, '1 пляшка з рідиною обємом 1,0 л (1,0 кг)', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 15:58:58.763756', '94-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х046146', '2019-12-17');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (290, '2020-04-10 16:00:51.391712', 62, 2000, '2019-12-17', 3, 1, 2000, 2, '2019-10-04', '2020-04-04', 1, '', 1, 5, 1, '2 пляшка із суспензією обємом по 1,0 л (по 1,1 кг)', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 16:00:51.391712', '95-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х046146', '2019-12-17');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (291, '2020-04-10 16:02:34.667681', 172, 3500, '2019-12-17', 3, 1, 3500, 1, '2019-04-03', '2029-04-03', 1, '', 4, 6, 1, '7 упаковок із полімерними накінечниками блакитного кольору по 500 шт/уп', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-10 16:02:34.667681', '96-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х046154', '2019-12-17');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (292, '2020-04-10 16:04:03.47474', 174, 50, '2019-12-17', 3, 1, 50, 1, '2019-10-31', '2029-10-31', 1, '', 4, 6, 1, '2 упаковки алюмінієвих пластинок 25 шт/уп 20*20 см', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-10 16:04:03.47474', '97-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х046154', '2019-12-17');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (293, '2020-04-10 16:05:10.682918', 110, 4, '2019-12-17', 3, 1, 4, 1, '2019-10-31', '2029-10-31', 1, '', 4, 6, 1, '4 скляних конічних колб на 50 мл', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-10 16:05:10.682918', '98-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х046154', '2019-12-17');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (294, '2020-04-10 16:08:34.885618', 265, 8, '2019-12-17', 3, 1, 8, 1, '2019-10-31', '2029-10-31', 1, '', 4, 6, 1, '8 стаканчиків для зважування низьких 50*30 мм', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-10 16:08:34.885618', '99-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х046154', '2019-12-17');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (295, '2020-04-10 16:09:39.883567', 191, 800, '2019-12-17', 3, 1, 800, 1, '2019-10-31', '2029-10-31', 1, '', 4, 6, 1, '8 комплектів віал із кришками та септами 100 шт/уп', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-10 16:09:39.883567', '100-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х046154', '2019-12-17');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (296, '2020-04-10 16:10:57.957936', 266, 900, '2019-12-17', 3, 1, 900, 1, '2019-10-31', '2029-10-31', 1, '', 4, 6, 1, '9 упаковок септ для кришок по 100 шт/уп', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-10 16:10:57.957936', '101-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х046154', '2019-12-17');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (298, '2020-04-10 16:13:44.862052', 22, 25000, '2019-12-24', 3, 1, 25000, 11, '2019-11-02', '2024-12-02', 0, '', 1, 5, 1, '250 пляшок із прозорою рідиною по 100 мл', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 16:13:44.862052', '103-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х046153', '2019-12-24');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (157, '2020-04-09 17:11:11.693053', 27, 1000, '2018-06-04', 3, 1, 1000, 11, '2017-11-28', '2022-11-28', 1, '', 2, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-09 17:11:11.693053', '12-2018', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0023632', '2018-06-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (167, '2020-04-10 09:53:15.615834', 118, 3, '2018-06-04', 3, 1, 3, 1, '2018-04-11', '2028-04-11', 0, '', 4, 6, 1, '', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-10 09:53:15.615834', '22-2018', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0023632', '2018-06-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (178, '2020-04-10 10:22:09.907536', 34, 100, '2018-06-05', 3, 1, 100, 9, '2017-09-07', '2019-02-23', 1, '', 2, 5, 1, '', 'лабораторія к. 317', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 10:22:09.907536', '33-2018', 'Сфера СІМ', '№РН-07496', '2018-06-05');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (189, '2020-04-10 10:42:15.495545', 7, 10000, '2018-06-05', 3, 1, 10000, 7, '2018-04-04', '2019-04-04', 1, '', 1, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 10:42:15.495545', '44-2018', 'Сфера СІМ', '№РН-07496', '2018-06-05');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (194, '2020-04-10 10:49:32.989679', 64, 3000, '2018-06-05', 3, 1, 3000, 8, '2018-05-01', '2019-11-01', 1, '', 1, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 10:49:32.989679', '49-2018', 'Сфера СІМ', '№РН-07496', '2018-06-05');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (20, '2020-04-07 11:17:26.064597', 59, 10.8699999999999992, '2016-03-14', 3, 1, 10.8699999999999992, 2, '2016-03-01', '2019-03-01', 1, '', 2, 5, 1, 'Кристалічний порошок коричневого кольору', 'лабораторія 317', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-07 11:17:26.064597', '1-2016', 'Сфера СІМ', 'РН-01884', '2016-03-14');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (48, '2020-04-07 15:35:47.21042', 26, 2000, '2016-04-04', 3, 1, 2000, 8, '2016-03-01', '2019-03-01', 1, '', 2, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-07 15:35:47.21042', '29-2016', 'Сфера СІМ', '№РН-04122', '2016-04-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (74, '2020-04-07 17:25:50.892422', 156, 5000, '2016-04-06', 3, 1, 5000, 2, '2016-03-01', '2018-03-01', 1, '', 2, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-07 17:25:50.892422', '55-2016', 'Сфера СІМ', '№РН-04444', '2016-04-06');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (81, '2020-04-09 09:13:13.488743', 162, 2, '2016-04-01', 3, 1, 2, 1, '2015-01-20', '2025-01-20', 1, '', 4, 6, 1, '', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-09 09:13:13.488743', '62-2016', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0011571', '2016-04-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (88, '2020-04-09 12:02:17.507357', 58, 1000, '2016-12-05', 3, 1, 1000, 7, '2016-07-01', '2017-07-01', 1, '', 1, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-09 12:02:17.507357', '69-2016', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0054476', '2016-12-05');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (95, '2020-04-09 13:26:20.335194', 179, 2, '2017-05-04', 3, 1, 2, 1, '2017-03-30', '2027-03-30', 0, '', 4, 6, 1, '', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-09 13:26:20.335194', '4-2017', 'Сфера СІМ', '№СФ-07280', '2017-05-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (104, '2020-04-09 13:44:42.413488', 188, 2000, '2017-05-04', 3, 1, 2000, 2, '2016-08-01', '2018-08-01', 1, '', 1, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-09 13:44:42.413488', '13-2017', 'Сфера СІМ', '№СФ-07467', '2017-05-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (119, '2020-04-09 14:29:57.362008', 21, 2000, '2017-11-30', 3, 1, 2000, 11, '2017-03-01', '2020-03-01', 1, '', 1, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-09 14:29:57.362008', '28-2017', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0076913', '2017-11-30');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (135, '2020-04-09 15:35:03.374354', 62, 1000, '2017-12-04', 3, 1, 1000, 1, '2017-06-01', '2018-06-01', 1, '', 1, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-09 15:35:03.374354', '44-2017', 'Сфера СІМ', '№РН-17718', '2017-12-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (145, '2020-04-09 15:58:26.212358', 205, 500, '2017-12-04', 3, 1, 500, 2, '2017-01-06', '2019-01-06', 1, '', 2, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-09 15:58:26.212358', '54-2017', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0059686', '2017-12-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (209, '2020-04-10 12:01:48.493104', 105, 20, '2019-07-01', 3, 1, 20, 1, '2019-04-03', '2029-04-03', 1, '', 4, 6, 1, '', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-10 12:01:48.493104', '14-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (217, '2020-04-10 12:15:43.061559', 226, 1000, '2019-07-01', 3, 1, 1000, 1, '2019-04-03', '2029-04-03', 0, '', 4, 6, 1, '1 упаковка (1000 шт) з жовтими накінечниками до піпет-дозатору ЛЛГ на 1-200 мкл', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-10 12:15:43.061559', '22-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (228, '2020-04-10 14:01:40.483795', 124, 10, '2019-07-01', 3, 1, 10, 1, '2019-04-03', '2029-04-03', 0, '', 4, 6, 1, '10 скляних стаканів на 250 мл', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-10 14:01:40.483795', '33-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (313, '2020-04-13 12:35:19.555341', 224, 1000, '2020-03-23', 3, 1, 1000, 7, '2018-01-12', '2024-01-12', 1, 'CARLO ERBA REAGENTS', 1, 5, 1, '1 пляшка з прозорою рідиною на 1,0 л', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-13 12:35:19.555341', '3-2020', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№ЛР004772', '2020-03-23');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (241, '2020-04-10 14:32:16.077273', 254, 5000, '2019-07-01', 3, 1, 5000, 9, '2018-07-16', '2022-07-16', 1, '', 1, 5, 1, '2 пляшки з прозорою рідиною по 2,5 л', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 14:32:16.077273', '46-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (246, '2020-04-10 14:44:31.267066', 240, 100, '2019-07-01', 3, 1, 100, 2, '2019-05-02', '2020-05-02', 1, '', 2, 5, 1, '1 банка з кристалічною речовиною 0,100 кг', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 14:44:31.267066', '51-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (255, '2020-04-10 15:01:53.534497', 5, 1000, '2019-07-01', 3, 1, 1000, 9, '2019-02-15', '2024-01-31', 0, '', 1, 5, 1, 'пляшка з прозорою рідиною 1 л (1,4 кг)', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 15:01:53.534497', '60-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (264, '2020-04-10 15:19:42.301253', 261, 200, '2019-07-01', 3, 1, 200, 11, '2018-11-09', '2020-11-09', 1, '', 2, 5, 1, '2 пакети з порошкоподібною речовиною по 0,100 кг', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 15:19:42.301253', '69-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (277, '2020-04-10 15:39:59.543205', 59, 300, '2019-07-01', 3, 1, 300, 2, '2019-06-15', '2022-07-15', 1, '', 2, 5, 1, '3 банки з кристалічною речовиною по 0,100 кг', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 15:39:59.543205', '82-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (282, '2020-04-10 15:49:12.787177', 177, 2500, '2019-07-30', 3, 1, 2500, 7, '2019-01-30', '2022-01-31', 1, '', 1, 5, 1, 'пляшка з рідиною 2,5 л', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 15:49:12.787177', '87-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№ХМ000537', '2019-07-30');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (285, '2020-04-10 15:53:48.997732', 49, 3000, '2019-12-18', 3, 1, 3000, 1, '2019-11-08', '2021-11-08', 1, '', 1, 5, 1, '3 пляшки з прозорою рідиною обємом по 1.0 л (по 0,8 кг)', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 15:53:48.997732', '90-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х046208', '2019-12-18');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (312, '2020-04-13 12:33:37.491257', 32, 15000, '2020-03-19', 3, 1, 15000, 7, '2020-02-25', '2022-02-25', 0, 'Нідерланди', 1, 5, 1, '15 пляшок з прозорою рідиною по 1,0 л (0,8 кг)', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-13 12:33:37.491257', '2-2020', 'ТОВ "Кріогенсервіс"', '№ЛР004547', '2020-03-19');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (314, '2020-04-13 16:14:15.675947', 174, 50, '2020-03-17', 3, 1, 50, 2, '2019-09-27', '2029-09-30', 0, 'МЕРК', 4, 6, 1, '2 упаковки з пластинками по 25 шт/уп', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-13 16:14:15.675947', '4-2020', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№ЛР004276', '2020-03-17');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (315, '2020-04-13 16:15:24.950876', 174, 50, '2020-03-17', 3, 1, 50, 2, '2019-09-27', '2029-09-30', 0, 'МЕРК', 4, 6, 1, '2 упаковки (цілісність порушена) з пластинками по 25 шт/уп', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-13 16:15:24.950876', '5-2020', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№ЛР004276', '2020-03-17');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (316, '2020-04-13 16:17:22.667634', 58, 3000, '2020-03-19', 3, 1, 3000, 7, '2019-11-11', '2020-11-11', 1, 'ПП "ТЕХПРОМЗБУТ"', 1, 5, 1, '3 пляшки з прозорою рідиною по 1,0 л (0,8 кг)', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-13 16:17:22.667634', '6-2020', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№ЛР004596', '2020-03-19');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (317, '2020-04-13 16:18:46.575122', 165, 50, '2020-03-19', 3, 1, 50, 11, '2018-05-25', '2021-05-25', 1, 'Китай', 2, 5, 1, '1 банка із кристалічною фіолетовою речовиною 50 г', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-13 16:18:46.575122', '7-2020', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№ЛР004596', '2020-03-19');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (318, '2020-04-13 16:21:06.759135', 57, 20000, '2020-03-19', 3, 1, 20000, 7, '2019-12-20', '2022-12-20', 1, 'Україна', 1, 5, 1, '20 пляшок із вязкою рідиною по 1,0 л (1,8 кг)', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-13 16:21:06.759135', '8-2020', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№ЛР004596', '2020-03-19');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (319, '2020-04-13 16:24:02.529228', 10, 4000, '2020-03-19', 3, 1, 4000, 7, '2019-11-11', '2022-11-11', 1, 'ПП "ТЕХПРОМЗБУТ"', 1, 5, 1, '4 пляшки із прозорою рідиною по 1,0 л (0,8 кг)', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-13 16:24:02.529228', '9-2020', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№ЛР004625', '2020-03-19');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (320, '2020-04-13 16:25:51.880311', 63, 5000, '2020-03-19', 3, 1, 5000, 8, '2019-12-20', '2022-12-20', 1, 'Україна', 1, 5, 1, '5 пляшок із прозорою вязкою рідиною по 1,0 л (1,2 кг)', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-13 16:25:51.880311', '10-2020', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№ЛР004625', '2020-03-19');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (321, '2020-04-13 16:30:30.823183', 176, 12500, '2020-03-23', 3, 1, 12500, 9, '2019-08-16', '2022-08-31', 1, 'МЕРК', 1, 5, 1, '5 пляшок із прозорою рідиною по 2,5 л', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-13 16:30:30.823183', '11-2020', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№ЛР004801', '2020-03-23');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (322, '2020-04-13 16:32:00.608549', 177, 20000, '2020-03-23', 3, 1, 20000, 9, '2019-05-06', '2022-05-31', 1, 'МЕРК', 1, 5, 1, '8 пляшок із прозорою рідиною по 2,5 л', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-13 16:32:00.608549', '12-2020', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№ЛР004801', '2020-03-23');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (323, '2020-04-13 16:35:01.311583', 215, 5000, '2020-03-23', 3, 1, 5000, 7, '2019-08-14', '2021-08-14', 0, '', 1, 5, 1, '5 пляшок із прозорою рідиною по 1,0 л (по 0,7 кг)', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-13 16:35:01.311583', '13-2020', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№ЛР004801', '2020-03-23');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (324, '2020-04-13 17:01:23.411125', 99, 10000, '2020-03-23', 3, 1, 10000, 8, '2020-01-21', '2021-01-21', 0, 'Німеччина', 1, 5, 1, '10 пляшок із прозорою рідиною по 1,0 л (по 0,6 кг)', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-13 17:01:23.411125', '14-2020', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№ЛР004801', '2020-03-23');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (325, '2020-04-13 17:04:42.746402', 49, 5000, '2020-03-23', 3, 1, 5000, 1, '2020-01-28', '2022-01-28', 0, 'Словаччина', 1, 5, 1, '5 пляшок із прозорою рідиною по 1,0 л (по 0,8 кг)', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-13 17:04:42.746402', '15-2020', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№ЛР004801', '2020-03-23');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (326, '2020-04-13 17:07:17.928803', 188, 2000, '2020-03-23', 3, 1, 2000, 2, '2019-02-28', '2022-02-28', 0, 'Словаччина', 1, 5, 1, '2 пляшки із прозорою рідиною по 1,0 л (по 0,7 кг)', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-13 17:07:17.928803', '16-2020', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№ЛР004801', '2020-03-23');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (335, '2020-04-14 15:25:45.886656', 250, 8, '2020-03-17', 3, 1, 8, 1, '2019-09-27', '2029-09-30', 1, '', 4, 6, 1, '8 скляних мірних піпеток на 1 мл', 'шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-14 15:25:45.886656', '25-2020', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№ЛР004269', '2020-03-17');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (336, '2020-04-14 15:30:36.863897', 267, 8, '2020-03-17', 3, 1, 8, 1, '2019-09-27', '2029-09-30', 0, '', 4, 6, 1, '8 скляних мірних піпеток на 0,2 мл', 'шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-14 15:30:36.863897', '26-2020', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№ЛР004269', '2020-03-17');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (337, '2020-04-14 15:33:17.436513', 269, 8, '2020-03-17', 3, 1, 8, 1, '2019-09-27', '2029-09-30', 1, '', 4, 6, 1, '8 скляних піпеток Мора на 10 мл', 'шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-14 15:33:17.436513', '27-2020', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№ЛР004269', '2020-03-17');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (327, '2020-04-14 13:53:21.242947', 34, 5, '2020-03-17', 3, 1, 0, 9, '2017-08-01', '2023-07-31', 1, 'МЕРК', 2, 5, 1, '1 пляшка із кристалічною речовиною масою 5.0 г', 'лабораторія к. 317 (холодильник)', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-14 13:53:21.242947', '17-2020', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№ЛР004276', '2020-03-17');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (328, '2020-04-14 14:24:19.321386', 62, 2000, '2020-03-31', 3, 1, 2000, 1, '2020-03-09', '2020-09-09', 1, 'Україна', 1, 5, 1, '2 пляшки із суспензією білого кольору по 1,0 л (по 1,1 кг)', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-14 14:24:19.321386', '18-2020', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', 'в.н. №1', '2020-03-31');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (329, '2020-04-14 14:32:21.533185', 105, 8, '2020-03-31', 3, 1, 8, 1, '2019-09-27', '2029-09-30', 1, '', 4, 6, 1, '8 скляних піпеток мірних на 2 мл (повний злив)', 'шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-14 14:32:21.533185', '19-2020', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', 'в.н. №1', '2020-03-31');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (330, '2020-04-14 14:53:09.971626', 175, 10000, '2020-03-17', 3, 1, 10000, 9, '2020-01-23', '2023-01-31', 1, 'МЕРК', 1, 5, 1, '10 пляшок із прозорою рідиною по 1,0 л', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-14 14:53:09.971626', '20-2020', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№ЛР004269', '2020-03-17');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (331, '2020-04-14 15:11:20.414678', 172, 5000, '2020-03-17', 3, 1, 5000, 1, '2019-09-27', '2029-09-30', 1, '', 4, 6, 1, '10 упаковок із накінечниками до піпет-дозатора по 500 шт/уп', 'шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-14 15:11:20.414678', '21-2020', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№ЛР004269', '2020-03-17');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (332, '2020-04-14 15:19:24.442818', 108, 8, '2020-03-17', 3, 1, 8, 1, '2019-09-27', '2029-09-30', 1, '', 4, 6, 1, '8 скляних мірних піпеток на 25 мл', 'шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-14 15:19:24.442818', '22-2020', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№ЛР004269', '2020-03-17');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (333, '2020-04-14 15:20:29.17451', 107, 8, '2020-03-17', 3, 1, 8, 1, '2019-09-27', '2029-09-30', 1, '', 4, 6, 1, '8 скляних мірних піпеток на 10 мл', 'шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-14 15:20:29.17451', '23-2020', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№ЛР004269', '2020-03-17');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (334, '2020-04-14 15:25:01.088332', 106, 8, '2020-03-17', 3, 1, 8, 1, '2019-09-27', '2029-09-30', 1, '', 4, 6, 1, '8 скляних мірних піпеток на 5 мл', 'шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-14 15:25:01.088332', '24-2020', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№ЛР004269', '2020-03-17');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (338, '2020-04-14 15:34:49.533088', 103, 8, '2020-03-17', 3, 1, 8, 1, '2019-09-27', '2029-09-30', 1, '', 4, 6, 1, '8 скляних піпеток Мора на 2 мл', 'шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-14 15:34:49.533088', '28-2020', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№ЛР004269', '2020-03-17');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (339, '2020-04-14 15:41:32.743266', 104, 8, '2020-03-17', 3, 1, 8, 1, '2019-09-27', '2029-09-30', 0, '', 4, 6, 1, '8 скляних піпеток Мора на 5 мл', 'шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-14 15:41:32.743266', '29-2020', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№ЛР004269', '2020-03-17');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (342, '2020-04-14 16:20:05.31806', 220, 2000, '2020-03-17', 3, 1, 0, 1, '2019-09-27', '2029-09-30', 0, '', 4, 6, 1, '2 упаковки мікропробірок Епендорфа на 0,5 мл по 1000 шт/уп', 'шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-14 16:20:05.31806', '32-2020', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№ЛР004269', '2020-03-17');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (343, '2020-04-14 16:24:23.11016', 171, 1000, '2020-03-17', 3, 1, 1000, 1, '2019-09-27', '2029-09-30', 0, '', 4, 6, 1, '1 упаковка накінечників на 0-10 мкл на 1000 шт/уп', 'шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-14 16:24:23.11016', '33-2020', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№ЛР004269', '2020-03-17');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (345, '2020-04-14 16:32:36.767964', 270, 10, '2020-03-17', 3, 1, 10, 1, '2019-09-27', '2029-09-30', 0, '', 4, 6, 1, '10 фарфорових тиглів з кришкою на 50 мл', 'шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-14 16:32:36.767964', '35-2020', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№ЛР004269', '2020-03-17');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (347, '2020-04-14 16:45:53.522873', 25, 3000, '2020-03-17', 3, 1, 3000, 8, '2020-03-14', '2021-03-24', 0, 'Німеччина', 1, 5, 1, '2 пляшки із прозорою рідиною по 1,0 л (по 0,8 кг)', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-14 16:45:53.522873', '37-2020', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№ЛР004269', '2020-03-17');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (348, '2020-04-14 17:00:47.138578', 255, 2500, '2020-03-17', 3, 1, 2500, 8, '2019-07-22', '2022-07-22', 1, 'FISHER', 1, 5, 1, '1 пляшка із прозорою рідиною на 2,5 л', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-14 17:00:47.138578', '38-2020', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№ЛР004269', '2020-03-17');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (349, '2020-04-14 17:03:33.901729', 254, 2500, '2020-03-17', 3, 1, 2500, 8, '2019-12-04', '2022-12-31', 1, 'FISHER', 1, 5, 1, '1 пляшка із прозорою рідиною на 2,5 л', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-14 17:03:33.901729', '39-2020', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№ЛР004269', '2020-03-17');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (341, '2020-04-14 16:14:45.373906', 115, 2, '2020-03-17', 3, 1, 2, 1, '2019-09-27', '2029-09-30', 1, '', 4, 6, 1, '2 скляних круглодонних колби на 1000 мл', 'шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-14 16:14:45.373906', '31-2020', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№ЛР004269', '2020-03-17');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (340, '2020-04-14 15:58:16.527647', 121, 10, '2020-03-17', 3, 1, 6, 1, '2019-09-27', '2029-09-30', 1, '', 4, 6, 1, '10 скляних мірних колб на 250 мл', 'шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-14 15:58:16.527647', '30-2020', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№ЛР004269', '2020-03-17');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (344, '2020-04-14 16:30:50.549587', 125, 10, '2020-03-17', 3, 1, 10, 1, '2019-09-27', '2029-09-30', 1, '', 4, 6, 1, '10 скляних стаканів для зважування на 100 мл', 'шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-14 16:30:50.549587', '34-2020', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№ЛР004269', '2020-03-17');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (346, '2020-04-14 16:34:57.728249', 265, 15, '2020-03-17', 3, 1, 15, 1, '2019-09-27', '2029-09-30', 1, '', 4, 6, 1, '15 скляних бюксів (стаканів для зважування) з кришками', 'шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-14 16:34:57.728249', '36-2020', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№ЛР004269', '2020-03-17');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (350, '2020-04-14 17:22:22.580798', 26, 200, '2020-03-17', 3, 1, 200, 11, '2019-11-18', '2021-11-17', 1, 'Чехія', 2, 5, 1, '2 банки із речовиною по 100 г', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-14 17:22:22.580798', '40-2020', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№ЛР004269', '2020-03-17');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (351, '2020-04-14 17:25:37.48342', 30, 200, '2020-03-17', 3, 1, 200, 11, '2018-09-13', '2023-09-13', 1, 'Китай', 2, 5, 1, '2 пакета із речовиною по 100 г', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-14 17:25:37.48342', '41-2020', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№ЛР004269', '2020-03-17');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (352, '2020-04-14 17:27:53.010747', 244, 300, '2020-03-17', 3, 1, 300, 7, '2018-11-16', '2021-11-16', 1, 'Китай', 2, 5, 1, '3 банки із речовиною по 100 г', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-14 17:27:53.010747', '42-2020', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№ЛР004269', '2020-03-17');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (353, '2020-04-14 17:31:25.189906', 60, 150, '2020-03-17', 3, 1, 150, 7, '2019-08-22', '2022-08-21', 1, 'Китай', 2, 5, 1, '3 банки із речовиною по 50 г', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-14 17:31:25.189906', '43-2020', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№ЛР004269', '2020-03-17');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (354, '2020-04-14 17:33:51.418158', 178, 100, '2020-03-17', 3, 1, 100, 2, '2019-04-02', '2021-04-01', 1, 'Китай', 2, 5, 1, '1 пакет із речовиною 100 г', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-14 17:33:51.418158', '44-2020', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№ЛР004269', '2020-03-17');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (355, '2020-04-14 17:38:05.896113', 258, 50, '2020-03-17', 3, 1, 50, 7, '2018-12-28', '2024-12-28', 1, 'Індія', 2, 5, 1, '1 банка із речовиною 50 г', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-14 17:38:05.896113', '45-2020', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№ЛР004269', '2020-03-17');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (356, '2020-04-14 17:39:44.959067', 239, 50, '2020-03-17', 3, 1, 50, 7, '2019-07-24', '2021-07-24', 1, 'Індія', 2, 5, 1, '1 банка із речовиною 50 г', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-14 17:39:44.959067', '46-2020', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№ЛР004269', '2020-03-17');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (357, '2020-04-15 16:56:42.668003', 39, 1000, '2020-03-17', 3, 1, 1000, 8, '2019-04-15', '2021-04-15', 1, 'Франція', 2, 5, 1, '10 банок із речовиною по 100 г', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-15 16:56:42.668003', '47-2020', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№ЛР004269', '2020-03-17');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (358, '2020-04-15 17:02:57.0342', 28, 200, '2020-03-17', 3, 1, 200, 11, '2019-08-21', '2020-08-20', 1, 'Китай', 2, 5, 1, '2 пакета із речовиною по 100 г', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-15 17:02:57.0342', '48-2020', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№ЛР004269', '2020-03-17');


--
-- Data for Name: units; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO "public"."units" ("id", "name", "position", "short_name") VALUES (0, '--', 0, '');
INSERT INTO "public"."units" ("id", "name", "position", "short_name") VALUES (9, 'Штук', 0, 'шт');
INSERT INTO "public"."units" ("id", "name", "position", "short_name") VALUES (1, 'Мілілітр', 0, 'мл');
INSERT INTO "public"."units" ("id", "name", "position", "short_name") VALUES (2, 'Грам', 0, 'гр');


--
-- Data for Name: using; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment") VALUES ('', 0, '1970-01-01', 0, '', '1970-01-01', 0, '', '');


--
-- Name: clearence_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('"public"."clearence_id_seq"', 11, true);


--
-- Name: consume_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('"public"."consume_id_seq"', 8, true);


--
-- Name: danger_class_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('"public"."danger_class_id_seq"', 6, true);


--
-- Name: dispersion_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('"public"."dispersion_id_seq"', 22, true);


--
-- Name: expert_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('"public"."expert_id_seq"', 3, true);


--
-- Name: expertise_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('"public"."expertise_id_seq"', 1, false);


--
-- Name: groups_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('"public"."groups_id_seq"', 1, true);


--
-- Name: purpose_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('"public"."purpose_id_seq"', 3, true);


--
-- Name: reactiv_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('"public"."reactiv_id_seq"', 1, false);


--
-- Name: reactiv_menu_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('"public"."reactiv_menu_id_seq"', 31, true);


--
-- Name: reagent_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('"public"."reagent_id_seq"', 270, true);


--
-- Name: reagent_state_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('"public"."reagent_state_id_seq"', 4, true);


--
-- Name: region_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('"public"."region_id_seq"', 1, true);


--
-- Name: stock_gr_0_2020_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('"public"."stock_gr_0_2020_seq"', 3, true);


--
-- Name: stock_gr_1_2015_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('"public"."stock_gr_1_2015_seq"', 1, true);


--
-- Name: stock_gr_1_2016_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('"public"."stock_gr_1_2016_seq"', 72, true);


--
-- Name: stock_gr_1_2017_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('"public"."stock_gr_1_2017_seq"', 55, true);


--
-- Name: stock_gr_1_2018_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('"public"."stock_gr_1_2018_seq"', 51, true);


--
-- Name: stock_gr_1_2019_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('"public"."stock_gr_1_2019_seq"', 104, true);


--
-- Name: stock_gr_1_2020_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('"public"."stock_gr_1_2020_seq"', 48, true);


--
-- Name: stock_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('"public"."stock_id_seq"', 358, true);


--
-- Name: units_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('"public"."units_id_seq"', 9, true);


--
-- Name: clearence clearence_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."clearence"
    ADD CONSTRAINT "clearence_pkey" PRIMARY KEY ("id");


--
-- Name: consume consume_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."consume"
    ADD CONSTRAINT "consume_pkey" PRIMARY KEY ("hash");


--
-- Name: danger_class danger_class_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."danger_class"
    ADD CONSTRAINT "danger_class_pkey" PRIMARY KEY ("id");


--
-- Name: dispersion dispersion_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."dispersion"
    ADD CONSTRAINT "dispersion_pkey" PRIMARY KEY ("id");


--
-- Name: expert expert_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."expert"
    ADD CONSTRAINT "expert_pkey" PRIMARY KEY ("id");


--
-- Name: expertise expertise_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."expertise"
    ADD CONSTRAINT "expertise_pkey" PRIMARY KEY ("id");


--
-- Name: groups groups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."groups"
    ADD CONSTRAINT "groups_pkey" PRIMARY KEY ("id");


--
-- Name: purpose purpose_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."purpose"
    ADD CONSTRAINT "purpose_pkey" PRIMARY KEY ("id");


--
-- Name: reactiv_consume reactiv_consume_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."reactiv_consume"
    ADD CONSTRAINT "reactiv_consume_pkey" PRIMARY KEY ("hash");


--
-- Name: reactiv_menu_ingredients reactiv_menu_ingredients_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."reactiv_menu_ingredients"
    ADD CONSTRAINT "reactiv_menu_ingredients_pkey" PRIMARY KEY ("unique_index");


--
-- Name: reactiv_menu_ingredients reactiv_menu_ingredients_reagent_id_reactiv_menu_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."reactiv_menu_ingredients"
    ADD CONSTRAINT "reactiv_menu_ingredients_reagent_id_reactiv_menu_id_key" UNIQUE ("reagent_id", "reactiv_menu_id");


--
-- Name: reactiv_menu reactiv_menu_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."reactiv_menu"
    ADD CONSTRAINT "reactiv_menu_pkey" PRIMARY KEY ("id");


--
-- Name: reactiv reactiv_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."reactiv"
    ADD CONSTRAINT "reactiv_pkey" PRIMARY KEY ("hash");


--
-- Name: reagent reagent_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."reagent"
    ADD CONSTRAINT "reagent_pkey" PRIMARY KEY ("id");


--
-- Name: reagent_state reagent_state_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."reagent_state"
    ADD CONSTRAINT "reagent_state_pkey" PRIMARY KEY ("id");


--
-- Name: region region_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."region"
    ADD CONSTRAINT "region_pkey" PRIMARY KEY ("id");


--
-- Name: stock stock_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."stock"
    ADD CONSTRAINT "stock_pkey" PRIMARY KEY ("id");


--
-- Name: units units_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."units"
    ADD CONSTRAINT "units_pkey" PRIMARY KEY ("id");


--
-- Name: using using_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."using"
    ADD CONSTRAINT "using_pkey" PRIMARY KEY ("hash");


--
-- Name: reactiv_menu_ingredients_unique_index_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "reactiv_menu_ingredients_unique_index_idx" ON "public"."reactiv_menu_ingredients" USING "btree" ("unique_index");


--
-- Name: stock_inc_date_year_indx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "stock_inc_date_year_indx" ON "public"."stock" USING "btree" ((("date_part"('year'::"text", "inc_date"))::integer) DESC NULLS LAST);


--
-- Name: stock_reagent_number_indx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "stock_reagent_number_indx" ON "public"."stock" USING "btree" ((("split_part"(("reagent_number")::"text", '-'::"text", 1))::integer) DESC NULLS LAST);


--
-- Name: stock GENERATE_STOCK_NUMBER_TRIG; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER "GENERATE_STOCK_NUMBER_TRIG" BEFORE INSERT OR UPDATE ON "public"."stock" FOR EACH ROW EXECUTE PROCEDURE "public"."GENERATE_STOCK_NUMBER_TRIG"();


--
-- Name: dispersion UPDATE_DISPERSION_QUANTITY_SELF_TRIG_tr; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER "UPDATE_DISPERSION_QUANTITY_SELF_TRIG_tr" BEFORE INSERT OR UPDATE ON "public"."dispersion" FOR EACH ROW EXECUTE PROCEDURE "public"."UPDATE_DISPERSION_QUANTITY_SELF_TRIG"();


--
-- Name: consume UPDATE_DISPERSION_QUANTITY_TRIG_cons; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER "UPDATE_DISPERSION_QUANTITY_TRIG_cons" AFTER INSERT OR DELETE OR UPDATE ON "public"."consume" FOR EACH ROW EXECUTE PROCEDURE "public"."UPDATE_DISPERSION_QUANTITY_TRIG"();


--
-- Name: reactiv_consume UPDATE_REACTIVE_CONSUME_AFTER_TR; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER "UPDATE_REACTIVE_CONSUME_AFTER_TR" AFTER INSERT OR DELETE OR UPDATE ON "public"."reactiv_consume" FOR EACH ROW EXECUTE PROCEDURE "public"."UPDATE_REACTIVE_CONSUME_AFTER_TRIG"();


--
-- Name: reactiv UPDATE_REACTIVE_QUANTITY_SELF_TR; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER "UPDATE_REACTIVE_QUANTITY_SELF_TR" BEFORE INSERT OR UPDATE OF "quantity_inc", "quantity_left" ON "public"."reactiv" FOR EACH ROW EXECUTE PROCEDURE "public"."UPDATE_REACTIVE_QUANTITY_SELF_TRIG"();


--
-- Name: stock UPDATE_STOCK_QUANTITY_SELF_TRIG_tr; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER "UPDATE_STOCK_QUANTITY_SELF_TRIG_tr" BEFORE INSERT OR UPDATE ON "public"."stock" FOR EACH ROW EXECUTE PROCEDURE "public"."UPDATE_STOCK_QUANTITY_SELF_TRIG"();


--
-- Name: dispersion UPDATE_STOCK_QUANTITY_in_disp; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER "UPDATE_STOCK_QUANTITY_in_disp" AFTER INSERT OR DELETE OR UPDATE ON "public"."dispersion" FOR EACH ROW EXECUTE PROCEDURE "public"."UPDATE_STOCK_QUANTITY_TRIG"();


--
-- Name: reactiv_menu_ingredients reactive_menu_uniq_trig; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER "reactive_menu_uniq_trig" BEFORE INSERT OR UPDATE ON "public"."reactiv_menu_ingredients" FOR EACH ROW EXECUTE PROCEDURE "public"."MAKE_RECIPE_UNIQUE_INDEX_TRIG"();


--
-- Name: consume consume_dispersion_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."consume"
    ADD CONSTRAINT "consume_dispersion_id_fkey" FOREIGN KEY ("dispersion_id") REFERENCES "public"."dispersion"("id") ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: consume consume_expert_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."consume"
    ADD CONSTRAINT "consume_expert_id_fkey" FOREIGN KEY ("inc_expert_id") REFERENCES "public"."expert"("id") ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: consume consume_using_hash_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."consume"
    ADD CONSTRAINT "consume_using_hash_fkey" FOREIGN KEY ("using_hash") REFERENCES "public"."using"("hash") ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: dispersion dispersion_expert_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."dispersion"
    ADD CONSTRAINT "dispersion_expert_id_fkey" FOREIGN KEY ("inc_expert_id") REFERENCES "public"."expert"("id") ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: dispersion dispersion_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."dispersion"
    ADD CONSTRAINT "dispersion_group_id_fkey" FOREIGN KEY ("group_id") REFERENCES "public"."groups"("id") ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: dispersion dispersion_out_expert_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."dispersion"
    ADD CONSTRAINT "dispersion_out_expert_id_fkey" FOREIGN KEY ("out_expert_id") REFERENCES "public"."expert"("id") ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: dispersion dispersion_stock_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."dispersion"
    ADD CONSTRAINT "dispersion_stock_id_fkey" FOREIGN KEY ("stock_id") REFERENCES "public"."stock"("id") ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: expert expert_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."expert"
    ADD CONSTRAINT "expert_group_id_fkey" FOREIGN KEY ("group_id") REFERENCES "public"."groups"("id") ON UPDATE CASCADE ON DELETE SET DEFAULT;


--
-- Name: groups groups_region_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."groups"
    ADD CONSTRAINT "groups_region_id_fkey" FOREIGN KEY ("region_id") REFERENCES "public"."region"("id") ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: reactiv_consume reactiv_consume_expert_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."reactiv_consume"
    ADD CONSTRAINT "reactiv_consume_expert_id_fkey" FOREIGN KEY ("inc_expert_id") REFERENCES "public"."expert"("id") ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: reactiv_consume reactiv_consume_reactive_hash_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."reactiv_consume"
    ADD CONSTRAINT "reactiv_consume_reactive_hash_fkey" FOREIGN KEY ("reactive_hash") REFERENCES "public"."reactiv"("hash") ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: reactiv_consume reactiv_consume_using_hash_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."reactiv_consume"
    ADD CONSTRAINT "reactiv_consume_using_hash_fkey" FOREIGN KEY ("using_hash") REFERENCES "public"."using"("hash") ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: reactiv reactiv_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."reactiv"
    ADD CONSTRAINT "reactiv_group_id_fkey" FOREIGN KEY ("group_id") REFERENCES "public"."groups"("id") ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: reactiv reactiv_inc_expert_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."reactiv"
    ADD CONSTRAINT "reactiv_inc_expert_id_fkey" FOREIGN KEY ("inc_expert_id") REFERENCES "public"."expert"("id") ON UPDATE CASCADE ON DELETE SET DEFAULT;


--
-- Name: reactiv_menu_ingredients reactiv_menu_ingredients_reactiv_menu_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."reactiv_menu_ingredients"
    ADD CONSTRAINT "reactiv_menu_ingredients_reactiv_menu_id_fkey" FOREIGN KEY ("reactiv_menu_id") REFERENCES "public"."reactiv_menu"("id") ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: reactiv_menu_ingredients reactiv_menu_ingredients_reagent_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."reactiv_menu_ingredients"
    ADD CONSTRAINT "reactiv_menu_ingredients_reagent_id_fkey" FOREIGN KEY ("reagent_id") REFERENCES "public"."reagent"("id") ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: reactiv_menu reactiv_menu_units_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."reactiv_menu"
    ADD CONSTRAINT "reactiv_menu_units_id_fkey" FOREIGN KEY ("units_id") REFERENCES "public"."units"("id") ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: reactiv reactiv_reactiv_menu_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."reactiv"
    ADD CONSTRAINT "reactiv_reactiv_menu_id_fkey" FOREIGN KEY ("reactiv_menu_id") REFERENCES "public"."reactiv_menu"("id") ON UPDATE CASCADE ON DELETE SET DEFAULT;


--
-- Name: reactiv reactiv_using_hash_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."reactiv"
    ADD CONSTRAINT "reactiv_using_hash_fkey" FOREIGN KEY ("using_hash") REFERENCES "public"."using"("hash") ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: reagent reagent_created_by_expert_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."reagent"
    ADD CONSTRAINT "reagent_created_by_expert_id_fkey" FOREIGN KEY ("created_by_expert_id") REFERENCES "public"."expert"("id") ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: reagent reagent_units_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."reagent"
    ADD CONSTRAINT "reagent_units_id_fkey" FOREIGN KEY ("units_id") REFERENCES "public"."units"("id") ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: stock stock_clearence_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."stock"
    ADD CONSTRAINT "stock_clearence_id_fkey" FOREIGN KEY ("clearence_id") REFERENCES "public"."clearence"("id") ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: stock stock_danger_class_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."stock"
    ADD CONSTRAINT "stock_danger_class_id_fkey" FOREIGN KEY ("danger_class_id") REFERENCES "public"."danger_class"("id") ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: stock stock_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."stock"
    ADD CONSTRAINT "stock_group_id_fkey" FOREIGN KEY ("group_id") REFERENCES "public"."groups"("id") ON UPDATE CASCADE ON DELETE SET DEFAULT;


--
-- Name: stock stock_inc_expert_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."stock"
    ADD CONSTRAINT "stock_inc_expert_id_fkey" FOREIGN KEY ("inc_expert_id") REFERENCES "public"."expert"("id") ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: stock stock_reagent_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."stock"
    ADD CONSTRAINT "stock_reagent_id_fkey" FOREIGN KEY ("reagent_id") REFERENCES "public"."reagent"("id") ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: stock stock_reagent_state_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."stock"
    ADD CONSTRAINT "stock_reagent_state_id_fkey" FOREIGN KEY ("reagent_state_id") REFERENCES "public"."reagent_state"("id") ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: using using_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."using"
    ADD CONSTRAINT "using_group_id_fkey" FOREIGN KEY ("group_id") REFERENCES "public"."groups"("id") ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: using using_purpose_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."using"
    ADD CONSTRAINT "using_purpose_id_fkey" FOREIGN KEY ("purpose_id") REFERENCES "public"."purpose"("id") ON UPDATE CASCADE ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

