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
	
	DECLARE reagent_number TEXT;
	DECLARE seq_name TEXT;
	DECLARE seq_exist INTEGER;

DECLARE	

BEGIN

		IF NEW.reagent_number != '' THEN
		
			return NEW;
			
		END IF;

		reagent_number := '';
		seq_name := 'stock_gr_'::text || NEW.group_id ::text || '_'::text || EXTRACT( year from NEW.inc_date )::text || '_seq'::TEXT;
		
		SELECT COUNT(c.relname) FROM pg_class c WHERE c.relkind = 'S' AND c.relname = seq_name INTO seq_exist;
		
		IF seq_exist = 0 THEN
		
					EXECUTE 'CREATE SEQUENCE "public"."' || seq_name || '" INCREMENT 1 MINVALUE 1 START 1;';
					
		END IF;
		
		
		LOOP
				SELECT ( nextval( seq_name )::TEXT || '-'::TEXT || EXTRACT( year from NEW.inc_date )::text ) INTO NEW.reagent_number;
				SELECT COUNT( stock.id ) FROM stock WHERE stock.reagent_number = NEW.reagent_number INTO seq_exist;
				
				IF seq_exist = 0 THEN
					EXIT;
				END IF;
		END LOOP;

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
    "consume_ts" timestamp(0) without time zone DEFAULT ("now"())::timestamp without time zone NOT NULL
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
    "reagent_number" character varying DEFAULT ''::character varying NOT NULL
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
-- Name: stock_gr_1_2015_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE "public"."stock_gr_1_2015_seq"
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
    NO MINVALUE
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


--
-- Data for Name: consume; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "using_hash", "consume_ts", "date") VALUES ('315576ac138b884e9e0cd5aeaeb7fe2f', '2020-03-31 08:34:43.728464', 12, 1, 17, '551d21f8f4ee2efaf5507d1f2ba92c10', '2020-03-31 08:34:43.728464', '2020-03-02');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "using_hash", "consume_ts", "date") VALUES ('16dbf90fb163a21e856011676c040eaa', '2020-03-31 08:34:43.728464', 10, 1, 2, '551d21f8f4ee2efaf5507d1f2ba92c10', '2020-03-31 08:34:43.728464', '2020-03-02');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "using_hash", "consume_ts", "date") VALUES ('', '2020-01-02 15:37:30.168681', 0, 0, 0, '', '2020-03-18 16:07:51.03563', '1970-01-01');


--
-- Data for Name: danger_class; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO "public"."danger_class" ("id", "name", "position") VALUES (0, '--', 0);
INSERT INTO "public"."danger_class" ("id", "name", "position") VALUES (3, 'Перший (І)', 0);
INSERT INTO "public"."danger_class" ("id", "name", "position") VALUES (2, 'Другий (ІІ)', 0);
INSERT INTO "public"."danger_class" ("id", "name", "position") VALUES (1, 'Третій (ІІІ)', 0);
INSERT INTO "public"."danger_class" ("id", "name", "position") VALUES (4, 'Четвертий (IV)', 0);


--
-- Data for Name: dispersion; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO "public"."dispersion" ("id", "stock_id", "ts", "inc_expert_id", "out_expert_id", "quantity_inc", "quantity_left", "group_id", "inc_date", "comment", "created_ts") VALUES (0, 0, '2020-01-02 15:37:24.48078', 0, 0, 0, 0, 0, '1970-01-01', '', '2020-03-13 11:54:36.766118+02');
INSERT INTO "public"."dispersion" ("id", "stock_id", "ts", "inc_expert_id", "out_expert_id", "quantity_inc", "quantity_left", "group_id", "inc_date", "comment", "created_ts") VALUES (14, 12, '2020-03-24 16:32:30.368918', 2, 1, 200, 200, 1, '2020-03-24', '', '2020-03-24 16:32:30.368918+02');
INSERT INTO "public"."dispersion" ("id", "stock_id", "ts", "inc_expert_id", "out_expert_id", "quantity_inc", "quantity_left", "group_id", "inc_date", "comment", "created_ts") VALUES (15, 14, '2020-03-24 17:32:37.80875', 3, 3, 1000, 1000, 1, '2020-03-24', '', '2020-03-24 17:32:37.80875+02');
INSERT INTO "public"."dispersion" ("id", "stock_id", "ts", "inc_expert_id", "out_expert_id", "quantity_inc", "quantity_left", "group_id", "inc_date", "comment", "created_ts") VALUES (16, 15, '2020-03-24 17:32:58.484095', 3, 3, 500, 500, 1, '2020-03-24', '', '2020-03-24 17:32:58.484095+02');
INSERT INTO "public"."dispersion" ("id", "stock_id", "ts", "inc_expert_id", "out_expert_id", "quantity_inc", "quantity_left", "group_id", "inc_date", "comment", "created_ts") VALUES (12, 10, '2020-03-20 12:32:57.550742', 1, 2, 500, 483, 1, '2020-03-20', '', '2020-03-20 12:32:57.550742+02');
INSERT INTO "public"."dispersion" ("id", "stock_id", "ts", "inc_expert_id", "out_expert_id", "quantity_inc", "quantity_left", "group_id", "inc_date", "comment", "created_ts") VALUES (11, 11, '2020-03-20 12:32:38.473591', 1, 2, 3, 3, 1, '2020-03-20', '', '2020-03-20 12:32:38.473591+02');
INSERT INTO "public"."dispersion" ("id", "stock_id", "ts", "inc_expert_id", "out_expert_id", "quantity_inc", "quantity_left", "group_id", "inc_date", "comment", "created_ts") VALUES (10, 9, '2020-03-20 12:31:36.252217', 1, 2, 20, 18, 1, '2020-03-20', '', '2020-03-20 12:31:36.252217+02');


--
-- Data for Name: expert; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO "public"."expert" ("id", "surname", "name", "phname", "visible", "ts", "login", "password", "token", "group_id", "last_ip") VALUES (0, '', '', '', 1, '2019-12-28 11:10:20.623791', '', '', '', 0, '0.0.0.0');
INSERT INTO "public"."expert" ("id", "surname", "name", "phname", "visible", "ts", "login", "password", "token", "group_id", "last_ip") VALUES (3, 'Шинкаренко', 'Дмитро', 'Юрійович', 1, '2020-03-24 17:12:38.05303', 'shinkarenko', '953adda3778dcf339f8debe9a72dcc34', '97ab313379ea5d8bdfde11ebe5d82be6', 1, '192.168.2.127');
INSERT INTO "public"."expert" ("id", "surname", "name", "phname", "visible", "ts", "login", "password", "token", "group_id", "last_ip") VALUES (1, 'Пташкін', 'Роман', 'Леонідович', 1, '2019-12-29 23:17:39.53982', 'root', '855cb86bd065112c52899ef9ea7b9918', '3638bcd565af1daea3f93755fc187fa7', 1, '192.168.137.168');
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

INSERT INTO "public"."reactiv" ("hash", "reactiv_menu_id", "quantity_inc", "quantity_left", "inc_expert_id", "group_id", "inc_date", "dead_date", "safe_place", "safe_needs", "comment", "using_hash") VALUES ('33ea3d303eb0f672b349a30b2613f9e5', 29, 20, 20, 1, 1, '2020-03-02', '2020-03-03', 'тест', 'тест', 'тест', '551d21f8f4ee2efaf5507d1f2ba92c10');
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
INSERT INTO "public"."reactiv_menu" ("id", "name", "position", "units_id", "comment") VALUES (29, '00-Тестовий рецепт-01', 0, 1, 'N2szWTBaeU81TjJjbXNUZWpWV2Ftc1RlalJuSg%3D%3D');
INSERT INTO "public"."reactiv_menu" ("id", "name", "position", "units_id", "comment") VALUES (30, '00-Тестовий рецепт-02', 0, 1, 'eUFUTDdrM1kwWnlPNU5HY21zVGVqVldhbXNUZWpOSGRtc1RlalZXYW1zVGVqSm5KZ3NUZWpwbUo3azNZcFp5TzVObWRtc1RlajltSjdrM1kwWnlPNU4yY21zVGVqVldhbXNUZWpSbEp0QURN');
INSERT INTO "public"."reactiv_menu" ("id", "name", "position", "units_id", "comment") VALUES (31, '00-Тестовий рецепт-03', 0, 2, '');


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
INSERT INTO "public"."reactiv_menu_ingredients" ("reagent_id", "reactiv_menu_id", "unique_index") VALUES (94, 29, '8135daed90a2f60c211890b296105433');
INSERT INTO "public"."reactiv_menu_ingredients" ("reagent_id", "reactiv_menu_id", "unique_index") VALUES (95, 29, '93beb777bbdfcd1d0cfb70499294d5d3');
INSERT INTO "public"."reactiv_menu_ingredients" ("reagent_id", "reactiv_menu_id", "unique_index") VALUES (94, 30, 'eace324899f46c82038e25681a7393cc');
INSERT INTO "public"."reactiv_menu_ingredients" ("reagent_id", "reactiv_menu_id", "unique_index") VALUES (96, 30, 'bd43c6954d718b90779bc43eedc71ef8');
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
INSERT INTO "public"."reactiv_menu_ingredients" ("reagent_id", "reactiv_menu_id", "unique_index") VALUES (96, 31, '3574b45c1f3e155e2939774eca102b93');
INSERT INTO "public"."reactiv_menu_ingredients" ("reagent_id", "reactiv_menu_id", "unique_index") VALUES (94, 31, '6c6fa4f7c54fbd752ef649ce4e21b164');


--
-- Data for Name: reagent; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (81, '2020-03-16 22:23:10.617711', '1,2 динітробензол', 1, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (21, '2020-01-02 15:39:01.529732', 'Діетиловий ефір', 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (24, '2020-01-02 15:39:01.529732', 'Ефір диізопропіловий', 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (25, '2020-01-02 15:39:01.529732', 'Ізопропанол', 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (23, '2020-01-02 15:39:01.529732', 'Етилацетат', 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (20, '2020-01-02 15:39:01.529732', 'Діетиламін', 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (2, '2020-01-02 15:39:01.529732', '1,3 - Динітробензол', 1, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (82, '2020-03-17 12:38:38.461639', 'Селениста кислота', 2, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (10, '2020-01-02 15:39:01.529732', 'Ацетон', 1, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (22, '2020-01-02 15:39:01.529732', 'Етанол', 1, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (84, '2020-03-18 12:58:32.313461', 'Сульфат заліза (ІІІ)', 1, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (85, '2020-03-18 15:48:39.161596', 'Хлоридна кислота розбавлена (Реагент)', 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (86, '2020-03-18 17:58:42.08735', 'Йод кристалічний', 2, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (87, '2020-03-18 18:20:35.233556', 'Галова кислота', 2, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (88, '2020-03-19 10:33:04.64491', 'Поліетиленгліколь', 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (90, '2020-03-19 10:39:52.749282', 'ізопропіламін', 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (93, '2020-03-19 11:41:30.12809', '4-диметиламінобензальдегід', 2, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (11, '2020-01-02 15:39:01.529732', 'Ацетонітрил', 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (12, '2020-01-02 15:39:01.529732', 'Барій сульфат', 2, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (3, '2020-01-02 15:39:01.529732', '1,4-Диоксан', 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (4, '2020-01-02 15:39:01.529732', 'N, N - диметилформамід', 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (5, '2020-01-02 15:39:01.529732', 'Азотна кислота', 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (6, '2020-01-02 15:39:01.529732', 'Альдегід оцтовий', 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (7, '2020-01-02 15:39:01.529732', 'Аміак 25%', 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (8, '2020-01-02 15:39:01.529732', 'Амоній молібденовокислий', 2, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (9, '2020-01-02 15:39:01.529732', 'Аргентум нітрат', 2, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (13, '2020-01-02 15:39:01.529732', 'Барію хлорид', 2, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (14, '2020-01-02 15:39:01.529732', 'Бензол', 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (0, '2019-12-28 11:10:26.287818', '--', 0, 0);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (15, '2020-01-02 15:39:01.529732', 'Бутанол', 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (16, '2020-01-02 15:39:01.529732', 'Ванілін', 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (17, '2020-01-02 15:39:01.529732', 'Вісмут нітрат', 2, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (94, '2020-03-19 12:16:55.578858', '00-Тестовий реактив 01', 1, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (95, '2020-03-20 12:11:29.70994', '00-Тестовий реактив 02', 1, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (97, '2020-03-24 16:44:54.767631', 'Ацетон 2/10-2019', 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (91, '2020-03-19 10:43:04.659486', '1,4-динітробензол', 3, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (18, '2020-01-02 15:39:01.529732', 'Гліцерин', 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (83, '2020-03-17 12:43:19.841877', 'Дистильована вода', 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (19, '2020-01-02 15:39:01.529732', 'Дифенілкарбазон', 2, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (92, '2020-03-19 11:06:13.688529', 'ацетат кобальту (ІІ)', 1, 2);
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
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (35, '2020-01-02 15:39:01.529732', 'Мідь (ІІ) сульфат', 2, 2);
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
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (53, '2020-01-02 15:39:01.529732', 'Петролейний ефір', 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (54, '2020-01-02 15:39:01.529732', 'Піридин', 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (55, '2020-01-02 15:39:01.529732', 'Платина VI хлорид', 2, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (57, '2020-01-02 15:39:01.529732', 'Сульфатна кислота концентрована', 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (58, '2020-01-02 15:39:01.529732', 'Толуол', 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (60, '2020-01-02 15:39:01.529732', 'Фенолфталеїн', 2, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (61, '2020-01-02 15:39:01.529732', 'Ферум (ІІІ) хлорид', 2, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (62, '2020-01-02 15:39:01.529732', 'Формальдегід', 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (63, '2020-01-02 15:39:01.529732', 'Хлоридна кислота концентрована', 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (64, '2020-01-02 15:39:01.529732', 'Хлороформ', 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id") VALUES (96, '2020-03-20 12:12:41.66433', '00-Тестовий реактив 03', 1, 9);


--
-- Data for Name: reagent_state; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO "public"."reagent_state" ("id", "name", "position") VALUES (0, '--', 0);
INSERT INTO "public"."reagent_state" ("id", "name", "position") VALUES (1, 'Рідка', 0);
INSERT INTO "public"."reagent_state" ("id", "name", "position") VALUES (2, 'Тверда', 0);


--
-- Data for Name: region; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO "public"."region" ("id", "ts", "name", "position") VALUES (0, '2019-12-28 11:09:22.894212', '--', 0);
INSERT INTO "public"."region" ("id", "ts", "name", "position") VALUES (1, '2019-12-29 23:22:02.645034', 'Черкаська область', 0);


--
-- Data for Name: stock; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number") VALUES (13, '2020-03-24 17:07:47.842647', 81, 1000, '2020-03-23', 1, 1, 1000, 10, '2019-09-02', '2021-01-29', 1, 'Тестовий виробник 02', 1, 1, 0, 'іфв іваіфва', 'тестове місце', 'тестові умови', '2020-03-24 17:07:47.842647', '8-2020');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number") VALUES (10, '2020-03-20 12:25:03.917761', 95, 550, '2020-03-19', 1, 1, 50, 2, '2019-09-12', '2027-03-28', 1, 'Тестовий виробник 02', 1, 3, 0, 'Тест', 'тестове місце', 'тестові умови', '2020-03-20 12:25:03.917761', '5-2020');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number") VALUES (9, '2020-03-20 12:20:54.468328', 94, 1000, '2020-03-20', 1, 1, 980, 8, '2019-03-20', '2028-03-27', 1, 'Тестовий виробник 01', 2, 2, 1, 'Тестові примітки', 'тестове місце', 'тестові умови', '2020-03-20 12:20:54.468328', '6-2020');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number") VALUES (14, '2020-03-24 17:30:51.463538', 57, 5000, '2020-03-24', 3, 1, 4000, 7, '2020-03-02', '2021-03-02', 1, 'Хімлаборреактив', 1, 4, 1, '', 'Кімната 318', 'Місце', '2020-03-24 17:30:51.463538', '9-2020');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number") VALUES (11, '2020-03-20 12:26:04.515197', 96, 15, '2020-03-20', 1, 1, 12, 1, '2020-01-01', '2028-03-26', 1, 'Тестовий виробник 03', 1, 4, 1, 'Тест 03', 'тестове місце', 'тестові умови', '2020-03-20 12:26:04.515197', '4-2020');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number") VALUES (12, '2020-03-24 16:30:49.968623', 81, 500, '2020-01-01', 2, 1, 300, 10, '2019-11-12', '2020-05-15', 1, 'Хімлаборреактив', 2, 4, 1, '', 'сейф', 'прохолодне місце', '2020-03-24 16:30:49.968623', '7-2020');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number") VALUES (15, '2020-03-24 17:32:05.616587', 62, 1000, '2020-03-24', 1, 1, 500, 7, '2020-03-03', '2021-03-03', 1, 'Хімлаборреактив', 1, 3, 1, '', 'Кімната 318', 'Місце', '2020-03-24 17:32:05.616587', '3-2020');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number") VALUES (0, '2020-01-02 15:37:14.580544', 0, 0, '2020-01-01', 0, 0, 0, 0, '1970-01-01', '1970-01-01', 0, '', 0, 0, 0, '', '', '', '2020-03-12 09:48:19.879959', '1-2020');


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

INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment") VALUES ('77fdeb9ffde2556d4b82fbac0fefc0e4', 1, '2020-03-31', 1, 'тест-01', '2020-03-31', 12, '', 'PTh1NGdEeTdnTCtzdkR1NHpDeU15RXo3aVA3N2dEaTR6K080');
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment") VALUES ('', 0, '1970-01-01', 0, '', '1970-01-01', 0, '', '');
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment") VALUES ('551d21f8f4ee2efaf5507d1f2ba92c10', 3, '2020-03-02', 1, '', '1970-01-01', 0, '', '');


--
-- Name: clearence_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('"public"."clearence_id_seq"', 10, true);


--
-- Name: consume_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('"public"."consume_id_seq"', 8, true);


--
-- Name: danger_class_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('"public"."danger_class_id_seq"', 4, true);


--
-- Name: dispersion_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('"public"."dispersion_id_seq"', 16, true);


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

SELECT pg_catalog.setval('"public"."reagent_id_seq"', 98, true);


--
-- Name: reagent_state_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('"public"."reagent_state_id_seq"', 3, true);


--
-- Name: region_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('"public"."region_id_seq"', 1, true);


--
-- Name: stock_gr_1_2015_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('"public"."stock_gr_1_2015_seq"', 1, true);


--
-- Name: stock_gr_1_2018_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('"public"."stock_gr_1_2018_seq"', 1, true);


--
-- Name: stock_gr_1_2019_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('"public"."stock_gr_1_2019_seq"', 1, true);


--
-- Name: stock_gr_1_2020_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('"public"."stock_gr_1_2020_seq"', 10, true);


--
-- Name: stock_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('"public"."stock_id_seq"', 19, true);


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

