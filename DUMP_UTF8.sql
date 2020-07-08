--
-- PostgreSQL database dump
--

-- Dumped from database version 11.8 (Debian 11.8-1.pgdg80+1)
-- Dumped by pg_dump version 11.8 (Debian 11.8-1.pgdg80+1)

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
				SELECT COUNT( stock.id ) FROM stock WHERE stock.reagent_number = rn AND stock.group_id = NEW.group_id INTO seq_exist;
				
				IF seq_exist = 0 THEN
					EXIT;
				END IF;
		END LOOP;
		
		NEW.reagent_number := rn;

		RETURN NEW;
	
END;$$;


--
-- Name: MAKE_RECIPE_REACT_UNIQUE_INDEX_TRIG(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION "public"."MAKE_RECIPE_REACT_UNIQUE_INDEX_TRIG"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$

	DECLARE	
BEGIN

		NEW.unique_index = MD5( NEW.reactiv_id::TEXT || ':'::TEXT || NEW.reactiv_menu_id::TEXT );
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
		curr_reactive_hash = NEW.reactiv_hash;
	END IF;

	IF TG_OP != 'INSERT' AND TG_OP != 'UPDATE' THEN
		curr_reactive_hash = OLD.reactiv_hash;
	END IF;

	SELECT quantity_inc FROM reactiv WHERE hash = curr_reactive_hash INTO reactiv_quantity_inc;
	
	SELECT coalesce(SUM( quantity ), 0) FROM reactiv_consume WHERE reactiv_hash = curr_reactive_hash INTO consumed;
	
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

	SELECT coalesce(SUM( quantity ), 0) FROM reactiv_consume WHERE reactiv_hash = NEW.hash INTO fully_consumed;
	
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
-- Name: access; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE "public"."access" (
    "id" integer NOT NULL,
    "name" character varying(255) DEFAULT ''::character varying NOT NULL,
    "label" character varying(32) DEFAULT ''::character varying NOT NULL,
    "position" integer DEFAULT 0 NOT NULL
);


--
-- Name: access_actions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE "public"."access_actions" (
    "access_id" integer DEFAULT 0 NOT NULL,
    "action_id" integer DEFAULT 0 NOT NULL
);


--
-- Name: access_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE "public"."access_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: access_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE "public"."access_id_seq" OWNED BY "public"."access"."id";


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
    "consume_ts" timestamp without time zone DEFAULT ("now"())::timestamp without time zone NOT NULL,
    "date" "date" DEFAULT '1970-01-01'::"date" NOT NULL,
    CONSTRAINT "consume_check_quantity" CHECK (("quantity" >= (0)::double precision))
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
-- Name: consume_using; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE "public"."consume_using" (
    "consume_hash" character varying(32) DEFAULT ''::character varying NOT NULL,
    "using_hash" character varying(32) DEFAULT NULL::character varying NOT NULL
);


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
    "created_ts" timestamp(6) with time zone DEFAULT ("now"())::timestamp without time zone NOT NULL,
    CONSTRAINT "dispersion_check_quantity_inc" CHECK (("quantity_inc" >= (0)::double precision)),
    CONSTRAINT "dispersion_check_quantity_left" CHECK (("quantity_left" >= (0)::double precision))
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
    "last_ip" "inet" DEFAULT '0.0.0.0'::"inet" NOT NULL,
    "access_id" integer DEFAULT 0 NOT NULL
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
-- Name: prolongation; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE "public"."prolongation" (
    "hash" character varying(32) DEFAULT "public"."generate_hash"('prolongation'::"text") NOT NULL,
    "stock_id" bigint DEFAULT 0 NOT NULL,
    "date_before_prolong" "date" DEFAULT '1970-01-01'::"date" NOT NULL,
    "date_after_prolong" "date" DEFAULT '1970-01-01'::"date" NOT NULL,
    "ts" timestamp(6) without time zone DEFAULT ("now"())::timestamp without time zone NOT NULL,
    "expert_id" bigint DEFAULT 0 NOT NULL,
    "date_prolong" "date" DEFAULT ("now"())::"date" NOT NULL,
    "act_number" character varying(32) DEFAULT ''::character varying NOT NULL,
    "act_date" "date" DEFAULT '1970-01-01'::"date" NOT NULL
);


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
    CONSTRAINT "reactiv_check_quantity_inc" CHECK (("quantity_inc" >= (0)::double precision)),
    CONSTRAINT "reactiv_check_quantity_left" CHECK (("quantity_left" >= (0)::double precision))
);


--
-- Name: reactiv_consume; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE "public"."reactiv_consume" (
    "hash" character varying(32) DEFAULT "public"."generate_hash"('reactiv_consume'::"text") NOT NULL,
    "reactiv_hash" character varying(32) DEFAULT ''::character varying NOT NULL,
    "quantity" double precision DEFAULT 0 NOT NULL,
    "inc_expert_id" bigint DEFAULT 0 NOT NULL,
    "consume_ts" timestamp(6) without time zone DEFAULT ("now"())::timestamp without time zone NOT NULL,
    "ts" timestamp(6) without time zone DEFAULT ("now"())::timestamp without time zone NOT NULL,
    "date" "date" DEFAULT '1970-01-01'::"date" NOT NULL,
    CONSTRAINT "reactiv_consume_check_quantity" CHECK (("quantity" >= (0)::double precision))
);


--
-- Name: reactiv_consume_using; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE "public"."reactiv_consume_using" (
    "consume_hash" character varying(32) DEFAULT ''::character varying NOT NULL,
    "using_hash" character varying(32) DEFAULT NULL::character varying NOT NULL
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
-- Name: reactiv_ingr_reactiv; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE "public"."reactiv_ingr_reactiv" (
    "consume_hash" character varying(32) DEFAULT ''::character varying NOT NULL,
    "reactiv_hash" character varying(32) DEFAULT ''::character varying NOT NULL
);


--
-- Name: reactiv_ingr_reagent; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE "public"."reactiv_ingr_reagent" (
    "consume_hash" character varying(32) DEFAULT ''::character varying NOT NULL,
    "reactiv_hash" character varying(32) DEFAULT ''::character varying NOT NULL
);


--
-- Name: reactiv_menu; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE "public"."reactiv_menu" (
    "id" bigint NOT NULL,
    "name" character varying(255) DEFAULT 0 NOT NULL,
    "position" integer DEFAULT 0 NOT NULL,
    "units_id" integer DEFAULT 0 NOT NULL,
    "comment" "text" DEFAULT ''::"text" NOT NULL,
    "group_id" integer DEFAULT 0 NOT NULL
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
-- Name: reactiv_menu_reactives; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE "public"."reactiv_menu_reactives" (
    "reactiv_menu_id" bigint DEFAULT 0 NOT NULL,
    "reactiv_id" bigint DEFAULT 0 NOT NULL,
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
    "units_id" integer DEFAULT 0 NOT NULL,
    "group_id" integer DEFAULT 0 NOT NULL
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
-- Name: spr_access_actions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE "public"."spr_access_actions" (
    "id" integer NOT NULL,
    "label" character varying(32) DEFAULT ''::character varying NOT NULL,
    "name" character varying(255) DEFAULT ''::character varying NOT NULL
);


--
-- Name: spr_access_actions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE "public"."spr_access_actions_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: spr_access_actions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE "public"."spr_access_actions_id_seq" OWNED BY "public"."spr_access_actions"."id";


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
    "nakladna_date" "date" DEFAULT '1970-01-01'::"date" NOT NULL,
    CONSTRAINT "stock_check_quantity_inc" CHECK (("quantity_inc" >= (0)::double precision)),
    CONSTRAINT "stock_check_quantity_left" CHECK (("quantity_left" >= (0)::double precision))
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
-- Name: stock_gr_1_2010_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE "public"."stock_gr_1_2010_seq"
    START WITH 1
    INCREMENT BY 1
    MINVALUE 0
    NO MAXVALUE
    CACHE 1;


--
-- Name: stock_gr_1_2011_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE "public"."stock_gr_1_2011_seq"
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
-- Name: stock_gr_2_2015_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE "public"."stock_gr_2_2015_seq"
    START WITH 1
    INCREMENT BY 1
    MINVALUE 0
    NO MAXVALUE
    CACHE 1;


--
-- Name: stock_gr_2_2016_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE "public"."stock_gr_2_2016_seq"
    START WITH 1
    INCREMENT BY 1
    MINVALUE 0
    NO MAXVALUE
    CACHE 1;


--
-- Name: stock_gr_2_2017_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE "public"."stock_gr_2_2017_seq"
    START WITH 1
    INCREMENT BY 1
    MINVALUE 0
    NO MAXVALUE
    CACHE 1;


--
-- Name: stock_gr_2_2018_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE "public"."stock_gr_2_2018_seq"
    START WITH 1
    INCREMENT BY 1
    MINVALUE 0
    NO MAXVALUE
    CACHE 1;


--
-- Name: stock_gr_2_2019_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE "public"."stock_gr_2_2019_seq"
    START WITH 1
    INCREMENT BY 1
    MINVALUE 0
    NO MAXVALUE
    CACHE 1;


--
-- Name: stock_gr_2_2020_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE "public"."stock_gr_2_2020_seq"
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
    "ucomment" "text" DEFAULT ''::"text" NOT NULL,
    "expert_id" bigint DEFAULT 0 NOT NULL
);


--
-- Name: access id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."access" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."access_id_seq"'::"regclass");


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
-- Name: spr_access_actions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."spr_access_actions" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."spr_access_actions_id_seq"'::"regclass");


--
-- Name: stock id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."stock" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."stock_id_seq"'::"regclass");


--
-- Name: units id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."units" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."units_id_seq"'::"regclass");


--
-- Data for Name: access; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO "public"."access" ("id", "name", "label", "position") VALUES (0, '--', '', 0);
INSERT INTO "public"."access" ("id", "name", "label", "position") VALUES (1, 'Адміністратор системи', 'root', 0);
INSERT INTO "public"."access" ("id", "name", "label", "position") VALUES (4, 'Експерт', 'expert', 3);
INSERT INTO "public"."access" ("id", "name", "label", "position") VALUES (2, 'Адміністратор центру', 'admin_region', 1);
INSERT INTO "public"."access" ("id", "name", "label", "position") VALUES (3, 'Адміністратор лабораторії', 'admin_lab', 2);


--
-- Data for Name: access_actions; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO "public"."access_actions" ("access_id", "action_id") VALUES (1, 6);
INSERT INTO "public"."access_actions" ("access_id", "action_id") VALUES (1, 1);
INSERT INTO "public"."access_actions" ("access_id", "action_id") VALUES (1, 8);
INSERT INTO "public"."access_actions" ("access_id", "action_id") VALUES (1, 3);
INSERT INTO "public"."access_actions" ("access_id", "action_id") VALUES (1, 2);
INSERT INTO "public"."access_actions" ("access_id", "action_id") VALUES (1, 4);
INSERT INTO "public"."access_actions" ("access_id", "action_id") VALUES (1, 5);
INSERT INTO "public"."access_actions" ("access_id", "action_id") VALUES (1, 7);
INSERT INTO "public"."access_actions" ("access_id", "action_id") VALUES (1, 13);
INSERT INTO "public"."access_actions" ("access_id", "action_id") VALUES (2, 14);
INSERT INTO "public"."access_actions" ("access_id", "action_id") VALUES (2, 7);
INSERT INTO "public"."access_actions" ("access_id", "action_id") VALUES (2, 12);
INSERT INTO "public"."access_actions" ("access_id", "action_id") VALUES (2, 3);
INSERT INTO "public"."access_actions" ("access_id", "action_id") VALUES (2, 6);
INSERT INTO "public"."access_actions" ("access_id", "action_id") VALUES (2, 9);
INSERT INTO "public"."access_actions" ("access_id", "action_id") VALUES (2, 8);
INSERT INTO "public"."access_actions" ("access_id", "action_id") VALUES (2, 5);
INSERT INTO "public"."access_actions" ("access_id", "action_id") VALUES (2, 2);
INSERT INTO "public"."access_actions" ("access_id", "action_id") VALUES (2, 1);
INSERT INTO "public"."access_actions" ("access_id", "action_id") VALUES (3, 7);
INSERT INTO "public"."access_actions" ("access_id", "action_id") VALUES (3, 10);
INSERT INTO "public"."access_actions" ("access_id", "action_id") VALUES (3, 4);
INSERT INTO "public"."access_actions" ("access_id", "action_id") VALUES (3, 1);
INSERT INTO "public"."access_actions" ("access_id", "action_id") VALUES (3, 12);
INSERT INTO "public"."access_actions" ("access_id", "action_id") VALUES (3, 6);
INSERT INTO "public"."access_actions" ("access_id", "action_id") VALUES (3, 3);
INSERT INTO "public"."access_actions" ("access_id", "action_id") VALUES (3, 9);
INSERT INTO "public"."access_actions" ("access_id", "action_id") VALUES (3, 8);
INSERT INTO "public"."access_actions" ("access_id", "action_id") VALUES (3, 5);
INSERT INTO "public"."access_actions" ("access_id", "action_id") VALUES (3, 2);
INSERT INTO "public"."access_actions" ("access_id", "action_id") VALUES (4, 7);
INSERT INTO "public"."access_actions" ("access_id", "action_id") VALUES (4, 5);
INSERT INTO "public"."access_actions" ("access_id", "action_id") VALUES (4, 6);
INSERT INTO "public"."access_actions" ("access_id", "action_id") VALUES (4, 12);
INSERT INTO "public"."access_actions" ("access_id", "action_id") VALUES (1, 15);
INSERT INTO "public"."access_actions" ("access_id", "action_id") VALUES (1, 12);
INSERT INTO "public"."access_actions" ("access_id", "action_id") VALUES (1, 11);
INSERT INTO "public"."access_actions" ("access_id", "action_id") VALUES (1, 10);
INSERT INTO "public"."access_actions" ("access_id", "action_id") VALUES (1, 9);
INSERT INTO "public"."access_actions" ("access_id", "action_id") VALUES (2, 11);
INSERT INTO "public"."access_actions" ("access_id", "action_id") VALUES (4, 8);
INSERT INTO "public"."access_actions" ("access_id", "action_id") VALUES (2, 4);
INSERT INTO "public"."access_actions" ("access_id", "action_id") VALUES (1, 14);
INSERT INTO "public"."access_actions" ("access_id", "action_id") VALUES (1, 16);
INSERT INTO "public"."access_actions" ("access_id", "action_id") VALUES (2, 16);
INSERT INTO "public"."access_actions" ("access_id", "action_id") VALUES (3, 11);


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

INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('79e86107173ce4a320768d5e3ef3778c', '2020-07-08 00:47:54.274326', 1002, 1, 18, '2020-07-08 00:47:54.274326', '2018-07-03');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('c6db4c9cbdb130669e2c8d59434d8bc4', '2020-07-08 00:47:54.274326', 996, 1, 9, '2020-07-08 00:47:54.274326', '2018-07-03');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('efafd285d1a97b77d088011480570bbb', '2020-07-08 00:47:54.406223', 987, 1, 34, '2020-07-08 00:47:54.406223', '2020-04-21');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('4c39a4892e8731b8591ce111b99816ad', '2020-07-08 00:47:54.406223', 978, 1, 17, '2020-07-08 00:47:54.406223', '2020-04-21');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('de1f24bfd088ed44b52133c16dea9a2c', '2020-07-08 00:47:54.406223', 976, 1, 14, '2020-07-08 00:47:54.406223', '2020-04-21');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('6881e3c8f412209611c1380365dced3b', '2020-07-08 00:47:54.544159', 993, 1, 1, '2020-07-08 00:47:54.544159', '2019-01-13');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('70db274329982ac2124acda343a9b59f', '2020-07-08 00:47:54.544159', 978, 1, 6, '2020-07-08 00:47:54.544159', '2019-01-13');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('44c7891c9aaac21cbb8d2bd94be74e56', '2020-07-08 00:47:54.544159', 1004, 1, 45, '2020-07-08 00:47:54.544159', '2019-01-13');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('e4fa6570b27c876670b4b25aceed6fe4', '2020-07-08 00:47:54.67741', 989, 1, 31, '2020-07-08 00:47:54.67741', '2018-04-04');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('8fd15efed1bbf04c4c0f943be47e7441', '2020-07-08 00:47:54.808366', 1001, 1, 23, '2020-07-08 00:47:54.808366', '2020-04-30');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('a30f8c51e8e58bf6aa584e6e696e43cd', '2020-07-08 00:47:54.808366', 971, 1, 8, '2020-07-08 00:47:54.808366', '2020-04-30');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('', '2020-01-02 15:37:30.168681', 0, 0, 0, '2020-03-18 16:07:51.03563', '1970-01-01');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('6cb0a7ec85bc7ef375954d87022b1fe5', '2020-07-08 00:47:54.808366', 982, 1, 22, '2020-07-08 00:47:54.808366', '2020-04-30');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('4e9ae7a9a8f5c295678229916124de5a', '2020-07-08 00:47:54.808366', 967, 1, 1, '2020-07-08 00:47:54.808366', '2020-04-30');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('78778f531e89f923e84c1584ab94b994', '2020-07-08 00:47:54.808366', 973, 1, 14, '2020-07-08 00:47:54.808366', '2020-04-30');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('63b76034db30e058518308d1e62a39bd', '2020-07-08 00:47:54.968037', 1005, 1, 1, '2020-07-08 00:47:54.968037', '2019-07-19');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('46f390fad15a4a975e486e0b1af29bb0', '2020-07-08 00:47:54.968037', 1001, 1, 55, '2020-07-08 00:47:54.968037', '2019-07-19');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('b7da63eba4815c11d06ae58ac4d489ca', '2020-07-08 00:47:54.968037', 981, 1, 7, '2020-07-08 00:47:54.968037', '2019-07-19');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('87a901fbda836f2597f0baabdd877bfe', '2020-07-08 00:47:55.104547', 981, 1, 26, '2020-07-08 00:47:55.104547', '2020-05-12');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('ae0d923bcf4c358e938662396ef17019', '2020-07-08 00:47:55.104547', 979, 1, 10, '2020-07-08 00:47:55.104547', '2020-05-12');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('da5307887c3b47e341803852fe63aef6', '2020-07-08 00:47:55.104547', 990, 1, 78, '2020-07-08 00:47:55.104547', '2020-05-12');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('2d8c820bdaad953f9f5da569f5f99ab5', '2020-07-08 00:47:55.104547', 1000, 1, 9, '2020-07-08 00:47:55.104547', '2020-05-12');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('3ca763c16bbb7886d65a5aa9892f8abd', '2020-07-08 00:47:55.104547', 976, 1, 14, '2020-07-08 00:47:55.104547', '2020-05-12');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('96f371c2c841b371e9f01b5ab6670db7', '2020-07-08 00:47:55.270964', 981, 1, 30, '2020-07-08 00:47:55.270964', '2019-06-02');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('cb8ce749ebb980b502bb2f3ec92741c9', '2020-07-08 00:47:55.270964', 985, 1, 59, '2020-07-08 00:47:55.270964', '2019-06-02');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('3d62fe92f73e2e12316c13aa6c9f1593', '2020-07-08 00:47:55.270964', 996, 1, 12, '2020-07-08 00:47:55.270964', '2019-06-02');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('7279c06cbe65d36cd394072d33ca0854', '2020-07-08 00:47:55.270964', 990, 1, 82, '2020-07-08 00:47:55.270964', '2019-06-02');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('574bf30944d7c42571f371bd70d6de49', '2020-07-08 00:47:55.270964', 1005, 1, 2, '2020-07-08 00:47:55.270964', '2019-06-02');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('4bdf10086039842b23ddb7cf1ce2b6bb', '2020-07-08 00:47:55.43461', 1004, 1, 45, '2020-07-08 00:47:55.43461', '2020-03-25');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('4261385d162079f70b0f89f01f7573b4', '2020-07-08 00:47:55.43461', 977, 1, 35, '2020-07-08 00:47:55.43461', '2020-03-25');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('7bbd05a127521904eec21f40e8b1c070', '2020-07-08 00:47:55.560977', 987, 1, 63, '2020-07-08 00:47:55.560977', '2020-05-09');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('3d302786fb04a60fa21357b24071442d', '2020-07-08 00:47:55.560977', 982, 1, 2, '2020-07-08 00:47:55.560977', '2020-05-09');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('d9a760826e458f86a705fb30988ce3d0', '2020-07-08 00:47:55.560977', 1002, 1, 17, '2020-07-08 00:47:55.560977', '2020-05-09');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('822eae7a756d2ccafbec8fcf48602fe4', '2020-07-02 15:43:48.617187', 24, 3, 50, '2020-07-02 15:43:48.617187', '2020-07-02');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('3cb8e6eb07a98719ed6b2a08bc25a945', '2020-07-08 00:47:55.560977', 967, 1, 49, '2020-07-08 00:47:55.560977', '2020-05-09');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('101dabac2f02ee47995065481e1a00b5', '2020-07-08 00:47:55.727208', 1001, 1, 23, '2020-07-08 00:47:55.727208', '2016-03-03');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('f198b3a705019e764e37c92a4c945fae', '2020-07-08 00:47:55.833647', 993, 1, 6, '2020-07-08 00:47:55.833647', '2019-03-30');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('10f3a38c4e801c8f87e47ba3316bb476', '2020-07-08 00:47:55.833647', 983, 1, 19, '2020-07-08 00:47:55.833647', '2019-03-30');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('820507aa839744da422acb37d04eaa1f', '2020-07-08 00:47:55.833647', 995, 1, 12, '2020-07-08 00:47:55.833647', '2019-03-30');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('5aee037debb6b6c879edab5e1904f88a', '2020-07-08 00:47:55.973228', 986, 1, 2, '2020-07-08 00:47:55.973228', '2019-09-18');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('61b1ec4dd3b521ccc1f427dded0c2655', '2020-07-08 00:47:55.973228', 994, 1, 11, '2020-07-08 00:47:55.973228', '2019-09-18');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('6f1fa4f14227982dc47a4ea0a1c00af2', '2020-07-08 00:47:55.973228', 991, 1, 105, '2020-07-08 00:47:55.973228', '2019-09-18');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('6abc32dcce505db5e8d2733ad5e21592', '2020-07-08 00:47:55.973228', 1002, 1, 20, '2020-07-08 00:47:55.973228', '2019-09-18');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('10e5d3b156429f98878acfbb17052123', '2020-07-08 00:47:55.973228', 972, 1, 4, '2020-07-08 00:47:55.973228', '2019-09-18');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('43420a787e9a7ec58c86be1298138168', '2020-07-08 00:47:56.136021', 1001, 1, 44, '2020-07-08 00:47:56.136021', '2019-01-14');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('b92445b73d5346c7afe2b8be73312d56', '2020-07-08 00:47:56.136021', 1003, 1, 10, '2020-07-08 00:47:56.136021', '2019-01-14');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('8b215644a2eac602082e53cd1c9a5967', '2020-07-08 00:47:56.136021', 984, 1, 15, '2020-07-08 00:47:56.136021', '2019-01-14');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('384f584fbafeeb7d7bac1445dcfde6d0', '2020-07-08 00:47:56.30337', 989, 1, 40, '2020-07-08 00:47:56.30337', '2020-06-10');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('caf89f0b2b78dd9090e812897f81e208', '2020-07-08 00:47:56.30337', 966, 1, 11, '2020-07-08 00:47:56.30337', '2020-06-10');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('698612a80baa8b54da873d81cc24af5e', '2020-07-08 00:47:56.456174', 979, 1, 20, '2020-07-08 00:47:56.456174', '2019-12-16');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('8633d2399b8c7faebe67f3b23aead8fb', '2020-07-08 00:47:56.456174', 982, 1, 20, '2020-07-08 00:47:56.456174', '2019-12-16');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('270325029997fb2c43d93db69b1b33be', '2020-07-08 00:47:56.456174', 976, 1, 12, '2020-07-08 00:47:56.456174', '2019-12-16');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('ce3fac7ec0b3eaa5defbfc9b013b19a0', '2020-07-08 00:47:56.456174', 969, 1, 1, '2020-07-08 00:47:56.456174', '2019-12-16');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('1ab7c8e50c099476705951bf57eb6aee', '2020-07-08 00:47:56.606657', 994, 1, 15, '2020-07-08 00:47:56.606657', '2020-04-10');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('48858e7b74fbfba8a8faf4b6c0177a72', '2020-07-08 00:47:56.606657', 971, 1, 6, '2020-07-08 00:47:56.606657', '2020-04-10');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('4631548f3d293cae30b5c4a44563aacb', '2020-07-08 00:47:56.606657', 992, 1, 5, '2020-07-08 00:47:56.606657', '2020-04-10');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('8b902cb7c1017fe77e7301a94289d618', '2020-07-08 00:47:56.606657', 970, 1, 28, '2020-07-08 00:47:56.606657', '2020-04-10');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('e08fc2cf32df940e0cbf665715a1fd96', '2020-07-08 00:47:56.606657', 999, 1, 52, '2020-07-08 00:47:56.606657', '2020-04-10');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('6281752c0b7266d9d4d9295ada44cbbe', '2020-07-08 00:47:56.606657', 976, 1, 21, '2020-07-08 00:47:56.606657', '2020-04-10');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('2d9a26be6f4a81b242430587a0699ab8', '2020-07-08 00:47:56.778216', 1005, 1, 1, '2020-07-08 00:47:56.778216', '2017-06-06');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('4f13b542d92fdfca7c774507d1b0c360', '2020-07-08 00:47:56.888336', 991, 1, 31, '2020-07-08 00:47:56.888336', '2020-07-04');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('0432072296062511f19bfa6f749cb4f1', '2020-07-08 00:47:56.888336', 998, 1, 16, '2020-07-08 00:47:56.888336', '2020-07-04');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('7866994e2f1957cbbfd1ca54efcef20b', '2020-07-08 00:47:56.888336', 972, 1, 4, '2020-07-08 00:47:56.888336', '2020-07-04');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('b78fc2c1ffe0806c624ad30d574ac6c5', '2020-07-08 00:47:56.888336', 968, 1, 29, '2020-07-08 00:47:56.888336', '2020-07-04');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('359ef8a7824c1bb8a1e8f02924c9578c', '2020-07-08 00:47:56.888336', 1001, 1, 33, '2020-07-08 00:47:56.888336', '2020-07-04');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('ac67e74d6a1333e8320d1339078ab26b', '2020-07-08 00:47:56.888336', 983, 1, 6, '2020-07-08 00:47:56.888336', '2020-07-04');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('4e6f7b706adb06f98b0c7b2721713c40', '2020-07-08 00:47:57.081394', 987, 1, 88, '2020-07-08 00:47:57.081394', '2020-05-15');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('844c3857ea0960a0c510ab8f62d7f0b5', '2020-07-08 00:47:57.081394', 967, 1, 33, '2020-07-08 00:47:57.081394', '2020-05-15');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('c9b27bfebe38e204d28bc3de75c0ab46', '2020-07-08 00:47:57.223159', 972, 1, 3, '2020-07-08 00:47:57.223159', '2019-08-15');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('d2b83c67ea1617cb204762c96e782b77', '2020-07-08 00:47:57.223159', 999, 1, 53, '2020-07-08 00:47:57.223159', '2019-08-15');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('9fba58ff47348a3675f1a47baa71a32b', '2020-07-08 00:47:57.223159', 978, 1, 1, '2020-07-08 00:47:57.223159', '2019-08-15');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('432365d18800017ef76cd945d631c177', '2020-07-08 00:47:57.223159', 973, 1, 20, '2020-07-08 00:47:57.223159', '2019-08-15');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('b61d6b14051084fe6fbbe66af0306c47', '2020-07-08 00:47:57.421481', 996, 1, 21, '2020-07-08 00:47:57.421481', '2019-09-30');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('fd4467554c3b3d90e09bb93a27b8572c', '2020-07-08 00:47:57.421481', 975, 1, 61, '2020-07-08 00:47:57.421481', '2019-09-30');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('dc7955476b390cbe2c0597895dffc447', '2020-07-08 00:47:57.421481', 985, 1, 46, '2020-07-08 00:47:57.421481', '2019-09-30');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('739f9f36975b76e72d2037dda6a85f7a', '2020-07-08 00:47:57.590234', 967, 1, 13, '2020-07-08 00:47:57.590234', '2020-06-11');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('3355ba69ae8a779a61b19b72472b4790', '2020-07-08 00:47:57.590234', 1005, 1, 1, '2020-07-08 00:47:57.590234', '2020-06-11');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('08de759a1a7d9ea194431395b514693d', '2020-07-08 00:47:57.711731', 972, 1, 4, '2020-07-08 00:47:57.711731', '2020-05-04');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('93d2eb4b5637f81f42aca0d2cbb06720', '2020-07-08 00:47:57.711731', 984, 1, 12, '2020-07-08 00:47:57.711731', '2020-05-04');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('a1cb089c3311eb1278002cd74a3c9afd', '2020-07-08 00:47:57.711731', 966, 1, 14, '2020-07-08 00:47:57.711731', '2020-05-04');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('5cc52f646ee591131f1f54afcb7ec73b', '2020-07-08 00:47:57.711731', 997, 1, 33, '2020-07-08 00:47:57.711731', '2020-05-04');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('830cef0858375587499d39446f70bd48', '2020-07-08 00:47:57.711731', 973, 1, 22, '2020-07-08 00:47:57.711731', '2020-05-04');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('a3fcbed3a86c9ac71aa5220b5868e5bd', '2020-07-08 00:47:57.711731', 992, 1, 4, '2020-07-08 00:47:57.711731', '2020-05-04');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('113a7698f0ffbcbbbe706de3fb4b38d4', '2020-07-08 00:47:57.880981', 980, 1, 34, '2020-07-08 00:47:57.880981', '2020-05-25');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('4d650fc4975d416706aab3e39b9caef9', '2020-07-08 00:47:57.880981', 990, 1, 11, '2020-07-08 00:47:57.880981', '2020-05-25');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('0ba6a6dcf54b5b4061db8fc61a74bb21', '2020-07-08 00:47:57.880981', 966, 1, 2, '2020-07-08 00:47:57.880981', '2020-05-25');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('8bab6c519e7173965f0e9a4e842b9839', '2020-07-08 00:47:57.880981', 1004, 1, 65, '2020-07-08 00:47:57.880981', '2020-05-25');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('764e8206bf748153f73aa70e78f6b583', '2020-07-08 00:47:57.880981', 974, 1, 29, '2020-07-08 00:47:57.880981', '2020-05-25');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('028d54cfa391090e25b9c231f647d248', '2020-07-08 00:47:58.035958', 979, 1, 7, '2020-07-08 00:47:58.035958', '2019-10-04');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('82c19e96bf7e636e6ec5b5a91ab3cd08', '2020-07-08 00:47:58.035958', 987, 1, 65, '2020-07-08 00:47:58.035958', '2019-10-04');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('f81520bf0997a38a59200fc8b83b9b7a', '2020-07-08 00:47:58.035958', 992, 1, 5, '2020-07-08 00:47:58.035958', '2019-10-04');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('45cc12f2d687844b2a29f038ffd4323e', '2020-07-08 00:47:58.035958', 1001, 1, 44, '2020-07-08 00:47:58.035958', '2019-10-04');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('739a589598197cde0bb9f542c3afa8ec', '2020-07-08 00:47:58.035958', 986, 1, 4, '2020-07-08 00:47:58.035958', '2019-10-04');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('a3618c7164311c810de1ff1b792596ec', '2020-07-08 00:47:58.035958', 970, 1, 29, '2020-07-08 00:47:58.035958', '2019-10-04');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('af4273c87f54afb7d3347ec20082eaca', '2020-07-08 00:47:58.203891', 974, 1, 9, '2020-07-08 00:47:58.203891', '2020-04-27');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('cdae52c4f94b1036beed588c1d938388', '2020-07-08 00:47:58.203891', 982, 1, 17, '2020-07-08 00:47:58.203891', '2020-04-27');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('961c1afbc72b16a6e605e0b24beb7c0c', '2020-07-08 00:47:58.203891', 966, 1, 18, '2020-07-08 00:47:58.203891', '2020-04-27');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('e505c4898600a9e31f18930036373e13', '2020-07-08 00:47:58.203891', 987, 1, 76, '2020-07-08 00:47:58.203891', '2020-04-27');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('79af00c09e37334742b4be0b1075b46a', '2020-07-08 00:47:58.203891', 979, 1, 1, '2020-07-08 00:47:58.203891', '2020-04-27');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('2f6758e517dafb93af26638bb6a16f3f', '2020-07-08 00:47:58.203891', 967, 1, 36, '2020-07-08 00:47:58.203891', '2020-04-27');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('cd044cab704cb4104bcaa3c751e6691b', '2020-07-08 00:47:58.382161', 990, 1, 107, '2020-07-08 00:47:58.382161', '2020-03-05');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('1de7f6aee323e41f5b6fc7c2a519971f', '2020-07-08 00:47:58.382161', 999, 1, 65, '2020-07-08 00:47:58.382161', '2020-03-05');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('18a146b66e3e7bedb0e23d2c34c714f0', '2020-07-08 00:47:58.382161', 971, 1, 4, '2020-07-08 00:47:58.382161', '2020-03-05');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('febee04c2e6389e89ca3d604ca875e35', '2020-07-08 00:47:58.382161', 994, 1, 14, '2020-07-08 00:47:58.382161', '2020-03-05');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('63af99fadaf71017bfa50f102b40f5e9', '2020-07-08 00:47:58.382161', 1004, 1, 28, '2020-07-08 00:47:58.382161', '2020-03-05');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('bc86d86dc93af21faae73160771e23a7', '2020-07-08 00:47:58.382161', 984, 1, 22, '2020-07-08 00:47:58.382161', '2020-03-05');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('ae21365aa4a970b3afbb8585c5396e82', '2020-07-08 00:47:58.581773', 992, 1, 6, '2020-07-08 00:47:58.581773', '2017-04-16');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('0db1da7118bc93564dd1f933e8984921', '2020-07-08 00:47:58.581773', 991, 1, 103, '2020-07-08 00:47:58.581773', '2017-04-16');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('a5678baa5332c0dc5540b879a7553fef', '2020-07-08 00:47:58.711954', 994, 1, 15, '2020-07-08 00:47:58.711954', '2017-11-26');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('9ce9e0b9bffa1f3a2fd36a3a5067e8c8', '2020-07-08 00:47:58.847439', 1003, 1, 4, '2020-07-08 00:47:58.847439', '2020-01-01');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('eb05374c27db0ec7f98f19eabd62aca5', '2020-07-08 00:47:58.847439', 1000, 1, 7, '2020-07-08 00:47:58.847439', '2020-01-01');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('ed1ed9fa66c72eddfc586d44981df7fe', '2020-07-08 00:47:58.847439', 978, 1, 20, '2020-07-08 00:47:58.847439', '2020-01-01');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('06af3f26743d7930ca99cea295685adb', '2020-07-08 00:47:58.847439', 974, 1, 40, '2020-07-08 00:47:58.847439', '2020-01-01');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('a27f3f52c4d14993e9051c5cdbea3b06', '2020-07-08 00:47:58.847439', 991, 1, 58, '2020-07-08 00:47:58.847439', '2020-01-01');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('c0c677ba59e8efd695ccea36d600bec4', '2020-07-08 00:47:58.847439', 994, 1, 15, '2020-07-08 00:47:58.847439', '2020-01-01');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('cb591c2d01e659ec9dc2a715f7f171ff', '2020-07-08 00:47:59.034002', 985, 1, 127, '2020-07-08 00:47:59.034002', '2020-02-07');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('4c7aa0b69d8460839242fea8d82e39d9', '2020-07-08 00:47:59.034002', 969, 1, 17, '2020-07-08 00:47:59.034002', '2020-02-07');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('3240f0e127d31172dde7fefe9a2578ae', '2020-07-08 00:47:59.034002', 975, 1, 42, '2020-07-08 00:47:59.034002', '2020-02-07');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('5fe5a75f77d6fee5ca1b5a94dc0f53d2', '2020-07-08 00:47:59.188317', 1000, 1, 8, '2020-07-08 00:47:59.188317', '2017-05-20');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('4a3492907b48d54d62e8e33d78545e52', '2020-07-08 00:47:59.299811', 966, 1, 3, '2020-07-08 00:47:59.299811', '2020-04-21');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('ee31e4c2271f581d17aec3224e455f78', '2020-07-08 00:47:59.299811', 969, 1, 50, '2020-07-08 00:47:59.299811', '2020-04-21');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('6d774b9413594b6b4501bd2881c6f7d3', '2020-07-08 00:47:59.299811', 989, 1, 28, '2020-07-08 00:47:59.299811', '2020-04-21');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('4c0e0724e29d2f6455c8510191b4132a', '2020-07-08 00:47:59.299811', 980, 1, 48, '2020-07-08 00:47:59.299811', '2020-04-21');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('95edea8fd73960cea72333c769312c02', '2020-07-08 00:47:59.435947', 984, 1, 23, '2020-07-08 00:47:59.435947', '2020-02-08');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('2e3f91568d557ea4fcab2e6ef4135031', '2020-07-08 00:47:59.435947', 972, 1, 1, '2020-07-08 00:47:59.435947', '2020-02-08');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('ff90a1a65d215a2440b8cce01234e1ad', '2020-07-08 00:47:59.435947', 998, 1, 26, '2020-07-08 00:47:59.435947', '2020-02-08');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('f3b52255533ad4efcc55839783f3f138', '2020-07-08 00:47:59.569975', 995, 1, 12, '2020-07-08 00:47:59.569975', '2016-04-16');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('56c0885f48a3af4754f1b0aa9b3cd250', '2020-07-08 00:47:59.683683', 984, 1, 26, '2020-07-08 00:47:59.683683', '2020-04-06');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('289c7a39b3fc97baed1a733eaf3b05b1', '2020-07-08 00:47:59.683683', 980, 1, 49, '2020-07-08 00:47:59.683683', '2020-04-06');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('d594cbda0c4828996437b4af30bdc8cc', '2020-07-08 00:47:59.80773', 990, 1, 77, '2020-07-08 00:47:59.80773', '2019-09-17');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('7b2d61b50b88945c081d29dcd9bf2761', '2020-07-08 00:47:59.919741', 996, 1, 12, '2020-07-08 00:47:59.919741', '2020-04-14');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('1c06b0532a2f9abbdbcc70d0e21aec82', '2020-07-08 00:48:00.04482', 970, 1, 14, '2020-07-08 00:48:00.04482', '2020-01-16');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('41ec97d62893c4ac5630d7ca833eeb32', '2020-07-08 00:48:00.155641', 975, 1, 79, '2020-07-08 00:48:00.155641', '2020-03-23');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('57f07e539554a6db095fa17686c7fc27', '2020-07-08 00:48:00.269001', 982, 1, 9, '2020-07-08 00:48:00.269001', '2018-12-19');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('f4f2dac088f4d7ca8f8c565906b3bb44', '2020-07-08 00:48:00.269001', 978, 1, 4, '2020-07-08 00:48:00.269001', '2018-12-19');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('02ca05acc31d7ba9c474b9bb5799b06b', '2020-07-08 00:48:00.269001', 986, 1, 3, '2020-07-08 00:48:00.269001', '2018-12-19');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('b2e4796bf865526675b7a38089452585', '2020-07-08 00:48:00.269001', 983, 1, 9, '2020-07-08 00:48:00.269001', '2018-12-19');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('9fd80d3a54b3b8715c79f82ae8946cd7', '2020-07-08 00:48:00.269001', 1001, 1, 50, '2020-07-08 00:48:00.269001', '2018-12-19');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('727d94f0237c987098b935ab80eb051b', '2020-07-08 00:48:00.447783', 984, 1, 5, '2020-07-08 00:48:00.447783', '2020-03-19');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('e3bef5818d39905a1333ca08e1ed5ff3', '2020-07-08 00:48:00.447783', 970, 1, 35, '2020-07-08 00:48:00.447783', '2020-03-19');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('a5a1fae932f46b0559a2f8d66948882b', '2020-07-08 00:48:00.447783', 966, 1, 5, '2020-07-08 00:48:00.447783', '2020-03-19');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('cb4329b58d0a93049b2642c37bbc17ea', '2020-07-08 00:48:00.579754', 1000, 1, 6, '2020-07-08 00:48:00.579754', '2020-03-17');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('cd7dad4b805550afad307d5e7565b7f0', '2020-07-08 00:48:00.579754', 969, 1, 50, '2020-07-08 00:48:00.579754', '2020-03-17');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('4155f975110c5fb3e23f28cd171e5b10', '2020-07-08 00:48:00.579754', 977, 1, 14, '2020-07-08 00:48:00.579754', '2020-03-17');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('e153f471c8051eb218bdc6d3d1f313f2', '2020-07-08 00:48:00.579754', 983, 1, 22, '2020-07-08 00:48:00.579754', '2020-03-17');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('9edc75c260db3ff0df27364e7a47b6bf', '2020-07-08 00:48:00.739199', 999, 1, 7, '2020-07-08 00:48:00.739199', '2020-04-27');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('9f0b189827aa134972909cf66903bf88', '2020-07-08 00:48:00.739199', 997, 1, 23, '2020-07-08 00:48:00.739199', '2020-04-27');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('41634912120b4833d999797f86b1bc40', '2020-07-08 00:48:00.739199', 966, 1, 12, '2020-07-08 00:48:00.739199', '2020-04-27');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('fbcdbc73065d5981bfa9ab189a53fb54', '2020-07-08 00:48:00.739199', 973, 1, 22, '2020-07-08 00:48:00.739199', '2020-04-27');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('48f15820af62ce9baaff82af2ec74122', '2020-07-08 00:48:00.895624', 974, 1, 52, '2020-07-08 00:48:00.895624', '2020-03-21');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('3a90472f254822c90ca85cb0bcae0267', '2020-07-08 00:48:00.895624', 998, 1, 15, '2020-07-08 00:48:00.895624', '2020-03-21');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('180d6aba9da7f4bcaa7ad9d2975cd2e1', '2020-07-08 00:48:00.895624', 994, 1, 17, '2020-07-08 00:48:00.895624', '2020-03-21');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('9247d851b2f61e9f230c1b89ea8ca67b', '2020-07-08 00:48:00.895624', 966, 1, 16, '2020-07-08 00:48:00.895624', '2020-03-21');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('3596b294aafcfcd5e3e2310ee7981e41', '2020-07-08 00:48:00.895624', 999, 1, 4, '2020-07-08 00:48:00.895624', '2020-03-21');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('dc4091bd41109b5a45b43e35f49006c5', '2020-07-08 00:48:01.057806', 991, 1, 33, '2020-07-08 00:48:01.057806', '2018-06-16');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('81aaa92f000270e87d32dee6cc845043', '2020-07-08 00:48:01.171464', 999, 1, 57, '2020-07-08 00:48:01.171464', '2020-03-12');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('488f7863c9f991ac01606220ab099706', '2020-07-08 00:48:01.171464', 969, 1, 37, '2020-07-08 00:48:01.171464', '2020-03-12');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('6d261a84c77e17962c9a2588b27520b0', '2020-07-08 00:48:01.171464', 984, 1, 12, '2020-07-08 00:48:01.171464', '2020-03-12');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('d4cd91be62638a8acdca7fd2d0b340f4', '2020-07-08 00:48:01.301705', 979, 1, 33, '2020-07-08 00:48:01.301705', '2020-03-27');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('a01fbcd22a9de3b178d7c0b09fdd9b96', '2020-07-08 00:48:01.301705', 1000, 1, 1, '2020-07-08 00:48:01.301705', '2020-03-27');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('4543f7139d65093dbb05abfeb0e43bf5', '2020-07-08 00:48:01.301705', 990, 1, 37, '2020-07-08 00:48:01.301705', '2020-03-27');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('7562aff2ee3224884bbbea38f55e74c6', '2020-07-08 00:48:01.301705', 966, 1, 14, '2020-07-08 00:48:01.301705', '2020-03-27');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('dce27ca7fe5d752aae23fb7638d967a8', '2020-07-08 00:48:01.301705', 996, 1, 8, '2020-07-08 00:48:01.301705', '2020-03-27');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('289de5f557b3a25627670c473e40fab2', '2020-07-08 00:48:01.464829', 975, 1, 25, '2020-07-08 00:48:01.464829', '2020-05-11');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('04b98bf9b83c27856b4f6c34949ed136', '2020-07-08 00:48:01.464829', 987, 1, 78, '2020-07-08 00:48:01.464829', '2020-05-11');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('632415e527568f53d48305240a40a09c', '2020-07-08 00:48:01.464829', 989, 1, 20, '2020-07-08 00:48:01.464829', '2020-05-11');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('898f5299ae1819d054a82b0621aae72a', '2020-07-08 00:48:01.606054', 966, 1, 15, '2020-07-08 00:48:01.606054', '2020-04-14');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('c30714cfd8131043e64c4d362af256c3', '2020-07-08 00:48:01.606054', 978, 1, 1, '2020-07-08 00:48:01.606054', '2020-04-14');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('9551ce357286d8eb259201321aabf5ea', '2020-07-08 00:48:01.606054', 984, 1, 12, '2020-07-08 00:48:01.606054', '2020-04-14');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('26546eb3379e7243c60b14580178ceb9', '2020-07-08 00:48:01.791008', 967, 1, 62, '2020-07-08 00:48:01.791008', '2020-06-12');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('ddc2bc3ecd53204f27cacf0840735297', '2020-07-08 00:48:01.791008', 983, 1, 42, '2020-07-08 00:48:01.791008', '2020-06-12');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('1edaef8aaa30bab19b871282232cbf2e', '2020-07-08 00:48:01.791008', 991, 1, 76, '2020-07-08 00:48:01.791008', '2020-06-12');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('271167e689ceddfc7b85d3a6e7a7fd9a', '2020-07-08 00:48:01.791008', 997, 1, 30, '2020-07-08 00:48:01.791008', '2020-06-12');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('00a89ed5ee94a61f5d54b2a5ff654bf3', '2020-07-08 00:48:01.948842', 971, 1, 2, '2020-07-08 00:48:01.948842', '2020-02-02');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('fbccf338aa2e1827324af224e3fcb169', '2020-07-08 00:48:01.948842', 1003, 1, 10, '2020-07-08 00:48:01.948842', '2020-02-02');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('d7dfdd3d2a358f10280321ea416d1e93', '2020-07-08 00:48:02.068081', 969, 1, 28, '2020-07-08 00:48:02.068081', '2020-03-15');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('981df914e4bd2c9babd3a6c078b8fc03', '2020-07-08 00:48:02.068081', 989, 1, 78, '2020-07-08 00:48:02.068081', '2020-03-15');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('e30e9d6bc35f94d3dc3fade7653a4769', '2020-07-08 00:48:02.068081', 978, 1, 12, '2020-07-08 00:48:02.068081', '2020-03-15');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('20f7d1be226a786c7b0e0c5672930421', '2020-07-08 00:48:02.068081', 975, 1, 42, '2020-07-08 00:48:02.068081', '2020-03-15');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('20aa3d811d560c45a26cdb86569cf0af', '2020-07-08 00:48:02.068081', 986, 1, 2, '2020-07-08 00:48:02.068081', '2020-03-15');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('a2e66f65c16dabaf12442390a26e0b27', '2020-07-08 00:48:02.068081', 1001, 1, 17, '2020-07-08 00:48:02.068081', '2020-03-15');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('32f64d85f23ade91ce9d05ee4410dfaf', '2020-07-08 00:48:02.251826', 968, 1, 3, '2020-07-08 00:48:02.251826', '2020-07-04');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('51b97f6572f1cdfce6fdadb7996d2c49', '2020-07-08 00:48:02.251826', 998, 1, 27, '2020-07-08 00:48:02.251826', '2020-07-04');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('04189b840fe85c5d3cdaed2a9107e6dc', '2020-07-08 00:48:02.368485', 995, 1, 11, '2020-07-08 00:48:02.368485', '2018-11-02');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('3242f5e9ad613e05696976a245e0f127', '2020-07-08 00:48:02.368485', 987, 1, 30, '2020-07-08 00:48:02.368485', '2018-11-02');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('3282834341e52455b375f3c9a9070a97', '2020-07-08 00:48:02.368485', 1001, 1, 50, '2020-07-08 00:48:02.368485', '2018-11-02');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('bc1cb1fef73832e1b96aaabae1394415', '2020-07-08 00:48:02.368485', 992, 1, 3, '2020-07-08 00:48:02.368485', '2018-11-02');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('b5ce116acbf072ab3a0217938e958a25', '2020-07-08 00:48:02.368485', 985, 1, 69, '2020-07-08 00:48:02.368485', '2018-11-02');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('6b52a4dbfd1880dac0f4769eda63c60c', '2020-07-08 00:48:02.368485', 984, 1, 20, '2020-07-08 00:48:02.368485', '2018-11-02');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('f01ef170a17a609db632f4ea67e9798f', '2020-07-08 00:48:02.537331', 995, 1, 16, '2020-07-08 00:48:02.537331', '2017-03-20');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('b65050219daa5c08627428241f8ef8d3', '2020-07-08 00:48:02.645109', 971, 1, 1, '2020-07-08 00:48:02.645109', '2020-05-05');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('8cd54b592ee9102a9bc71bbf0af37e23', '2020-07-08 00:48:02.645109', 993, 1, 2, '2020-07-08 00:48:02.645109', '2020-05-05');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('8ba03da03a07bb6f632e41dcd124c9c8', '2020-07-08 00:48:02.774032', 999, 1, 33, '2020-07-08 00:48:02.774032', '2020-07-05');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('9706494ba9fc4834c1ef1dc185267d7b', '2020-07-08 00:48:02.774032', 968, 1, 25, '2020-07-08 00:48:02.774032', '2020-07-05');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('946260fe98b18db25486f6048ab059a1', '2020-07-08 00:48:02.774032', 978, 1, 8, '2020-07-08 00:48:02.774032', '2020-07-05');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('53d875efc8903eb263e6024224449a1a', '2020-07-08 00:48:02.774032', 993, 1, 5, '2020-07-08 00:48:02.774032', '2020-07-05');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('b075d3ee1a7955d95500f88403c12b90', '2020-07-08 00:48:02.774032', 979, 1, 36, '2020-07-08 00:48:02.774032', '2020-07-05');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('f9568f6acb4de29f2339ffbf14ed08c2', '2020-07-08 00:48:02.944406', 1004, 1, 10, '2020-07-08 00:48:02.944406', '2020-06-10');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('226b681d71d210afc9f97fc1eb0c0559', '2020-07-08 00:48:02.944406', 966, 1, 2, '2020-07-08 00:48:02.944406', '2020-06-10');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('5bf37f2078afa99b3e1e2294be85fb2c', '2020-07-08 00:48:02.944406', 1005, 1, 1, '2020-07-08 00:48:02.944406', '2020-06-10');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('9d05bd5b494d798c011038a70f5a9f55', '2020-07-08 00:48:02.944406', 969, 1, 5, '2020-07-08 00:48:02.944406', '2020-06-10');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('06aa5df674dad4587fbd21b6a99ce740', '2020-07-08 00:48:02.944406', 984, 1, 5, '2020-07-08 00:48:02.944406', '2020-06-10');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('73a5d9e8732b848e912dfcc76b5cb2de', '2020-07-08 00:48:02.944406', 983, 1, 10, '2020-07-08 00:48:02.944406', '2020-06-10');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('9c1a161c90ea5a2b05a8aad92fc05e7d', '2020-07-08 00:48:03.1447', 995, 1, 3, '2020-07-08 00:48:03.1447', '2019-08-31');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('e5a18532b3c29c4d8d51841e7b6f07a0', '2020-07-08 00:48:03.1447', 972, 1, 1, '2020-07-08 00:48:03.1447', '2019-08-31');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('02341231363d688ab55ba51492eae968', '2020-07-08 00:48:03.1447', 988, 1, 39, '2020-07-08 00:48:03.1447', '2019-08-31');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('4f0dce0b0dbadbb7d9fe066bc7151ecf', '2020-07-08 00:48:03.1447', 989, 1, 60, '2020-07-08 00:48:03.1447', '2019-08-31');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('95151bbe92a22a5fa904023cebcece82', '2020-07-08 00:48:03.1447', 974, 1, 46, '2020-07-08 00:48:03.1447', '2019-08-31');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('ee6767a0b8072e35e96480c440cf13ee', '2020-07-08 00:48:03.322316', 994, 1, 5, '2020-07-08 00:48:03.322316', '2018-03-13');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('ee05429b3e10831ffb1b1e61be390a6e', '2020-07-08 00:48:03.423045', 993, 1, 2, '2020-07-08 00:48:03.423045', '2019-08-30');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('42922ba44dcabee0401681a3c7a6f7ee', '2020-07-08 00:48:03.550785', 966, 1, 3, '2020-07-08 00:48:03.550785', '2020-06-28');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('bddde09ade1b6f7b8f707a3de0b4cc48', '2020-07-08 00:48:03.550785', 969, 1, 34, '2020-07-08 00:48:03.550785', '2020-06-28');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('0bfb1e13ab8f5affcad6ea0c54923a66', '2020-07-08 00:48:03.550785', 982, 1, 19, '2020-07-08 00:48:03.550785', '2020-06-28');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('cb49d789a07e377f9d88f3abc52bc0f0', '2020-07-08 00:48:03.550785', 1000, 1, 7, '2020-07-08 00:48:03.550785', '2020-06-28');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('5beb9242da862eccfd41e7e2b2e19f11', '2020-07-08 00:48:03.550785', 987, 1, 87, '2020-07-08 00:48:03.550785', '2020-06-28');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('91931928c05e40c73a7964c72b634742', '2020-07-08 00:48:03.736283', 968, 1, 33, '2020-07-08 00:48:03.736283', '2020-07-04');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('718d615442322b94e122ba31422606c1', '2020-07-08 00:48:03.736283', 998, 1, 29, '2020-07-08 00:48:03.736283', '2020-07-04');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('aa5b3e404462a56640e976a07143f48c', '2020-07-08 00:48:03.881054', 976, 1, 2, '2020-07-08 00:48:03.881054', '2020-06-10');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('c83a88f5f52d10ff217656d4e4ec6651', '2020-07-08 00:48:03.881054', 971, 1, 5, '2020-07-08 00:48:03.881054', '2020-06-10');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('7212660174c057e27a1e019eefcef6c4', '2020-07-08 00:48:03.881054', 989, 1, 23, '2020-07-08 00:48:03.881054', '2020-06-10');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('5c54dd16ea30493a9b78b376d53d181f', '2020-07-08 00:48:04.416954', 987, 1, 113, '2020-07-08 00:48:04.416954', '2019-12-07');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('f032a26837fd8c340846f0eeff59d459', '2020-07-08 00:48:04.416954', 989, 1, 51, '2020-07-08 00:48:04.416954', '2019-12-07');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('94bdce8b9639854e5257c5ed8743dd71', '2020-07-08 00:48:04.416954', 994, 1, 9, '2020-07-08 00:48:04.416954', '2019-12-07');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('e281918e5f358b399f4dce33c65ed500', '2020-07-08 00:48:04.416954', 969, 1, 13, '2020-07-08 00:48:04.416954', '2019-12-07');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('e26010825638f36549f83c2d6f87fa54', '2020-07-08 00:48:04.416954', 1004, 1, 19, '2020-07-08 00:48:04.416954', '2019-12-07');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('299ed923585c334013f2a543bbbc6241', '2020-07-08 00:48:04.589165', 981, 1, 34, '2020-07-08 00:48:04.589165', '2020-07-04');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('1a42ca9b376bd74b390fa77ab8235a01', '2020-07-08 00:48:04.589165', 968, 1, 39, '2020-07-08 00:48:04.589165', '2020-07-04');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('6a186c8adfe1f8b75a6e9363f58c0e41', '2020-07-08 00:48:04.589165', 995, 1, 22, '2020-07-08 00:48:04.589165', '2020-07-04');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('2980ce6875e77ecc01b4e4d93f65df98', '2020-07-08 00:48:04.589165', 973, 1, 5, '2020-07-08 00:48:04.589165', '2020-07-04');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('ae81b9e5e25654153eb043a863ec17c0', '2020-07-08 00:48:04.589165', 993, 1, 9, '2020-07-08 00:48:04.589165', '2020-07-04');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('921fc3ca9f40b6e9bbe047b01d2726eb', '2020-07-08 00:48:04.589165', 1004, 1, 23, '2020-07-08 00:48:04.589165', '2020-07-04');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('487d7c719f9525494628c75f3ab5b6a7', '2020-07-08 00:48:04.759906', 981, 1, 5, '2020-07-08 00:48:04.759906', '2019-12-19');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('ff382a711fd33170c429d31d2b189346', '2020-07-08 00:48:04.759906', 993, 1, 5, '2020-07-08 00:48:04.759906', '2019-12-19');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('585ddf537b9d617a080022381574ff66', '2020-07-08 00:48:04.759906', 978, 1, 3, '2020-07-08 00:48:04.759906', '2019-12-19');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('e83bb3e770769d30ee76014bd4f8b11f', '2020-07-08 00:48:04.759906', 1000, 1, 2, '2020-07-08 00:48:04.759906', '2019-12-19');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('63b073e42ae588e45451d33f6a909652', '2020-07-08 00:48:04.759906', 973, 1, 22, '2020-07-08 00:48:04.759906', '2019-12-19');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('e812330e8d13e2ff82fe28fe4cc02f22', '2020-07-08 00:48:04.759906', 987, 1, 87, '2020-07-08 00:48:04.759906', '2019-12-19');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('6ac682d93dd1c9190eb919dc1fd1f45b', '2020-07-08 00:48:04.938102', 968, 1, 1, '2020-07-08 00:48:04.938102', '2020-07-05');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('963a3df02a3e90208d14fa2f95edbdee', '2020-07-08 00:48:04.938102', 990, 1, 73, '2020-07-08 00:48:04.938102', '2020-07-05');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('e7e775ef70911da4ae773d8dbc67663a', '2020-07-08 00:48:04.938102', 988, 1, 38, '2020-07-08 00:48:04.938102', '2020-07-05');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('9213cbbdb379878411f602c1e4190ab7', '2020-07-08 00:48:04.938102', 980, 1, 1, '2020-07-08 00:48:04.938102', '2020-07-05');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('ae25fa58a7cce3ec5cd40271ece61f51', '2020-07-08 00:48:04.938102', 997, 1, 18, '2020-07-08 00:48:04.938102', '2020-07-05');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('efab7dd8411a5c076379840c1e37fe37', '2020-07-08 00:48:04.938102', 1000, 1, 6, '2020-07-08 00:48:04.938102', '2020-07-05');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('d6d61b6f57cc7b6b5c1ec815ff1891dd', '2020-07-08 00:48:05.124469', 978, 1, 4, '2020-07-08 00:48:05.124469', '2020-04-06');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('05d1196ab2819cb8a83f3b5b022570ef', '2020-07-08 00:48:05.124469', 969, 1, 25, '2020-07-08 00:48:05.124469', '2020-04-06');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('cc3dc2b1aa8bc11043d361c2b499a965', '2020-07-08 00:48:05.124469', 998, 1, 54, '2020-07-08 00:48:05.124469', '2020-04-06');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('3010767caf9387be8952482cf3ac9029', '2020-07-08 00:48:05.124469', 991, 1, 26, '2020-07-08 00:48:05.124469', '2020-04-06');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('8f028188f913370ca5cafdf619e8d103', '2020-07-08 00:48:05.124469', 986, 1, 4, '2020-07-08 00:48:05.124469', '2020-04-06');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('84871f502e98e21ba16bfe37e19249cf', '2020-07-08 00:48:05.296984', 972, 1, 4, '2020-07-08 00:48:05.296984', '2020-03-16');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('8a635b0e8ce8195dd768ac7234008d61', '2020-07-08 00:48:05.40111', 995, 1, 19, '2020-07-08 00:48:05.40111', '2020-07-04');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('1703f5dfa2eb12bdab21b162622b4a30', '2020-07-08 00:48:05.40111', 968, 1, 29, '2020-07-08 00:48:05.40111', '2020-07-04');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('6a3312f68bc9d91c5d506073bdb29267', '2020-07-08 00:48:05.40111', 987, 1, 108, '2020-07-08 00:48:05.40111', '2020-07-04');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('792f7ca741635c87cdceb7ecb5f21df1', '2020-07-08 00:48:05.558412', 1005, 1, 1, '2020-07-08 00:48:05.558412', '2019-05-03');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('267c0513baedcbb76a4ed324e75675d5', '2020-07-08 00:48:05.558412', 979, 1, 27, '2020-07-08 00:48:05.558412', '2019-05-03');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('bd45cabbf7ed66dba0d99acf496404e5', '2020-07-08 00:48:05.684172', 991, 1, 7, '2020-07-08 00:48:05.684172', '2020-05-26');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('8c85e37eb2a8d4a5ff8456d47b39d5dc', '2020-07-08 00:48:05.684172', 966, 1, 8, '2020-07-08 00:48:05.684172', '2020-05-26');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('979a9d431248bda10753704a7d87391d', '2020-07-08 00:48:05.684172', 1002, 1, 29, '2020-07-08 00:48:05.684172', '2020-05-26');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('69a15aa6567ee8b036acf15f8694b2ee', '2020-07-08 00:48:05.684172', 988, 1, 6, '2020-07-08 00:48:05.684172', '2020-05-26');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('a98b52b401b8987e7824f5b74cfbc589', '2020-07-08 00:48:05.825648', 988, 1, 41, '2020-07-08 00:48:05.825648', '2020-02-07');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('9fac3d87b62e9e4124f41b913dd31436', '2020-07-08 00:48:05.825648', 996, 1, 21, '2020-07-08 00:48:05.825648', '2020-02-07');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('162ed9e219ef9b104fad4d2ce1419f32', '2020-07-08 00:48:05.946423', 987, 1, 77, '2020-07-08 00:48:05.946423', '2019-08-26');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('7df923e58e2a752351a4efb787cca045', '2020-07-08 00:48:05.946423', 975, 1, 57, '2020-07-08 00:48:05.946423', '2019-08-26');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('fd4946431435363c3b69ba94707528bb', '2020-07-08 00:48:05.946423', 1003, 1, 9, '2020-07-08 00:48:05.946423', '2019-08-26');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('26c1d0027cd792c6cf961a888e65c048', '2020-07-08 00:48:06.086588', 984, 1, 4, '2020-07-08 00:48:06.086588', '2020-01-26');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('40269695fc620ff26f2822f06b832bd4', '2020-07-08 00:48:06.212936', 969, 1, 54, '2020-07-08 00:48:06.212936', '2019-12-06');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('4fdec4084bbb422abdbeb69f501c54a4', '2020-07-08 00:48:06.212936', 1000, 1, 5, '2020-07-08 00:48:06.212936', '2019-12-06');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('7fd505d1169f008fc345c6484bf50f5f', '2020-07-08 00:48:06.212936', 997, 1, 11, '2020-07-08 00:48:06.212936', '2019-12-06');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('4dc80730777100b6fd9ece03f514ca46', '2020-07-08 00:48:06.212936', 985, 1, 102, '2020-07-08 00:48:06.212936', '2019-12-06');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('697858b5ce151ece6da24775656bcbe1', '2020-07-08 00:48:06.212936', 1002, 1, 2, '2020-07-08 00:48:06.212936', '2019-12-06');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('f677e3b7f61ce1a274e8434d881d0e7e', '2020-07-08 00:48:06.212936', 989, 1, 4, '2020-07-08 00:48:06.212936', '2019-12-06');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('559bf2a0812dea6a2092c3259f90d8e1', '2020-07-08 00:48:06.379637', 985, 1, 47, '2020-07-08 00:48:06.379637', '2020-06-08');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('ef0cfd6f7f97a1c8ae4d3eef503d99d1', '2020-07-08 00:48:06.379637', 975, 1, 5, '2020-07-08 00:48:06.379637', '2020-06-08');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('3822e15e4d219a7b17a1b206ea280d90', '2020-07-08 00:48:06.519828', 1003, 1, 9, '2020-07-08 00:48:06.519828', '2019-11-26');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('b48369ff42249702814d0dea915dee09', '2020-07-08 00:48:06.519828', 973, 1, 20, '2020-07-08 00:48:06.519828', '2019-11-26');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('b6e986aca8c8cd8a217d073df54e796a', '2020-07-08 00:48:06.519828', 991, 1, 79, '2020-07-08 00:48:06.519828', '2019-11-26');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('d9c8d3ae6be79e5b5a4e3509753f3771', '2020-07-08 00:48:06.519828', 985, 1, 49, '2020-07-08 00:48:06.519828', '2019-11-26');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('88f1df8dab6d7c0913567896c8e9dfe0', '2020-07-08 00:48:06.519828', 975, 1, 74, '2020-07-08 00:48:06.519828', '2019-11-26');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('446be551eaf10ac54315c1015be6b831', '2020-07-08 00:48:06.519828', 976, 1, 3, '2020-07-08 00:48:06.519828', '2019-11-26');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('d1fd459c008ca0f985a571b401eaf3c9', '2020-07-08 00:48:06.700436', 984, 1, 16, '2020-07-08 00:48:06.700436', '2018-12-12');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('3a6d6b0e4d0ed0219500faa2856f70a7', '2020-07-08 00:48:06.830164', 967, 1, 24, '2020-07-08 00:48:06.830164', '2020-03-12');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('c056ad7afa2cadc91efd9cac221fb62f', '2020-07-08 00:48:06.830164', 986, 1, 4, '2020-07-08 00:48:06.830164', '2020-03-12');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('f46b066cf0702a999cc7e0234ea825f4', '2020-07-08 00:48:06.830164', 987, 1, 85, '2020-07-08 00:48:06.830164', '2020-03-12');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('2ba455e86ccfaa2675db69ca49d6089a', '2020-07-08 00:48:06.830164', 983, 1, 1, '2020-07-08 00:48:06.830164', '2020-03-12');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('c92ae69da340892055ed03e383d9d313', '2020-07-08 00:48:06.830164', 1000, 1, 8, '2020-07-08 00:48:06.830164', '2020-03-12');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('d8c8de2660611b77f41252370a180977', '2020-07-08 00:48:06.830164', 973, 1, 5, '2020-07-08 00:48:06.830164', '2020-03-12');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('05b3eac309746b0d9eb39c365d9724a7', '2020-07-08 00:48:07.027582', 969, 1, 47, '2020-07-08 00:48:07.027582', '2020-02-07');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('ae25f35618efce8fab8de7abc78613a8', '2020-07-08 00:48:07.027582', 999, 1, 55, '2020-07-08 00:48:07.027582', '2020-02-07');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('a8566a087c0b367ccad3b3ac0aafc86f', '2020-07-08 00:48:07.027582', 994, 1, 10, '2020-07-08 00:48:07.027582', '2020-02-07');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('eb76b193cf8b9d05f1547368e7d702a7', '2020-07-08 00:48:07.027582', 997, 1, 23, '2020-07-08 00:48:07.027582', '2020-02-07');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('214f7d737433089efa2ea2d4f30d684d', '2020-07-08 00:48:07.027582', 990, 1, 99, '2020-07-08 00:48:07.027582', '2020-02-07');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('8ab0002fc0a117ad9334e96f974f08a6', '2020-07-08 00:48:07.181708', 993, 1, 5, '2020-07-08 00:48:07.181708', '2020-04-21');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('a4bc1bd8ce6cd6066dc71a264257597b', '2020-07-08 00:48:07.181708', 977, 1, 18, '2020-07-08 00:48:07.181708', '2020-04-21');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('eeffbdf8a4b83233c966116c2276327b', '2020-07-08 00:48:07.181708', 967, 1, 25, '2020-07-08 00:48:07.181708', '2020-04-21');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('d0fdcae8bed564b407896bf2129e3832', '2020-07-08 00:48:07.181708', 985, 1, 135, '2020-07-08 00:48:07.181708', '2020-04-21');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('ea218dc694c7be4e24aa1949dea5d26c', '2020-07-08 00:48:07.334291', 993, 1, 6, '2020-07-08 00:48:07.334291', '2019-10-21');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('e9d3cfc06d1ed598e519ba4cee492e4c', '2020-07-08 00:48:07.334291', 975, 1, 51, '2020-07-08 00:48:07.334291', '2019-10-21');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('50893c8b09ed60bedf7850cbabb82453', '2020-07-08 00:48:07.334291', 990, 1, 24, '2020-07-08 00:48:07.334291', '2019-10-21');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('a2487e3996eb8c83c0cea4b4de65c774', '2020-07-08 00:48:07.475559', 969, 1, 5, '2020-07-08 00:48:07.475559', '2020-03-15');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('497f9259127db6b94f41e39f7a55e971', '2020-07-08 00:48:07.475559', 972, 1, 2, '2020-07-08 00:48:07.475559', '2020-03-15');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('9e5e50b2775a894680fb82085aad1d67', '2020-07-08 00:48:07.591021', 994, 1, 7, '2020-07-08 00:48:07.591021', '2020-06-27');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('94ea5d608db5139a018e7c5571c0553e', '2020-07-08 00:48:07.591021', 996, 1, 11, '2020-07-08 00:48:07.591021', '2020-06-27');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('c772175ac5792e0c0f3cf5040edcfccc', '2020-07-08 00:48:07.591021', 990, 1, 72, '2020-07-08 00:48:07.591021', '2020-06-27');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('c011ac9b9255d64f4d77828bb4ab2874', '2020-07-08 00:48:07.591021', 1001, 1, 24, '2020-07-08 00:48:07.591021', '2020-06-27');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('ed2d9a44b0d88448ade429e60f810c62', '2020-07-08 00:48:07.591021', 973, 1, 20, '2020-07-08 00:48:07.591021', '2020-06-27');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('6508a59e1ef20cbb67d4de4eec7ecf3f', '2020-07-08 00:48:07.591021', 967, 1, 1, '2020-07-08 00:48:07.591021', '2020-06-27');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('7d365d8f31ee18b401396d51aed89372', '2020-07-08 00:48:07.770587', 992, 1, 6, '2020-07-08 00:48:07.770587', '2018-05-29');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('06c7043f29646b8953cd1f5910c5b974', '2020-07-08 00:48:07.889307', 985, 1, 118, '2020-07-08 00:48:07.889307', '2019-02-24');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('2f93c20eb9a44b929005ab66e3e3a298', '2020-07-08 00:48:07.889307', 980, 1, 70, '2020-07-08 00:48:07.889307', '2019-02-24');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('cb4fd59cadfe1cae33abc9c46b8e6858', '2020-07-08 00:48:07.889307', 983, 1, 26, '2020-07-08 00:48:07.889307', '2019-02-24');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('b84e6d01b7bab744c47bdf9c43068855', '2020-07-08 00:48:08.025966', 976, 1, 7, '2020-07-08 00:48:08.025966', '2020-06-16');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('212233499fc31ddf49568712ccfd43eb', '2020-07-08 00:48:08.152942', 983, 1, 18, '2020-07-08 00:48:08.152942', '2018-03-20');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('c1cff98dad44988108767215a8c2fe15', '2020-07-08 00:48:08.257815', 967, 1, 47, '2020-07-08 00:48:08.257815', '2020-04-03');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('15210463283ae8cc6dd941b0c51561a7', '2020-07-08 00:48:08.369712', 999, 1, 37, '2020-07-08 00:48:08.369712', '2017-12-06');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('4544372fde352b332cc919d8996c08ff', '2020-07-08 00:48:08.369712', 1001, 1, 53, '2020-07-08 00:48:08.369712', '2017-12-06');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('c9f68197b16f3a568b573d3ab6b2cd32', '2020-07-08 00:48:08.503571', 968, 1, 7, '2020-07-08 00:48:08.503571', '2020-07-06');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('d28fd04fec2d97dffb023c544b51c780', '2020-07-08 00:48:08.503571', 990, 1, 14, '2020-07-08 00:48:08.503571', '2020-07-06');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('6e8d6305dd15aa19826dfbdf16d474ab', '2020-07-08 00:48:08.503571', 971, 1, 3, '2020-07-08 00:48:08.503571', '2020-07-06');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('79650c2d2510ff42b79237484af1ae39', '2020-07-08 00:48:08.503571', 988, 1, 49, '2020-07-08 00:48:08.503571', '2020-07-06');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('bfbf2a045efb8f7706eca22204746421', '2020-07-08 00:48:08.503571', 985, 1, 52, '2020-07-08 00:48:08.503571', '2020-07-06');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('99c87a84bc252716cc0e63d92ce2a048', '2020-07-08 00:48:08.503571', 969, 1, 38, '2020-07-08 00:48:08.503571', '2020-07-06');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('4728c3b0a83e287507592d07d0575e0c', '2020-07-08 00:48:08.69722', 968, 1, 18, '2020-07-08 00:48:08.69722', '2020-07-04');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('f3e51517ebfbee0cac5fefcd28789de7', '2020-07-08 00:48:08.69722', 983, 1, 21, '2020-07-08 00:48:08.69722', '2020-07-04');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('b99cab55019d02483c7236f278d429c4', '2020-07-08 00:48:08.69722', 1000, 1, 10, '2020-07-08 00:48:08.69722', '2020-07-04');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('86316e9ab6429573daaa315f081aa0d7', '2020-07-08 00:48:08.69722', 969, 1, 32, '2020-07-08 00:48:08.69722', '2020-07-04');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('47120bd070c82f2c9fb33e7e93ee2922', '2020-07-08 00:48:08.69722', 980, 1, 34, '2020-07-08 00:48:08.69722', '2020-07-04');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('1cd403150c0d990c5cff4fa55609cd6b', '2020-07-08 00:48:08.69722', 986, 1, 1, '2020-07-08 00:48:08.69722', '2020-07-04');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('2e709ea886600731ebdd0ca741334944', '2020-07-08 00:48:08.89627', 995, 1, 6, '2020-07-08 00:48:08.89627', '2019-12-25');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('2cb78b99d6fc19a017aea01ca6040618', '2020-07-08 00:48:08.89627', 973, 1, 5, '2020-07-08 00:48:08.89627', '2019-12-25');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('e289f56342b39533fd984762eb899ff2', '2020-07-08 00:48:09.022376', 975, 1, 36, '2020-07-08 00:48:09.022376', '2019-12-05');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('178f326f4a696decdac76e8eec13851f', '2020-07-08 00:48:09.022376', 984, 1, 24, '2020-07-08 00:48:09.022376', '2019-12-05');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('1a89143eab7588471fa64f37bf64f41f', '2020-07-08 00:48:09.022376', 999, 1, 42, '2020-07-08 00:48:09.022376', '2019-12-05');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('b2eab3ab87c0a859ed3558f80cbeb488', '2020-07-08 00:48:09.022376', 994, 1, 2, '2020-07-08 00:48:09.022376', '2019-12-05');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('47f2581b075f879db4a889fc0403dde7', '2020-07-08 00:48:09.022376', 1000, 1, 9, '2020-07-08 00:48:09.022376', '2019-12-05');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('93349d4c9e39c7fb876d88de8a301873', '2020-07-08 00:48:09.1948', 968, 1, 2, '2020-07-08 00:48:09.1948', '2020-07-04');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('c26a91a53a77f661825aebb157108eff', '2020-07-08 00:48:09.1948', 975, 1, 2, '2020-07-08 00:48:09.1948', '2020-07-04');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('ff5ad9c5a4b33ad4e5c3568f73f4ae51', '2020-07-08 00:48:09.1948', 985, 1, 68, '2020-07-08 00:48:09.1948', '2020-07-04');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('3d5b75d2c11b6a3516b44215c100385c', '2020-07-08 00:48:09.1948', 993, 1, 10, '2020-07-08 00:48:09.1948', '2020-07-04');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('dab12f1cec7a842e08a2c06b367f32bf', '2020-07-08 00:49:02.766702', 969, 1, 11, '2020-07-08 00:49:02.766702', '2020-01-30');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('1f896b5a72b865b6f3f8aa203491c08b', '2020-07-08 00:49:02.880285', 971, 1, 6, '2020-07-08 00:49:02.880285', '2020-03-16');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('9be5829269d2253ff37e0b8ef5c90e77', '2020-07-08 00:49:02.880285', 970, 1, 23, '2020-07-08 00:49:02.880285', '2020-03-16');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('125c9ae2fcbf1dc42d8f9601e2256eb0', '2020-07-08 00:49:02.880285', 969, 1, 3, '2020-07-08 00:49:02.880285', '2020-03-16');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('472e96a5bf570bb13e72e8893f87a88a', '2020-07-08 00:49:02.880285', 1003, 1, 5, '2020-07-08 00:49:02.880285', '2020-03-16');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('e7a000168d58369f5f737da4c6fab95c', '2020-07-08 00:49:02.880285', 995, 1, 7, '2020-07-08 00:49:02.880285', '2020-03-16');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('620c3bb2cac7408d78487fd39a1b55a0', '2020-07-08 00:49:02.880285', 979, 1, 21, '2020-07-08 00:49:02.880285', '2020-03-16');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('df0d15618edaa24c14118f86b07b6786', '2020-07-08 00:49:03.064138', 997, 1, 4, '2020-07-08 00:49:03.064138', '2019-06-26');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('f12d7c6d7500b79612d677215b87d49b', '2020-07-08 00:49:03.064138', 1003, 1, 3, '2020-07-08 00:49:03.064138', '2019-06-26');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('71a66dc555c3b76d3f03d918370dce3e', '2020-07-08 00:49:03.064138', 994, 1, 4, '2020-07-08 00:49:03.064138', '2019-06-26');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('7d5676bbfdcbf9e62f78cd88f4a4e69b', '2020-07-08 00:49:03.203398', 983, 1, 23, '2020-07-08 00:49:03.203398', '2020-05-30');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('40f289bf02cd3ecdd5d486e7b8f9c9d5', '2020-07-08 00:49:03.203398', 1001, 1, 12, '2020-07-08 00:49:03.203398', '2020-05-30');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('cee6427a3364616eac61f578210d62c8', '2020-07-08 00:49:03.203398', 969, 1, 2, '2020-07-08 00:49:03.203398', '2020-05-30');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('754062186abd2323c6ecc82b79cadd91', '2020-07-08 00:49:03.203398', 977, 1, 39, '2020-07-08 00:49:03.203398', '2020-05-30');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('af6547a190d3f50c8178cc709914d153', '2020-07-08 00:49:03.203398', 986, 1, 2, '2020-07-08 00:49:03.203398', '2020-05-30');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('ad51d2e338b835a4b2d1d4d7a68867d7', '2020-07-08 00:49:03.203398', 974, 1, 32, '2020-07-08 00:49:03.203398', '2020-05-30');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('85565adc9f4d52935f22374956b2c649', '2020-07-08 00:49:03.381408', 1003, 1, 11, '2020-07-08 00:49:03.381408', '2020-03-22');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('a56186642a6cbbf47c3177daebaef4af', '2020-07-08 00:49:03.381408', 970, 1, 9, '2020-07-08 00:49:03.381408', '2020-03-22');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('d68bf08fb272c7f3bf690519b30bc9da', '2020-07-08 00:49:03.381408', 969, 1, 6, '2020-07-08 00:49:03.381408', '2020-03-22');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('8f71d9d3f51fa83fc8e4e0be04fdc219', '2020-07-08 00:49:03.381408', 994, 1, 7, '2020-07-08 00:49:03.381408', '2020-03-22');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('02062054ab3cb119c42d2a9a2da5f379', '2020-07-08 00:49:03.381408', 992, 1, 4, '2020-07-08 00:49:03.381408', '2020-03-22');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('742469d773dfccf28939a1013156ce22', '2020-07-08 00:49:03.381408', 973, 1, 5, '2020-07-08 00:49:03.381408', '2020-03-22');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('4e539d208176239a3bddf50af55c9eac', '2020-07-08 00:49:03.561354', 966, 1, 9, '2020-07-08 00:49:03.561354', '2020-05-19');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('5d1e6a8b10dd002e3067068538c8afc7', '2020-07-08 00:49:03.666865', 985, 1, 56, '2020-07-08 00:49:03.666865', '2017-12-27');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('e7d74920ab8f76525f87a75d86809c1b', '2020-07-08 00:49:03.666865', 990, 1, 38, '2020-07-08 00:49:03.666865', '2017-12-27');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('c454bde6ff9ee34fe6b274aa5063b1f6', '2020-07-08 00:49:03.666865', 1003, 1, 1, '2020-07-08 00:49:03.666865', '2017-12-27');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('c386cba98a38e282ef77af180e53e628', '2020-07-08 00:49:03.807687', 999, 1, 18, '2020-07-08 00:49:03.807687', '2019-10-19');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('794cec1730847ce88e0b13d76fa91eba', '2020-07-08 00:49:03.807687', 990, 1, 11, '2020-07-08 00:49:03.807687', '2019-10-19');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('4c4bcaba44580846f961699773e42f22', '2020-07-08 00:49:03.807687', 998, 1, 9, '2020-07-08 00:49:03.807687', '2019-10-19');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('b4f8a983d9182309f46cd9d401ae3427', '2020-07-08 00:49:03.807687', 977, 1, 5, '2020-07-08 00:49:03.807687', '2019-10-19');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('6a074b7d4a3b764312a305dff9922184', '2020-07-08 00:49:03.807687', 978, 1, 2, '2020-07-08 00:49:03.807687', '2019-10-19');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('951213e03bff05784966bf0b6480378b', '2020-07-08 00:49:03.970124', 969, 1, 1, '2020-07-08 00:49:03.970124', '2020-04-03');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('8e22143b9f27570990bfc5f6587646ff', '2020-07-08 00:49:03.970124', 991, 1, 42, '2020-07-08 00:49:03.970124', '2020-04-03');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('31b19abb5ca4874101029a7275bbe1d9', '2020-07-08 00:49:03.970124', 993, 1, 4, '2020-07-08 00:49:03.970124', '2020-04-03');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('6a815e6871204f21650fbe2dc660f7d0', '2020-07-08 00:49:03.970124', 979, 1, 25, '2020-07-08 00:49:03.970124', '2020-04-03');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('98cea720c3b88221d5cbce69c7d2ff1d', '2020-07-08 00:49:03.970124', 1001, 1, 14, '2020-07-08 00:49:03.970124', '2020-04-03');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('d7671e698dacee7cbc9d9e3fcdce1b55', '2020-07-08 00:49:04.146885', 968, 1, 12, '2020-07-08 00:49:04.146885', '2020-07-06');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('a3795b9366e3e71186fd841c18d0ddab', '2020-07-08 00:49:04.146885', 992, 1, 1, '2020-07-08 00:49:04.146885', '2020-07-06');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('890fca0919347571bb241acf06d586d5', '2020-07-08 00:49:04.146885', 967, 1, 16, '2020-07-08 00:49:04.146885', '2020-07-06');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('83100cf029e2bbcb22bf1df76f89c198', '2020-07-08 00:49:04.146885', 974, 1, 11, '2020-07-08 00:49:04.146885', '2020-07-06');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('8ed5515bece122446b1c3d944a8f9db7', '2020-07-08 00:49:04.29602', 968, 1, 2, '2020-07-08 00:49:04.29602', '2020-07-06');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('5ae90313d80c8248d48d74a292dd0039', '2020-07-08 00:49:04.29602', 977, 1, 31, '2020-07-08 00:49:04.29602', '2020-07-06');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('1be7f96fa47f39d703e4f8b0f611d819', '2020-07-08 00:49:04.29602', 984, 1, 5, '2020-07-08 00:49:04.29602', '2020-07-06');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('dbf85fbec5253402a2806e91bf8d7f85', '2020-07-08 00:49:04.29602', 985, 1, 33, '2020-07-08 00:49:04.29602', '2020-07-06');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('1bf2d15917dc3afeebaaaf9ecfc21846', '2020-07-08 00:49:04.29602', 999, 1, 11, '2020-07-08 00:49:04.29602', '2020-07-06');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('0258a62872132340f25de8a556040376', '2020-07-08 00:49:04.459401', 994, 1, 8, '2020-07-08 00:49:04.459401', '2017-03-29');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('f432ca8b70ebba15e669f01477e6e51e', '2020-07-08 00:49:04.589916', 984, 1, 1, '2020-07-08 00:49:04.589916', '2020-05-03');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('e4acfd80c205acc4af65b97014db2405', '2020-07-08 00:49:04.589916', 994, 1, 1, '2020-07-08 00:49:04.589916', '2020-05-03');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('ef6177f107b862207a6405e7b4852c12', '2020-07-08 00:49:04.589916', 969, 1, 14, '2020-07-08 00:49:04.589916', '2020-05-03');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('20a3e23b1433df702692eb5e894c7b8b', '2020-07-08 00:49:04.589916', 991, 1, 40, '2020-07-08 00:49:04.589916', '2020-05-03');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('ae43f63d299b371ad78dcfd94462bb85', '2020-07-08 00:49:04.589916', 987, 1, 26, '2020-07-08 00:49:04.589916', '2020-05-03');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('b170df58d91b1e5db6df915e3355ff43', '2020-07-08 00:49:04.589916', 971, 1, 7, '2020-07-08 00:49:04.589916', '2020-05-03');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('4770d0f4b579384d28ff066e47416fa0', '2020-07-08 00:49:04.754143', 998, 1, 32, '2020-07-08 00:49:04.754143', '2019-11-18');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('31b6812abe4b4e58b78e7cee11acd3a1', '2020-07-08 00:49:04.754143', 976, 1, 6, '2020-07-08 00:49:04.754143', '2019-11-18');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('ea59f7fa1e2e2c1b7c1b95b6389df986', '2020-07-08 00:49:04.754143', 969, 1, 8, '2020-07-08 00:49:04.754143', '2019-11-18');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('296e53e485e9d7648a4453cde6044d60', '2020-07-08 00:49:04.754143', 1002, 1, 19, '2020-07-08 00:49:04.754143', '2019-11-18');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('0e28e17e50ef0800ffc821548e1866b5', '2020-07-08 00:49:04.754143', 999, 1, 1, '2020-07-08 00:49:04.754143', '2019-11-18');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('3a1611baed053411128b5a8e0e2df420', '2020-07-08 00:49:04.754143', 980, 1, 3, '2020-07-08 00:49:04.754143', '2019-11-18');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('060b2d6f4fe2b6a6d7d47bad6c446bc5', '2020-07-08 00:49:04.914903', 991, 1, 26, '2020-07-08 00:49:04.914903', '2020-03-24');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('3cb76d2d8be65b5aa8bc1ac6d1d12e01', '2020-07-08 00:49:04.914903', 978, 1, 2, '2020-07-08 00:49:04.914903', '2020-03-24');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('a1bbb063da5114f9384f77316ef7bb6f', '2020-07-08 00:49:04.914903', 967, 1, 33, '2020-07-08 00:49:04.914903', '2020-03-24');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('db3bd1c455e1cbb9a5cbed5a8c11f2a4', '2020-07-08 00:49:04.914903', 984, 1, 1, '2020-07-08 00:49:04.914903', '2020-03-24');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('da3b47843effa01e665a9868a2f3eab7', '2020-07-08 00:49:04.914903', 1004, 1, 27, '2020-07-08 00:49:04.914903', '2020-03-24');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('5a93172337757a40389e08f34d4d24d0', '2020-07-08 00:49:05.081346', 986, 1, 1, '2020-07-08 00:49:05.081346', '2020-01-12');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('eb1e7e6ae0b09c1d57c1ddcd93322869', '2020-07-08 00:49:05.081346', 977, 1, 34, '2020-07-08 00:49:05.081346', '2020-01-12');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('1401e15a67f19f2b04d14de5b02ab4e4', '2020-07-08 00:49:05.081346', 970, 1, 18, '2020-07-08 00:49:05.081346', '2020-01-12');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('82f810b36927d064ddc8247cb22e8cbb', '2020-07-08 00:49:05.081346', 981, 1, 14, '2020-07-08 00:49:05.081346', '2020-01-12');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('6b6c9727657976aa5d5118373e8cdc58', '2020-07-08 00:49:05.081346', 984, 1, 4, '2020-07-08 00:49:05.081346', '2020-01-12');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('df8f1f97142f01275420bb6e02603c06', '2020-07-08 00:49:05.303975', 978, 1, 2, '2020-07-08 00:49:05.303975', '2019-12-24');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('f7955c4f48516aac573b8fa0d27de711', '2020-07-08 00:49:05.411632', 971, 1, 6, '2020-07-08 00:49:05.411632', '2020-02-15');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('c1f2625e0d9e443783ac5fcdffdaf4b0', '2020-07-08 00:49:05.411632', 1002, 1, 13, '2020-07-08 00:49:05.411632', '2020-02-15');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('1505213e44a2363b67e2de423882073e', '2020-07-08 00:49:05.411632', 974, 1, 23, '2020-07-08 00:49:05.411632', '2020-02-15');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('efcb9a69106cc97fb4323f09f6723947', '2020-07-08 00:49:05.550198', 982, 1, 9, '2020-07-08 00:49:05.550198', '2020-01-26');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('c13ec0ca0e86d0df7ef9aaf56071999d', '2020-07-08 00:49:05.550198', 1001, 1, 3, '2020-07-08 00:49:05.550198', '2020-01-26');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('ec7817c61189f658d5cc17ccfb58e3c8', '2020-07-08 00:49:05.550198', 981, 1, 19, '2020-07-08 00:49:05.550198', '2020-01-26');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('bcfafda5dbc35c69874f5b37d635da0e', '2020-07-08 00:49:05.680178', 972, 1, 1, '2020-07-08 00:49:05.680178', '2020-07-06');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('1c36982cb46e81e0355b341aa2a7a489', '2020-07-08 00:49:05.680178', 973, 1, 14, '2020-07-08 00:49:05.680178', '2020-07-06');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('9c780544526baa071263de35c561158d', '2020-07-08 00:49:05.680178', 981, 1, 9, '2020-07-08 00:49:05.680178', '2020-07-06');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('059225b24fdb9beb6fd90acfc9d83c6e', '2020-07-08 00:49:05.680178', 993, 1, 1, '2020-07-08 00:49:05.680178', '2020-07-06');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('e8ce846c76b1e046a73049053f10c357', '2020-07-08 00:49:05.680178', 999, 1, 21, '2020-07-08 00:49:05.680178', '2020-07-06');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('6c337f1c3528cb324e3c4367fb0a2a4a', '2020-07-08 00:49:05.680178', 968, 1, 9, '2020-07-08 00:49:05.680178', '2020-07-06');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('d0aec3db4b5647564721fe3defe3322a', '2020-07-08 00:49:05.848884', 983, 1, 23, '2020-07-08 00:49:05.848884', '2019-08-28');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('4b75257068e0b499db745d73a8ab2a54', '2020-07-08 00:49:05.848884', 995, 1, 4, '2020-07-08 00:49:05.848884', '2019-08-28');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('0f1554d2fdace350e57630e7248a043c', '2020-07-08 00:49:05.848884', 982, 1, 9, '2020-07-08 00:49:05.848884', '2019-08-28');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('f9d41cc736ffb92e5ac590b41cbe970a', '2020-07-08 00:49:05.848884', 970, 1, 6, '2020-07-08 00:49:05.848884', '2019-08-28');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('b37c61b90b9602426e9748508a7cf79d', '2020-07-08 00:49:05.848884', 976, 1, 6, '2020-07-08 00:49:05.848884', '2019-08-28');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('17619d0e883bd1a33df9496c08779bb3', '2020-07-08 00:49:05.848884', 977, 1, 2, '2020-07-08 00:49:05.848884', '2019-08-28');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('6ed6b166b7b817198e29254e9812a82e', '2020-07-08 00:49:06.029046', 984, 1, 3, '2020-07-08 00:49:06.029046', '2020-01-23');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('48a7c844e73c710748c7708a59eb15ac', '2020-07-08 00:49:06.029046', 982, 1, 9, '2020-07-08 00:49:06.029046', '2020-01-23');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('a55cb1983e12bc11f43de41e89efa6ef', '2020-07-08 00:49:06.145822', 980, 1, 17, '2020-07-08 00:49:06.145822', '2018-06-28');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('120159c82dbe6e6a834d7b69c451c07e', '2020-07-08 00:49:06.145822', 1001, 1, 14, '2020-07-08 00:49:06.145822', '2018-06-28');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('c00da8ae7e00be70b44dec5107ef4cf1', '2020-07-08 00:49:06.145822', 1000, 1, 2, '2020-07-08 00:49:06.145822', '2018-06-28');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('f9009843cfdba49eb37cc981a97834c6', '2020-07-08 00:49:06.286603', 980, 1, 54, '2020-07-08 00:49:06.286603', '2018-11-26');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('a3ef26ab0c60b4ccd63e84b9a809f23c', '2020-07-08 00:49:06.286603', 982, 1, 3, '2020-07-08 00:49:06.286603', '2018-11-26');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('0f1ba4d87d72827da86bb028deded987', '2020-07-08 00:49:06.401607', 990, 1, 61, '2020-07-08 00:49:06.401607', '2019-07-16');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('232bdd5d3260855c4d3f6733710c5fda', '2020-07-08 00:49:06.401607', 998, 1, 8, '2020-07-08 00:49:06.401607', '2019-07-16');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('a62dd2bd4441bd23186aebd91211f4ff', '2020-07-08 00:49:06.530862', 979, 1, 10, '2020-07-08 00:49:06.530862', '2020-01-16');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('f74355b3207890cbd6c9a6a760d8146b', '2020-07-08 00:49:06.530862', 983, 1, 17, '2020-07-08 00:49:06.530862', '2020-01-16');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('7edaa97ec1e8c46133c13cc7df00f71e', '2020-07-08 00:49:06.530862', 984, 1, 3, '2020-07-08 00:49:06.530862', '2020-01-16');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('434bf2f2c272023d95665d86ea0bc158', '2020-07-08 00:49:06.657987', 973, 1, 5, '2020-07-08 00:49:06.657987', '2019-10-14');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('0dc07762c60d8a19e53360c76f1d5d7a', '2020-07-08 00:49:06.775909', 1003, 1, 3, '2020-07-08 00:49:06.775909', '2020-04-09');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('9cc40f72686a6f6b5d85e3a533b02de9', '2020-07-08 00:49:06.775909', 971, 1, 6, '2020-07-08 00:49:06.775909', '2020-04-09');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('c0b7c2d524ca5776de81e17762312069', '2020-07-08 00:49:06.775909', 992, 1, 5, '2020-07-08 00:49:06.775909', '2020-04-09');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('5bd5df8abdcba522b893f2040841bee1', '2020-07-08 00:49:06.775909', 998, 1, 10, '2020-07-08 00:49:06.775909', '2020-04-09');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('ac8076556a0949b984871bbd3e06d0e1', '2020-07-08 00:49:06.775909', 989, 1, 57, '2020-07-08 00:49:06.775909', '2020-04-09');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('32c84248075c9c63fd8297de33002618', '2020-07-08 00:49:06.939677', 968, 1, 25, '2020-07-08 00:49:06.939677', '2020-07-06');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('11db52d1db294a5e5bfeec85df31e2ea', '2020-07-08 00:49:06.939677', 969, 1, 10, '2020-07-08 00:49:06.939677', '2020-07-06');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('c6c72b920699b8f5c5b1d06e521b3b0f', '2020-07-08 00:49:06.939677', 974, 1, 9, '2020-07-08 00:49:06.939677', '2020-07-06');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('7b6ed8e1c750a5cc4ca37ae54534a366', '2020-07-08 00:49:06.939677', 1002, 1, 9, '2020-07-08 00:49:06.939677', '2020-07-06');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('3de889173cd537d79bc15be49070e964', '2020-07-08 00:49:07.080787', 985, 1, 8, '2020-07-08 00:49:07.080787', '2018-04-02');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('700e86cc782439bb1cf2e6972fa0f18d', '2020-07-08 00:49:07.080787', 992, 1, 4, '2020-07-08 00:49:07.080787', '2018-04-02');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('bde9ce6595811cd5f3f6eda896329b9b', '2020-07-08 00:49:07.080787', 991, 1, 47, '2020-07-08 00:49:07.080787', '2018-04-02');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('a6ff4de6a5c042cf67a2b8640280173c', '2020-07-08 00:49:07.219434', 976, 1, 11, '2020-07-08 00:49:07.219434', '2019-11-22');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('f4b06d8b75b4c662b9b4e9c9a13a68fe', '2020-07-08 00:49:07.219434', 988, 1, 9, '2020-07-08 00:49:07.219434', '2019-11-22');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('08b6729f8ea2f67a2dcef7201eaf8945', '2020-07-08 00:49:07.219434', 973, 1, 9, '2020-07-08 00:49:07.219434', '2019-11-22');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('03e02b6a580836b9b2ec68b6e3853312', '2020-07-08 00:49:07.219434', 984, 1, 1, '2020-07-08 00:49:07.219434', '2019-11-22');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('34481f88008ee1da10acf343468f12d8', '2020-07-08 00:49:07.219434', 992, 1, 4, '2020-07-08 00:49:07.219434', '2019-11-22');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('ac6fa1ff069e164d3eeba1f0372f90bf', '2020-07-08 00:49:07.370312', 989, 1, 15, '2020-07-08 00:49:07.370312', '2019-08-18');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('a44da93076b9529149a8d22201708a47', '2020-07-08 00:49:07.370312', 986, 1, 2, '2020-07-08 00:49:07.370312', '2019-08-18');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('9527c787af196fb6a74625273d35726f', '2020-07-08 00:49:07.370312', 997, 1, 20, '2020-07-08 00:49:07.370312', '2019-08-18');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('7bb60f351a6fa49e094aa36450e1d3b1', '2020-07-08 00:49:07.511943', 966, 1, 8, '2020-07-08 00:49:07.511943', '2020-05-30');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('1b1b30b338c1c22ec46842e3b796e69b', '2020-07-08 00:49:07.511943', 969, 1, 8, '2020-07-08 00:49:07.511943', '2020-05-30');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('e9e2ba5ee2c5fa646ccb16b10c15a265', '2020-07-08 00:49:07.511943', 985, 1, 36, '2020-07-08 00:49:07.511943', '2020-05-30');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('1ae2ace957d4bbf7077d2e9225a77173', '2020-07-08 00:49:07.511943', 967, 1, 6, '2020-07-08 00:49:07.511943', '2020-05-30');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('0f1dc28f5267e55d28baf0f1dd55b245', '2020-07-08 00:49:07.658946', 994, 1, 5, '2020-07-08 00:49:07.658946', '2020-02-20');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('238496c760fcd7ad0bd963d602f7d2e6', '2020-07-08 00:49:07.658946', 977, 1, 36, '2020-07-08 00:49:07.658946', '2020-02-20');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('1449dc96224ed9c41ff07c187fb2d548', '2020-07-08 00:49:07.658946', 974, 1, 17, '2020-07-08 00:49:07.658946', '2020-02-20');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('d3e737998c35e5315a79dff944ad0ca2', '2020-07-08 00:49:07.658946', 984, 1, 3, '2020-07-08 00:49:07.658946', '2020-02-20');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('a8ceb6e8c1122b5282a14b907615ce53', '2020-07-08 00:49:07.658946', 990, 1, 59, '2020-07-08 00:49:07.658946', '2020-02-20');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('b659dc6071bd02df7ff1776567f605a8', '2020-07-08 00:49:07.803946', 981, 1, 8, '2020-07-08 00:49:07.803946', '2018-08-04');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('3f7e2c79a12d1e85e2833e27b61fef6a', '2020-07-08 00:49:07.803946', 993, 1, 2, '2020-07-08 00:49:07.803946', '2018-08-04');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('edec610bb43f815bb11e13a2f6d8fe7c', '2020-07-08 00:49:07.803946', 990, 1, 38, '2020-07-08 00:49:07.803946', '2018-08-04');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('2ab8789527a808f3b927f13004d4735f', '2020-07-08 00:49:07.803946', 1003, 1, 3, '2020-07-08 00:49:07.803946', '2018-08-04');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('7b6f61201d1f1458789133e5e515e8b8', '2020-07-08 00:49:08.113995', 997, 1, 19, '2020-07-08 00:49:08.113995', '2018-12-15');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('d1138fd2d3074867775b7f8ed8919a51', '2020-07-08 00:49:08.113995', 978, 1, 9, '2020-07-08 00:49:08.113995', '2018-12-15');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('2bd27383d11436fdb96a93eff1416a77', '2020-07-08 00:49:08.113995', 989, 1, 55, '2020-07-08 00:49:08.113995', '2018-12-15');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('9caef85410b21c87b227f44dfb7e0953', '2020-07-08 00:49:08.113995', 984, 1, 3, '2020-07-08 00:49:08.113995', '2018-12-15');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('7798ecbbaf2a8f318419aec5f794dbb7', '2020-07-08 00:49:08.277943', 996, 1, 10, '2020-07-08 00:49:08.277943', '2019-02-04');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('aba196512dd079c2e2186f71d1e39790', '2020-07-08 00:49:08.277943', 1001, 1, 14, '2020-07-08 00:49:08.277943', '2019-02-04');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('d0629893b9931d215e9de92e07b1d788', '2020-07-08 00:49:08.277943', 1004, 1, 39, '2020-07-08 00:49:08.277943', '2019-02-04');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('92f675f23ca3c26ff42336115ece15ed', '2020-07-08 00:49:08.277943', 981, 1, 18, '2020-07-08 00:49:08.277943', '2019-02-04');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('5d144af7f499cefaa3838b3ec569b818', '2020-07-08 00:49:08.422122', 970, 1, 9, '2020-07-08 00:49:08.422122', '2020-06-30');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('8efedc19c6f8f6a3dbd2d02ecae3a9da', '2020-07-08 00:49:08.531577', 989, 1, 58, '2020-07-08 00:49:08.531577', '2018-04-07');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('56c56d16b9f98fcedd3d9be5124a88d6', '2020-07-08 00:49:08.644806', 994, 1, 8, '2020-07-08 00:49:08.644806', '2020-03-10');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('a0afd8fb4d0f0584bfa1f335d4af74ea', '2020-07-08 00:49:08.644806', 970, 1, 21, '2020-07-08 00:49:08.644806', '2020-03-10');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('5d5a224c81fe306eee3c713e5fc7dbe1', '2020-07-08 00:49:08.644806', 990, 1, 56, '2020-07-08 00:49:08.644806', '2020-03-10');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('795182f08f91d628b91d8218b5b36cef', '2020-07-08 00:49:08.644806', 996, 1, 8, '2020-07-08 00:49:08.644806', '2020-03-10');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('37061e53fe5b512bc50484bc81689ab6', '2020-07-08 00:49:08.794525', 968, 1, 1, '2020-07-08 00:49:08.794525', '2020-07-04');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('2431ce5ed72edde2d167044c40d54fb4', '2020-07-08 00:49:08.794525', 976, 1, 11, '2020-07-08 00:49:08.794525', '2020-07-04');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('ad17c60f490436e3746cd77a0f274988', '2020-07-08 00:49:08.794525', 990, 1, 3, '2020-07-08 00:49:08.794525', '2020-07-04');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('480d0c0c748867ed3f976acebaa444df', '2020-07-08 00:49:08.794525', 970, 1, 16, '2020-07-08 00:49:08.794525', '2020-07-04');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('9288d838f269ad6e2c47c12db60bc3f5', '2020-07-08 00:49:08.945367', 995, 1, 11, '2020-07-08 00:49:08.945367', '2020-04-23');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('c1059a1dd009659a3a733efa2f7c8d93', '2020-07-08 00:49:08.945367', 978, 1, 6, '2020-07-08 00:49:08.945367', '2020-04-23');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('65405ff1d3cf44f19a85557c4efbff8c', '2020-07-08 00:49:09.06596', 999, 1, 2, '2020-07-08 00:49:09.06596', '2018-09-22');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('046e73774554b2d673b94dee9f2bcccd', '2020-07-08 00:49:09.06596', 1004, 1, 42, '2020-07-08 00:49:09.06596', '2018-09-22');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('1d8d706bf0a7b166f887f42892169d7b', '2020-07-08 00:49:09.06596', 1001, 1, 1, '2020-07-08 00:49:09.06596', '2018-09-22');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('0de52b5acf17f8cf920730f917ee3ff1', '2020-07-08 00:49:09.06596', 981, 1, 3, '2020-07-08 00:49:09.06596', '2018-09-22');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('71241cf33dc16a5e9e6fee5cc965c82b', '2020-07-08 00:49:09.06596', 1005, 1, 1, '2020-07-08 00:49:09.06596', '2018-09-22');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('aacfcda80f3c35cad6a891d9c891f6c7', '2020-07-08 00:49:09.06596', 997, 1, 20, '2020-07-08 00:49:09.06596', '2018-09-22');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('90dd1235de7c08aab64cec7c7a0bb96f', '2020-07-08 00:49:09.284414', 970, 1, 5, '2020-07-08 00:49:09.284414', '2019-10-31');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('66e00b49d4cc7a802a00dbbc9e642790', '2020-07-08 00:49:09.436373', 966, 1, 4, '2020-07-08 00:49:09.436373', '2020-07-06');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('3d8b353c02d7afe76698d04eb9de85b4', '2020-07-08 00:49:09.548088', 996, 1, 17, '2020-07-08 00:49:09.548088', '2020-05-23');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('5f1a0d1708eae959a45f1e863d4da7f4', '2020-07-08 00:49:09.548088', 966, 1, 4, '2020-07-08 00:49:09.548088', '2020-05-23');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('934242e6c24cedcba1dcbf198433de36', '2020-07-08 00:49:09.548088', 1003, 1, 10, '2020-07-08 00:49:09.548088', '2020-05-23');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('76b9cfc0413a3b4fe278356b2b5a8770', '2020-07-08 00:49:09.548088', 989, 1, 43, '2020-07-08 00:49:09.548088', '2020-05-23');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('85e0791f0d279d9ad0578ab8bcedcf6d', '2020-07-08 00:49:09.548088', 986, 1, 2, '2020-07-08 00:49:09.548088', '2020-05-23');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('99ad362349842d73aaaa2b4294cb696f', '2020-07-08 00:49:09.717544', 997, 1, 9, '2020-07-08 00:49:09.717544', '2020-05-15');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('5e5094d0bb6cd803c4f731a8cb451a48', '2020-07-08 00:49:09.717544', 981, 1, 6, '2020-07-08 00:49:09.717544', '2020-05-15');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('7bcbd64330fc0b7a2f9d42e53bf69d31', '2020-07-08 00:49:09.717544', 974, 1, 2, '2020-07-08 00:49:09.717544', '2020-05-15');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('e4f8cac5b272cd7ac91a292e9e8fcd42', '2020-07-08 00:49:09.717544', 979, 1, 5, '2020-07-08 00:49:09.717544', '2020-05-15');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('a20f258e164214200adf2d80f86ff453', '2020-07-08 00:49:09.717544', 967, 1, 21, '2020-07-08 00:49:09.717544', '2020-05-15');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('d0fbc6c6ee45d6659794ee83cb985433', '2020-07-08 00:49:09.717544', 1001, 1, 8, '2020-07-08 00:49:09.717544', '2020-05-15');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('01d6e7d714c15261c32de97eb096a236', '2020-07-08 00:49:09.900248', 986, 1, 1, '2020-07-08 00:49:09.900248', '2018-08-20');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('0d475f1ec22e48f4d3c33471c4cf12d2', '2020-07-08 00:49:09.900248', 980, 1, 8, '2020-07-08 00:49:09.900248', '2018-08-20');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('ccf990cea879e3ca0789aecbaad579e0', '2020-07-08 00:49:10.026827', 988, 1, 4, '2020-07-08 00:49:10.026827', '2018-02-06');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('99be073105f6814fbf9ad62023cbb4f2', '2020-07-08 00:49:10.14832', 999, 1, 4, '2020-07-08 00:49:10.14832', '2019-02-05');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('451955b74639088615a64247779d72eb', '2020-07-08 00:49:10.14832', 976, 1, 12, '2020-07-08 00:49:10.14832', '2019-02-05');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('0b317fabca1aac31b858c5175e78ff76', '2020-07-08 00:49:10.14832', 997, 1, 15, '2020-07-08 00:49:10.14832', '2019-02-05');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('9838043c6e0ff340b7448e81aa26621a', '2020-07-08 00:49:10.14832', 986, 1, 1, '2020-07-08 00:49:10.14832', '2019-02-05');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('7d23961a93480f8dbb08e344dcd92609', '2020-07-08 00:49:10.14832', 992, 1, 5, '2020-07-08 00:49:10.14832', '2019-02-05');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('b3cc6184a8192a6ad8120dd5907c5fc5', '2020-07-08 00:49:10.14832', 994, 1, 1, '2020-07-08 00:49:10.14832', '2019-02-05');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('b256cc42e7dd337cea573717fb2a38d9', '2020-07-08 00:49:10.327406', 968, 1, 17, '2020-07-08 00:49:10.327406', '2020-07-04');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('716467a0874281e7b0f72065bd001590', '2020-07-08 00:49:10.327406', 993, 1, 4, '2020-07-08 00:49:10.327406', '2020-07-04');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('26af9c43981456755d3ee2f34baf0543', '2020-07-08 00:49:10.327406', 976, 1, 12, '2020-07-08 00:49:10.327406', '2020-07-04');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('9897792ee23ef89049798b71c98b2120', '2020-07-08 00:49:10.467263', 987, 1, 18, '2020-07-08 00:49:10.467263', '2020-02-23');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('2119bf93a5eb21a2d21cf620c3b3cc58', '2020-07-08 00:49:10.467263', 969, 1, 5, '2020-07-08 00:49:10.467263', '2020-02-23');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('76b4ec7cb080c63751ce3d3e61ac8c2d', '2020-07-08 00:49:10.467263', 972, 1, 1, '2020-07-08 00:49:10.467263', '2020-02-23');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('32b28bc0537e0db46d64300503ee9139', '2020-07-08 00:49:10.467263', 1002, 1, 21, '2020-07-08 00:49:10.467263', '2020-02-23');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('eb3459441d3989b733f9ce457ff1d91f', '2020-07-08 00:49:10.467263', 985, 1, 9, '2020-07-08 00:49:10.467263', '2020-02-23');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('dadc57917ba6e7858c181cb7f632f841', '2020-07-08 00:49:10.467263', 974, 1, 23, '2020-07-08 00:49:10.467263', '2020-02-23');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('ed4cb27356f23b9649b037271e5bd566', '2020-07-08 00:49:10.650543', 977, 1, 4, '2020-07-08 00:49:10.650543', '2020-05-27');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('85bc2f1481eac63437d2ea3e61d0ce1a', '2020-07-08 00:49:10.650543', 981, 1, 24, '2020-07-08 00:49:10.650543', '2020-05-27');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('bb409c27b62c9a37f20f95b5aa14ed7c', '2020-07-08 00:49:10.650543', 994, 1, 4, '2020-07-08 00:49:10.650543', '2020-05-27');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('038e892d711edaeda862b159ef0f40c4', '2020-07-08 00:49:10.650543', 1001, 1, 5, '2020-07-08 00:49:10.650543', '2020-05-27');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('4225ba764faa5745bd1aae3a6a4f72c8', '2020-07-08 00:49:10.650543', 993, 1, 2, '2020-07-08 00:49:10.650543', '2020-05-27');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('58f5172286d0cb3e9c3a3244aca7d15f', '2020-07-08 00:49:10.806699', 998, 1, 35, '2020-07-08 00:49:10.806699', '2020-07-05');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('8ba5c1c15a1a8500c5f1db037fe0b13e', '2020-07-08 00:49:10.806699', 989, 1, 54, '2020-07-08 00:49:10.806699', '2020-07-05');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('2248d8851b7d91c3c1c3349c95755ab9', '2020-07-08 00:49:10.806699', 968, 1, 23, '2020-07-08 00:49:10.806699', '2020-07-05');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('df692cb6045a4f2af1aa254b149cca2c', '2020-07-08 00:49:10.806699', 1000, 1, 2, '2020-07-08 00:49:10.806699', '2020-07-05');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('6eb2853f6bc10b9212b68c58ae6465a5', '2020-07-08 00:49:10.806699', 978, 1, 10, '2020-07-08 00:49:10.806699', '2020-07-05');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('a80b5a08d04c0958b099bfb5c79c5430', '2020-07-08 00:49:10.806699', 995, 1, 1, '2020-07-08 00:49:10.806699', '2020-07-05');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('0f9f6319b76a11f3946fb66b9d5f6b6f', '2020-07-08 00:49:10.987511', 982, 1, 3, '2020-07-08 00:49:10.987511', '2019-03-21');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('5f39ee5e82070bc4de9dfa6f5a00a5c3', '2020-07-08 00:49:10.987511', 1001, 1, 5, '2020-07-08 00:49:10.987511', '2019-03-21');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('2ccd6f24b7a986f791d8fcb959ba8822', '2020-07-08 00:49:10.987511', 993, 1, 4, '2020-07-08 00:49:10.987511', '2019-03-21');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('d71eefda9594803e84f77543742332cc', '2020-07-08 00:49:11.2279', 992, 1, 3, '2020-07-08 00:49:11.2279', '2018-05-18');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('e514da0043192217b9578b32949f442f', '2020-07-08 00:49:11.32834', 966, 1, 3, '2020-07-08 00:49:11.32834', '2020-03-28');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('03e81d98d1dee150caa26a7c4427f23d', '2020-07-08 00:49:11.32834', 1004, 1, 32, '2020-07-08 00:49:11.32834', '2020-03-28');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('52b737cca2549ab2eaa3281cd95a87c8', '2020-07-08 00:49:11.32834', 983, 1, 13, '2020-07-08 00:49:11.32834', '2020-03-28');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('a4f247397bc4064327cf5fe56c3d9dfa', '2020-07-08 00:49:11.32834', 1005, 1, 1, '2020-07-08 00:49:11.32834', '2020-03-28');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('16193b75d9c48b527a1a3b51cfabb46c', '2020-07-08 00:49:11.32834', 977, 1, 21, '2020-07-08 00:49:11.32834', '2020-03-28');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('00626c2275efd7616a5348f0cf335b94', '2020-07-08 00:49:11.484713', 966, 1, 4, '2020-07-08 00:49:11.484713', '2020-05-06');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('b1824e18476f4750e0b195f610872a4a', '2020-07-08 00:49:11.484713', 1001, 1, 8, '2020-07-08 00:49:11.484713', '2020-05-06');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('11dcb877eb5dbb83e3f3e79b86552c50', '2020-07-08 00:49:11.484713', 1002, 1, 14, '2020-07-08 00:49:11.484713', '2020-05-06');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('4974d40a147859b500fb02611f1c246f', '2020-07-08 00:49:11.616309', 985, 1, 48, '2020-07-08 00:49:11.616309', '2017-05-07');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('af84535fd5b75e246d17d1589eb483e7', '2020-07-08 00:49:11.729999', 1003, 1, 6, '2020-07-08 00:49:11.729999', '2020-07-06');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('005b8b37f2173c32090e3b6258fbe978', '2020-07-08 00:49:11.729999', 992, 1, 2, '2020-07-08 00:49:11.729999', '2020-07-06');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('0128fabf7e88cb427cbad6a55c902ebe', '2020-07-08 00:49:11.729999', 978, 1, 3, '2020-07-08 00:49:11.729999', '2020-07-06');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('c1103f350a5d976fc079d082776dab25', '2020-07-08 00:49:11.729999', 1005, 1, 1, '2020-07-08 00:49:11.729999', '2020-07-06');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('c186f3eb01cf8006868bf0f896c8d6ce', '2020-07-08 00:49:11.729999', 968, 1, 14, '2020-07-08 00:49:11.729999', '2020-07-06');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('e8883ee84aeb5ab5a787cb69457bfb8f', '2020-07-08 00:49:11.729999', 994, 1, 2, '2020-07-08 00:49:11.729999', '2020-07-06');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('ae4587be2e277650042ba139b7ba613d', '2020-07-08 00:49:11.918907', 990, 1, 52, '2020-07-08 00:49:11.918907', '2020-02-24');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('1bb4d3da44c4dc999ac2162cfa3a30fa', '2020-07-08 00:49:11.918907', 977, 1, 33, '2020-07-08 00:49:11.918907', '2020-02-24');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('cada870d1817428571f2f71ef6e8b9c1', '2020-07-08 00:49:11.918907', 980, 1, 62, '2020-07-08 00:49:11.918907', '2020-02-24');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('a36039cf129d58a20326c852e0831037', '2020-07-08 00:49:12.049394', 982, 1, 11, '2020-07-08 00:49:12.049394', '2020-04-05');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('6207b517c4fd7081f291e270978bf2dd', '2020-07-08 00:49:12.049394', 987, 1, 44, '2020-07-08 00:49:12.049394', '2020-04-05');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('dff1061e2e3d0203b543ad521a3db0d8', '2020-07-08 00:49:12.049394', 972, 1, 1, '2020-07-08 00:49:12.049394', '2020-04-05');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('4639c0c92f68a54d17e0b9811fb060e0', '2020-07-08 00:49:12.185625', 969, 1, 14, '2020-07-08 00:49:12.185625', '2020-04-29');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('f2d33c624d0b2640fd8af0859a3c687d', '2020-07-08 00:49:12.185625', 973, 1, 14, '2020-07-08 00:49:12.185625', '2020-04-29');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('ce8fd5b0fc07c54e89cfc2e96f1684f5', '2020-07-08 00:49:12.308645', 999, 1, 19, '2020-07-08 00:49:12.308645', '2020-07-04');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('873c0f750c23a3b7ad67a507bad54dbb', '2020-07-08 00:49:12.308645', 980, 1, 50, '2020-07-08 00:49:12.308645', '2020-07-04');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('9039e63b535d4625f120fdc444999423', '2020-07-08 00:49:12.308645', 981, 1, 14, '2020-07-08 00:49:12.308645', '2020-07-04');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('8b7f5380cccd20237339d08c20a1ea6e', '2020-07-08 00:49:12.308645', 968, 1, 16, '2020-07-08 00:49:12.308645', '2020-07-04');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('c86595b20569d13415f85483612a7459', '2020-07-08 00:49:12.308645', 990, 1, 25, '2020-07-08 00:49:12.308645', '2020-07-04');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('5cc032ccd99d5511b1acd498d6d22dc5', '2020-07-08 00:49:12.46293', 974, 1, 23, '2020-07-08 00:49:12.46293', '2020-06-14');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('f06ed8a9381ddd5ba708d102713d91a3', '2020-07-08 00:49:12.46293', 971, 1, 6, '2020-07-08 00:49:12.46293', '2020-06-14');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('53a1da48f2a466499b20c4bf329030eb', '2020-07-08 00:49:12.46293', 983, 1, 9, '2020-07-08 00:49:12.46293', '2020-06-14');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('d545cccc7162a485c3f5d6e712388eaa', '2020-07-08 00:49:12.46293', 992, 1, 5, '2020-07-08 00:49:12.46293', '2020-06-14');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('733acf539914a33ea6907ea479e83a40', '2020-07-08 00:49:12.46293', 984, 1, 2, '2020-07-08 00:49:12.46293', '2020-06-14');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('102678a89b069c71bab1540b6d97a61b', '2020-07-08 00:49:12.631099', 999, 1, 24, '2020-07-08 00:49:12.631099', '2020-04-10');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('188c7ca20d323839f3d8435fab5dccf7', '2020-07-08 00:49:12.631099', 1003, 1, 6, '2020-07-08 00:49:12.631099', '2020-04-10');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('120d7b82d50858595b00d28fadf9ea3a', '2020-07-08 00:49:12.631099', 978, 1, 7, '2020-07-08 00:49:12.631099', '2020-04-10');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('dd1aaaafcb544ed5713f78e02ac92713', '2020-07-08 00:49:12.631099', 967, 1, 32, '2020-07-08 00:49:12.631099', '2020-04-10');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('39210b09682f4d8824efd11ba928edaa', '2020-07-08 00:49:12.631099', 980, 1, 30, '2020-07-08 00:49:12.631099', '2020-04-10');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('7599d888d8640e386ebadff06eeecd14', '2020-07-08 00:49:12.784506', 992, 1, 2, '2020-07-08 00:49:12.784506', '2018-07-29');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('d7d213170b75def2e087270a4ba1ddcf', '2020-07-08 00:49:12.784506', 990, 1, 32, '2020-07-08 00:49:12.784506', '2018-07-29');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('773f80155e04a4f019422fbee7758fb2', '2020-07-08 00:49:12.913014', 968, 1, 18, '2020-07-08 00:49:12.913014', '2020-07-04');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('95128ea0a08e040df4fc52e5540239fd', '2020-07-08 00:49:12.913014', 971, 1, 5, '2020-07-08 00:49:12.913014', '2020-07-04');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('df372f4da863998f4ab6a835393216c0', '2020-07-08 00:49:12.913014', 990, 1, 47, '2020-07-08 00:49:12.913014', '2020-07-04');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('690917d3537f3b1cb85643c77196b0d2', '2020-07-08 00:49:12.913014', 984, 1, 6, '2020-07-08 00:49:12.913014', '2020-07-04');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('034674f9f2b2ddc6420e20dd5a8f6721', '2020-07-08 00:49:13.102151', 1001, 1, 11, '2020-07-08 00:49:13.102151', '2020-07-06');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('3401d12e49222fc05c8702de691c1ce5', '2020-07-08 00:49:13.102151', 981, 1, 14, '2020-07-08 00:49:13.102151', '2020-07-06');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('f8c5faf050a6535a32b2bef594fbed89', '2020-07-08 00:49:13.102151', 995, 1, 5, '2020-07-08 00:49:13.102151', '2020-07-06');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('b99d8008cc0a597d098721161b66c517', '2020-07-08 00:49:13.102151', 999, 1, 4, '2020-07-08 00:49:13.102151', '2020-07-06');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('7a3a2dc2f2fa227bb2517e204ee1c583', '2020-07-08 00:49:13.102151', 996, 1, 7, '2020-07-08 00:49:13.102151', '2020-07-06');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('722adc98e7423addc5897e8b5afbca32', '2020-07-08 00:49:13.267731', 1003, 1, 5, '2020-07-08 00:49:13.267731', '2016-10-07');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('37ab6132a37867f055d0e8ddc7594f2c', '2020-07-08 00:49:13.423953', 994, 1, 5, '2020-07-08 00:49:13.423953', '2019-04-01');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('7a8aa304833320d4258a397d67deb43b', '2020-07-08 00:49:13.423953', 976, 1, 7, '2020-07-08 00:49:13.423953', '2019-04-01');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('3908c1090e46bf09071c554d26652ee4', '2020-07-08 00:49:13.547827', 998, 1, 28, '2020-07-08 00:49:13.547827', '2019-01-09');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('19c9e20e5a8bce0aa0eeba2348ebad8a', '2020-07-08 00:49:13.547827', 993, 1, 1, '2020-07-08 00:49:13.547827', '2019-01-09');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('0f1c7fc8fc7af07c135b37f5ea14c674', '2020-07-08 00:49:13.676854', 975, 1, 30, '2020-07-08 00:49:13.676854', '2020-03-05');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('c7e4c3de63be0fcde63ef3241e3799dc', '2020-07-08 00:49:13.676854', 983, 1, 17, '2020-07-08 00:49:13.676854', '2020-03-05');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('7da0eb619b64c9a818b5ee6785235cf8', '2020-07-08 00:49:13.676854', 1002, 1, 12, '2020-07-08 00:49:13.676854', '2020-03-05');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('1131406f4281cec134e65d5bac3769eb', '2020-07-08 00:49:13.676854', 995, 1, 5, '2020-07-08 00:49:13.676854', '2020-03-05');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('46b0cae349e3c00ceac6f19b1faaa699', '2020-07-08 00:49:13.676854', 991, 1, 46, '2020-07-08 00:49:13.676854', '2020-03-05');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('5c96f99332e848a57d3b7e6391967ff9', '2020-07-08 00:49:13.676854', 978, 1, 7, '2020-07-08 00:49:13.676854', '2020-03-05');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('71d5310d0b350317ba047ca6291ecc7d', '2020-07-08 00:49:13.875118', 996, 1, 6, '2020-07-08 00:49:13.875118', '2018-07-17');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('10650fadc85e00c8815aea158792f1ce', '2020-07-08 00:49:13.875118', 987, 1, 9, '2020-07-08 00:49:13.875118', '2018-07-17');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('8ccc46a621321a7b736b008e25cee1eb', '2020-07-08 00:49:13.875118', 989, 1, 15, '2020-07-08 00:49:13.875118', '2018-07-17');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('7f441dd8d7c14713bd1cccc1bdd7de2c', '2020-07-08 00:49:14.038662', 1001, 1, 12, '2020-07-08 00:49:14.038662', '2020-01-16');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('28ec65d0c74f3beb6948bb902442a9b5', '2020-07-08 00:49:14.038662', 1003, 1, 3, '2020-07-08 00:49:14.038662', '2020-01-16');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('ea2276158e7352a62f0018d31ade8d1f', '2020-07-08 00:49:14.038662', 999, 1, 13, '2020-07-08 00:49:14.038662', '2020-01-16');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('4afe2e1d933c2e5bea45512c1498d0ac', '2020-07-08 00:49:14.038662', 974, 1, 34, '2020-07-08 00:49:14.038662', '2020-01-16');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('6893db5075ef38a136c41590a8862315', '2020-07-08 00:49:14.038662', 977, 1, 29, '2020-07-08 00:49:14.038662', '2020-01-16');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('e0b650f4c928b0cc32e84ff05e83e863', '2020-07-08 00:49:14.038662', 994, 1, 5, '2020-07-08 00:49:14.038662', '2020-01-16');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('94e966ff10e9390534a7b4bb7a7dca12', '2020-07-08 00:49:14.208034', 972, 1, 1, '2020-07-08 00:49:14.208034', '2020-03-22');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('d565750fe8ca2a767432d3f69ff3e1ca', '2020-07-08 00:49:14.208034', 999, 1, 16, '2020-07-08 00:49:14.208034', '2020-03-22');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('0761641d9d94a45d01c9587f12c0aef5', '2020-07-08 00:49:15.024506', 987, 1, 37, '2020-07-08 00:49:15.024506', '2019-11-12');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('e8670b75daf3a9ef82d7c9b54c41eaa3', '2020-07-08 00:49:15.024506', 996, 1, 16, '2020-07-08 00:49:15.024506', '2019-11-12');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('17afe2c50b4330b4ff3688e49523bd10', '2020-07-08 00:49:15.024506', 972, 1, 1, '2020-07-08 00:49:15.024506', '2019-11-12');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('53ac6e7767d4b0a9430b5c6d969461e8', '2020-07-08 00:49:15.161717', 986, 1, 1, '2020-07-08 00:49:15.161717', '2018-06-06');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('c9fa08d56e24c500217547e22ff21ee9', '2020-07-08 00:49:15.161717', 997, 1, 16, '2020-07-08 00:49:15.161717', '2018-06-06');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('f3d9ae75a8170be9eb28d56940236f06', '2020-07-08 00:49:15.161717', 980, 1, 66, '2020-07-08 00:49:15.161717', '2018-06-06');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('196fbf76d3f9e866594158cad276961f', '2020-07-08 00:49:15.303475', 972, 1, 1, '2020-07-08 00:49:15.303475', '2019-08-31');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('5e9db218d08fab653e86cb45b57c6e4c', '2020-07-08 00:49:15.303475', 980, 1, 29, '2020-07-08 00:49:15.303475', '2019-08-31');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('41546766c0ddd548546cfdbd5a25daf6', '2020-07-08 00:49:15.303475', 987, 1, 36, '2020-07-08 00:49:15.303475', '2019-08-31');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('605275dbd723d6effc0700037b9812de', '2020-07-08 00:49:15.303475', 979, 1, 14, '2020-07-08 00:49:15.303475', '2019-08-31');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('9babfc58f8a43dfb4a00605010e4c9a8', '2020-07-08 00:49:15.303475', 975, 1, 25, '2020-07-08 00:49:15.303475', '2019-08-31');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('58a866562478087b29e61dbbcced5da3', '2020-07-08 00:49:15.303475', 990, 1, 23, '2020-07-08 00:49:15.303475', '2019-08-31');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('74bbec938b63b0d8f344bfcea46b373e', '2020-07-08 00:49:15.502139', 994, 1, 2, '2020-07-08 00:49:15.502139', '2019-09-01');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('f372e4e56c589fe1c71205fec04b914c', '2020-07-08 00:49:15.502139', 997, 1, 7, '2020-07-08 00:49:15.502139', '2019-09-01');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('8b355a79f005b7e5b2f73bc7e8dca956', '2020-07-08 00:49:15.502139', 973, 1, 9, '2020-07-08 00:49:15.502139', '2019-09-01');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('9bf7043c8c30ce572f82dc830b45fe8f', '2020-07-08 00:49:15.502139', 982, 1, 9, '2020-07-08 00:49:15.502139', '2019-09-01');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('abb09c3111811a30b76c2a50f7f7f648', '2020-07-08 00:49:15.502139', 978, 1, 6, '2020-07-08 00:49:15.502139', '2019-09-01');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('1c1daa927ff08a2b37e4a21aa1412d34', '2020-07-08 00:49:15.665161', 999, 1, 4, '2020-07-08 00:49:15.665161', '2020-05-24');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('2eadefe07acfbebb1718241e7d8681ef', '2020-07-08 00:49:15.665161', 994, 1, 8, '2020-07-08 00:49:15.665161', '2020-05-24');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('f4efb1963f0d9a089e33696f5b9196d0', '2020-07-08 00:49:15.665161', 1001, 1, 5, '2020-07-08 00:49:15.665161', '2020-05-24');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('56f71761d09f319c2e03eb5cdad2b464', '2020-07-08 00:49:15.665161', 971, 1, 7, '2020-07-08 00:49:15.665161', '2020-05-24');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('79af9ed295df45039af353818c0dbb44', '2020-07-08 00:49:15.819776', 991, 1, 59, '2020-07-08 00:49:15.819776', '2019-11-19');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('0f7309ce4c566a06c8160ffdbe76935e', '2020-07-08 00:49:15.819776', 996, 1, 16, '2020-07-08 00:49:15.819776', '2019-11-19');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('187b565dcbe4e03e2bd100fb4fa80c4c', '2020-07-08 00:49:15.940383', 1004, 1, 15, '2020-07-08 00:49:15.940383', '2020-02-10');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('e400976dd524869f9cbd574b36273dd8', '2020-07-08 00:49:15.940383', 982, 1, 7, '2020-07-08 00:49:15.940383', '2020-02-10');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('7fab24fe8b8bb3cc434d2501076d8409', '2020-07-08 00:49:15.940383', 990, 1, 45, '2020-07-08 00:49:15.940383', '2020-02-10');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('d563cf849833f272ca07ea9ba925b388', '2020-07-08 00:49:16.079758', 989, 1, 54, '2020-07-08 00:49:16.079758', '2020-06-21');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('236eaa6f084983d5d6227191a916e434', '2020-07-08 00:49:16.079758', 979, 1, 12, '2020-07-08 00:49:16.079758', '2020-06-21');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('3740fafe2582b5bab05ff77d74da4db2', '2020-07-08 00:49:16.079758', 969, 1, 1, '2020-07-08 00:49:16.079758', '2020-06-21');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('50fa1aded0b1c60bf5c8334ef8222644', '2020-07-08 00:49:16.079758', 1000, 1, 1, '2020-07-08 00:49:16.079758', '2020-06-21');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('2472960f243b164066b63f24f5b42897', '2020-07-08 00:49:16.079758', 1005, 1, 1, '2020-07-08 00:49:16.079758', '2020-06-21');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('8e4aa308c89db618fd9143a4d233415f', '2020-07-08 00:49:16.079758', 988, 1, 21, '2020-07-08 00:49:16.079758', '2020-06-21');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('8cda2c1892c52c98c59a381fd98a4055', '2020-07-08 00:49:16.258535', 998, 1, 18, '2020-07-08 00:49:16.258535', '2019-08-22');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('c5232557ef57b3e992c744f70e06038c', '2020-07-08 00:49:16.258535', 999, 1, 4, '2020-07-08 00:49:16.258535', '2019-08-22');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('0375910eab17bad1365f06aabad6a238', '2020-07-08 00:49:16.258535', 995, 1, 3, '2020-07-08 00:49:16.258535', '2019-08-22');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('7b319b2eb0093dc1d9e29add9adca7a1', '2020-07-08 00:49:16.258535', 1002, 1, 16, '2020-07-08 00:49:16.258535', '2019-08-22');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('80fb45df84b442955123714896c25916', '2020-07-08 00:49:16.258535', 986, 1, 1, '2020-07-08 00:49:16.258535', '2019-08-22');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('8a6cfd85ed001bf1b354bf5bc5780013', '2020-07-08 00:49:16.258535', 980, 1, 1, '2020-07-08 00:49:16.258535', '2019-08-22');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('e9a73620e721c6ad69fa5f43e2358111', '2020-07-08 00:49:16.431045', 996, 1, 2, '2020-07-08 00:49:16.431045', '2020-05-25');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('0d26ed9ff1e1395dde1aace745de394e', '2020-07-08 00:49:16.431045', 1005, 1, 1, '2020-07-08 00:49:16.431045', '2020-05-25');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('a3e80ca9d6de6ad4b4b20f1047ef22aa', '2020-07-08 00:49:16.431045', 993, 1, 4, '2020-07-08 00:49:16.431045', '2020-05-25');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('535da1cad5c934c31f0f36c3cdf4abf7', '2020-07-08 00:49:16.431045', 974, 1, 25, '2020-07-08 00:49:16.431045', '2020-05-25');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('4ac9531d210290d31c7a48b53f204022', '2020-07-08 00:49:16.573586', 983, 1, 2, '2020-07-08 00:49:16.573586', '2019-05-12');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('779ad2cf3944372ed1078438484bbcde', '2020-07-08 00:49:16.700284', 973, 1, 5, '2020-07-08 00:49:16.700284', '2019-07-23');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('2278416f487759f6894f77ad0328ada7', '2020-07-08 00:49:16.700284', 994, 1, 3, '2020-07-08 00:49:16.700284', '2019-07-23');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('5097e22f1f7db25ab27678561e5bf303', '2020-07-08 00:49:16.700284', 988, 1, 4, '2020-07-08 00:49:16.700284', '2019-07-23');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('a29aa6b0f15d51ba33c09c7dbd5737e6', '2020-07-08 00:49:16.838632', 1001, 1, 3, '2020-07-08 00:49:16.838632', '2017-12-09');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('ce3db356e4cea9aa7379c93273a03206', '2020-07-08 00:49:16.838632', 1002, 1, 1, '2020-07-08 00:49:16.838632', '2017-12-09');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('52707ee9c6dd5ff8abbae7375cd5bddf', '2020-07-08 00:49:16.838632', 994, 1, 3, '2020-07-08 00:49:16.838632', '2017-12-09');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('9aa9ee012aeacb4c1a47f2cd31596588', '2020-07-08 00:49:16.981254', 1001, 1, 10, '2020-07-08 00:49:16.981254', '2020-06-12');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('f0ff190a07c94158754c71af2be9efcc', '2020-07-08 00:49:16.981254', 975, 1, 3, '2020-07-08 00:49:16.981254', '2020-06-12');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('90493bed284f419716ac017bb5fd795f', '2020-07-08 00:49:16.981254', 990, 1, 56, '2020-07-08 00:49:16.981254', '2020-06-12');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('9b3297260255af3a574e885c8e5b2b17', '2020-07-08 00:49:16.981254', 974, 1, 1, '2020-07-08 00:49:16.981254', '2020-06-12');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('60ecf38f9179315eb1da7a52ab403851', '2020-07-08 00:49:16.981254', 988, 1, 27, '2020-07-08 00:49:16.981254', '2020-06-12');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('b95d009f1a060a64da91cddf6728b102', '2020-07-08 00:49:16.981254', 971, 1, 1, '2020-07-08 00:49:16.981254', '2020-06-12');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('cad76954f603d405c59cf590934da6df', '2020-07-08 00:49:17.162104', 993, 1, 1, '2020-07-08 00:49:17.162104', '2019-11-21');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('2cf4874639129cbc88720647ad3a5d1c', '2020-07-08 00:49:17.162104', 982, 1, 13, '2020-07-08 00:49:17.162104', '2019-11-21');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('75ea2dc6624dfa69aa8d415978170597', '2020-07-08 00:49:17.162104', 972, 1, 1, '2020-07-08 00:49:17.162104', '2019-11-21');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('644b18b6434f79fc307bc0e6e27ddcfd', '2020-07-08 00:49:17.162104', 1005, 1, 1, '2020-07-08 00:49:17.162104', '2019-11-21');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('c6918ebb2be6370a5831d1bf19387350', '2020-07-08 00:49:17.333682', 985, 1, 10, '2020-07-08 00:49:17.333682', '2020-06-04');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('292826848bcde6578149b90dc36247e8', '2020-07-08 00:49:17.333682', 967, 1, 15, '2020-07-08 00:49:17.333682', '2020-06-04');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('5aa340dd9871211d7e907e20b6c5f9b4', '2020-07-08 00:49:17.333682', 996, 1, 7, '2020-07-08 00:49:17.333682', '2020-06-04');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('835a499eac0f2338a8130ac9ce9bf612', '2020-07-08 00:49:17.333682', 977, 1, 40, '2020-07-08 00:49:17.333682', '2020-06-04');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('461bdfeea9a3f701df9c28d3feafcbb0', '2020-07-08 00:49:17.333682', 991, 1, 58, '2020-07-08 00:49:17.333682', '2020-06-04');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('19cd7b0d69bdc1424bd6643d4d7e2574', '2020-07-08 00:49:17.485578', 987, 1, 36, '2020-07-08 00:49:17.485578', '2020-06-07');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('5f5197a2d8b0cd4b36be9c3efeb81075', '2020-07-08 00:49:17.485578', 969, 1, 8, '2020-07-08 00:49:17.485578', '2020-06-07');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('0865bc3f9b94f1a34c7d71f86bc8ef8f', '2020-07-08 00:49:17.485578', 992, 1, 5, '2020-07-08 00:49:17.485578', '2020-06-07');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('1dd6672db063920b4a20433e9bb4ab36', '2020-07-08 00:49:17.485578', 995, 1, 4, '2020-07-08 00:49:17.485578', '2020-06-07');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('1e86cf1e6821bf8cab7baf12387f986f', '2020-07-08 00:49:17.485578', 972, 1, 1, '2020-07-08 00:49:17.485578', '2020-06-07');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('bc253c746f7e0c64e1fb80cdbd1c7a21', '2020-07-08 00:49:17.741856', 987, 1, 49, '2020-07-08 00:49:17.741856', '2017-12-27');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('0efd4933f264a3a583a58d8018d55289', '2020-07-08 00:49:17.88203', 999, 1, 16, '2020-07-08 00:49:17.88203', '2020-06-02');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('26520921379f02c5aeced46b9026c423', '2020-07-08 00:49:17.88203', 977, 1, 12, '2020-07-08 00:49:17.88203', '2020-06-02');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('eecd35b3026af2e905bb8905ca354ecf', '2020-07-08 00:49:18.023204', 999, 1, 23, '2020-07-08 00:49:18.023204', '2020-04-09');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('68786d77ca6e2ecdfffadb32e4324a56', '2020-07-08 00:49:18.023204', 994, 1, 4, '2020-07-08 00:49:18.023204', '2020-04-09');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('217384c9ecce2fa3d23386127781f7c4', '2020-07-08 00:49:18.023204', 981, 1, 18, '2020-07-08 00:49:18.023204', '2020-04-09');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('76d5357b164b8a3f57eca76f88740a35', '2020-07-08 00:49:18.023204', 967, 1, 24, '2020-07-08 00:49:18.023204', '2020-04-09');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('a5dd5619d3c4d4bde155b14e0a405996', '2020-07-08 00:49:18.174498', 986, 1, 1, '2020-07-08 00:49:18.174498', '2017-11-09');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('3db5984f65eb9366b219be11f46e1977', '2020-07-08 00:49:18.174498', 987, 1, 6, '2020-07-08 00:49:18.174498', '2017-11-09');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('f0101967637690f1c3c4b1fb2b150669', '2020-07-08 00:49:18.302184', 987, 1, 48, '2020-07-08 00:49:18.302184', '2020-02-22');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('2a73a84fa2057580326bc8f6bf87cabd', '2020-07-08 00:49:18.302184', 971, 1, 2, '2020-07-08 00:49:18.302184', '2020-02-22');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('bc626a79d090b6043f487d6f9b74f21b', '2020-07-08 00:49:18.302184', 973, 1, 14, '2020-07-08 00:49:18.302184', '2020-02-22');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('8565db8e1e61013dc272b0e34d581598', '2020-07-08 00:49:18.302184', 977, 1, 13, '2020-07-08 00:49:18.302184', '2020-02-22');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('014f6087f4dd82cfefdb3b86d37a59e4', '2020-07-08 00:49:18.474251', 976, 1, 13, '2020-07-08 00:49:18.474251', '2018-09-26');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('694b5d5f9119f1fc2e38525449325fb4', '2020-07-08 00:49:18.474251', 992, 1, 2, '2020-07-08 00:49:18.474251', '2018-09-26');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('eb35a8e18d939480db1dbc4958b5920b', '2020-07-08 00:52:44.367795', 984, 1, 1, '2020-07-08 00:52:44.367795', '2019-05-29');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('e497f9fee2c8cc5fbf694541e00dfd33', '2020-07-08 00:52:44.367795', 978, 1, 7, '2020-07-08 00:52:44.367795', '2019-05-29');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('d4a7f20e0976cd44d21de1c73fc2fd8b', '2020-07-08 00:52:44.506324', 997, 1, 9, '2020-07-08 00:52:44.506324', '2020-05-12');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('15d217a97351f2e9a81936d00d12864d', '2020-07-08 00:52:44.506324', 975, 1, 32, '2020-07-08 00:52:44.506324', '2020-05-12');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('9a9000584d26408471f27e069039fe04', '2020-07-08 00:52:44.506324', 1005, 1, 1, '2020-07-08 00:52:44.506324', '2020-05-12');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('c74c72e5f9600caa180ad4217ab2efbb', '2020-07-08 00:52:44.506324', 976, 1, 1, '2020-07-08 00:52:44.506324', '2020-05-12');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('0b3243ecb2ee9c4bd8bbb62370d9c231', '2020-07-08 00:52:44.65562', 996, 1, 6, '2020-07-08 00:52:44.65562', '2020-07-06');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('c21f82751c8d6571150f2afd8fa1ddf3', '2020-07-08 00:52:44.65562', 968, 1, 9, '2020-07-08 00:52:44.65562', '2020-07-06');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('be7cc9d3aa94cfbdc521cf40755c7165', '2020-07-08 00:52:44.65562', 969, 1, 1, '2020-07-08 00:52:44.65562', '2020-07-06');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('495aa9ec50eca6324e709ba257548a67', '2020-07-08 00:52:44.65562', 970, 1, 6, '2020-07-08 00:52:44.65562', '2020-07-06');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('1a6d235bfebd7dcf3b58d8942f1a08e0', '2020-07-08 00:52:44.65562', 994, 1, 1, '2020-07-08 00:52:44.65562', '2020-07-06');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('21d5f5f39b6eb23c4c0aa968b82f6d8f', '2020-07-08 00:52:44.65562', 983, 1, 6, '2020-07-08 00:52:44.65562', '2020-07-06');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('caec4a434e72436513d69d815b0772df', '2020-07-08 00:52:44.821527', 1002, 1, 15, '2020-07-08 00:52:44.821527', '2015-08-23');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('0b4e8c612f8f78394123a4b2620a4bdf', '2020-07-08 00:52:44.940642', 975, 1, 12, '2020-07-08 00:52:44.940642', '2019-11-16');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('76da9c12d98ad5fe3cff25a438218240', '2020-07-08 00:52:45.054959', 977, 1, 10, '2020-07-08 00:52:45.054959', '2020-06-28');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('f57b0a5e7f51999a7ef0ab88ac63c1a7', '2020-07-08 00:52:45.054959', 979, 1, 3, '2020-07-08 00:52:45.054959', '2020-06-28');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('2938844e4997b84c143e96032d2df21f', '2020-07-08 00:52:45.054959', 995, 1, 7, '2020-07-08 00:52:45.054959', '2020-06-28');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('fec587745039453cff40e8121ed0ae88', '2020-07-08 00:52:45.054959', 996, 1, 1, '2020-07-08 00:52:45.054959', '2020-06-28');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('542b7e9432ee27f87f335d2e94bdbbb2', '2020-07-08 00:52:45.054959', 999, 1, 2, '2020-07-08 00:52:45.054959', '2020-06-28');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('1a94420e3421638f1c00e9bde7b3b48c', '2020-07-08 00:52:45.054959', 967, 1, 13, '2020-07-08 00:52:45.054959', '2020-06-28');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('9552bbc6672b54ae9f48eaba53bc8edf', '2020-07-08 00:52:45.235469', 976, 1, 2, '2020-07-08 00:52:45.235469', '2020-04-06');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('b6e25cd0fe6bed7dd134996578737ba7', '2020-07-08 00:52:45.235469', 967, 1, 17, '2020-07-08 00:52:45.235469', '2020-04-06');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('1eb846f59308f819607deb223df52e46', '2020-07-08 00:52:45.235469', 979, 1, 2, '2020-07-08 00:52:45.235469', '2020-04-06');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('d4fced00c1b1eed21bbe911bee05ddf1', '2020-07-08 00:52:45.374349', 998, 1, 19, '2020-07-08 00:52:45.374349', '2020-02-22');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('040b52242b889462f0f7cff529e499b1', '2020-07-08 00:52:45.374349', 978, 1, 2, '2020-07-08 00:52:45.374349', '2020-02-22');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('4dd6a6ebcbfdb8c47f3bff3eeca8f2cc', '2020-07-08 00:52:45.374349', 969, 1, 3, '2020-07-08 00:52:45.374349', '2020-02-22');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('cd0aaee155151b6d2c2c1442050c9dab', '2020-07-08 00:52:45.374349', 985, 1, 20, '2020-07-08 00:52:45.374349', '2020-02-22');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('bb63c26907cd65e61957a60a410f2b36', '2020-07-08 00:52:45.374349', 984, 1, 1, '2020-07-08 00:52:45.374349', '2020-02-22');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('6fdc1a9b56180c80103dd0d35d60f3e0', '2020-07-08 00:52:45.374349', 1004, 1, 7, '2020-07-08 00:52:45.374349', '2020-02-22');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('6699084e3e9ac99d81247f6e03abe6bd', '2020-07-08 00:52:45.556082', 976, 1, 5, '2020-07-08 00:52:45.556082', '2019-09-26');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('f79e47f673d8a8039a350a93831d60b6', '2020-07-08 00:52:45.556082', 977, 1, 1, '2020-07-08 00:52:45.556082', '2019-09-26');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('784eeb6a1d280fe9cb98fb3f3c91f36e', '2020-07-08 00:52:45.556082', 975, 1, 8, '2020-07-08 00:52:45.556082', '2019-09-26');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('cb6063f3ef750d0482434bee2a2e226a', '2020-07-08 00:52:45.556082', 993, 1, 1, '2020-07-08 00:52:45.556082', '2019-09-26');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('830b266d4389a1e6761314b6a72482d4', '2020-07-08 00:52:45.556082', 982, 1, 4, '2020-07-08 00:52:45.556082', '2019-09-26');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('18e10e9586906e17cb068f9998fa5276', '2020-07-08 00:52:45.556082', 999, 1, 3, '2020-07-08 00:52:45.556082', '2019-09-26');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('d8a7ff64241bbd7f5a35597fcaf550a7', '2020-07-08 00:52:45.732966', 977, 1, 1, '2020-07-08 00:52:45.732966', '2018-11-26');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('4c0984b098e1a604db63341069153269', '2020-07-08 00:52:45.831272', 974, 1, 13, '2020-07-08 00:52:45.831272', '2020-06-11');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('1743a4d7d189ffac7884abc5caaf99ce', '2020-07-08 00:52:45.831272', 996, 1, 7, '2020-07-08 00:52:45.831272', '2020-06-11');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('df5de09c6bc3cde525a9d8c7d41263d4', '2020-07-08 00:52:45.831272', 971, 1, 1, '2020-07-08 00:52:45.831272', '2020-06-11');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('da230992f205f706106c89fe5731d8d5', '2020-07-08 00:52:45.831272', 994, 1, 1, '2020-07-08 00:52:45.831272', '2020-06-11');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('107c3a9e5f2677e2afae7c9516c2ae06', '2020-07-08 00:52:45.831272', 981, 1, 5, '2020-07-08 00:52:45.831272', '2020-06-11');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('6907b65eab4f7b877a853ccae9c576f5', '2020-07-08 00:52:46.011747', 978, 1, 4, '2020-07-08 00:52:46.011747', '2019-08-19');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('e6ddbf78e54f83c342adc363502ca50c', '2020-07-08 00:52:46.011747', 989, 1, 15, '2020-07-08 00:52:46.011747', '2019-08-19');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('fe06a5d9ef76c923c53001126529ac9d', '2020-07-08 00:52:46.011747', 987, 1, 18, '2020-07-08 00:52:46.011747', '2019-08-19');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('cfbdfb94e9e08184cf2a2db80740d929', '2020-07-08 00:52:46.011747', 1002, 1, 16, '2020-07-08 00:52:46.011747', '2019-08-19');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('547015138ce3aabd0bafb48b30c2f489', '2020-07-08 00:52:46.011747', 995, 1, 7, '2020-07-08 00:52:46.011747', '2019-08-19');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('1cbe767c591ab4fcde78a8b986519b83', '2020-07-08 00:52:46.177737', 971, 1, 1, '2020-07-08 00:52:46.177737', '2020-01-23');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('9ba7c266e9a2b13a872ab45a309f9866', '2020-07-08 00:52:46.177737', 985, 1, 1, '2020-07-08 00:52:46.177737', '2020-01-23');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('3cc92212a7cdc01f842ce2232263119d', '2020-07-08 00:52:46.177737', 979, 1, 3, '2020-07-08 00:52:46.177737', '2020-01-23');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('d0d89971e213c44575be3ed8466e595b', '2020-07-08 00:52:46.177737', 969, 1, 4, '2020-07-08 00:52:46.177737', '2020-01-23');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('c31746492415f6783b1f1b4153029425', '2020-07-08 00:52:46.177737', 982, 1, 7, '2020-07-08 00:52:46.177737', '2020-01-23');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('a9cdd3507e047dda3a158699177243fe', '2020-07-08 00:52:46.342199', 968, 1, 7, '2020-07-08 00:52:46.342199', '2020-07-06');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('d1b43063ec8a46711c5455b222d38b21', '2020-07-08 00:52:46.342199', 1001, 1, 2, '2020-07-08 00:52:46.342199', '2020-07-06');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('28fe60f58aaf2b0c67107032c1b11ed5', '2020-07-08 00:52:46.342199', 985, 1, 24, '2020-07-08 00:52:46.342199', '2020-07-06');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('e7b826fc2fe55547606098f74e7c6f36', '2020-07-08 00:52:46.476954', 975, 1, 27, '2020-07-08 00:52:46.476954', '2020-05-28');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('b4b20e3f80ec26f482f722344e9bd164', '2020-07-08 00:52:46.586166', 985, 1, 8, '2020-07-08 00:52:46.586166', '2017-06-06');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('31a1fbd7bb68a79a365af3ea84b9b217', '2020-07-08 00:52:46.699609', 982, 1, 6, '2020-07-08 00:52:46.699609', '2019-03-05');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('c7af6663a454e798c6bf16b5c6b13273', '2020-07-08 00:52:46.699609', 983, 1, 12, '2020-07-08 00:52:46.699609', '2019-03-05');
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "quantity", "consume_ts", "date") VALUES ('74a4871ea3e062832124ef4e90a2e401', '2020-07-08 00:52:46.699609', 976, 1, 4, '2020-07-08 00:52:46.699609', '2019-03-05');


--
-- Data for Name: consume_using; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('79e86107173ce4a320768d5e3ef3778c', 'bfc0bfffe4427d00c1443738ff7dcafc');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('c6db4c9cbdb130669e2c8d59434d8bc4', 'bfc0bfffe4427d00c1443738ff7dcafc');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('efafd285d1a97b77d088011480570bbb', 'c97f06277101990d58e1dbf1bcc611fe');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('4c39a4892e8731b8591ce111b99816ad', 'c97f06277101990d58e1dbf1bcc611fe');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('de1f24bfd088ed44b52133c16dea9a2c', 'c97f06277101990d58e1dbf1bcc611fe');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('6881e3c8f412209611c1380365dced3b', '5ffe1b0204bf8dd0f1ee688299ef790f');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('70db274329982ac2124acda343a9b59f', '5ffe1b0204bf8dd0f1ee688299ef790f');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('44c7891c9aaac21cbb8d2bd94be74e56', '5ffe1b0204bf8dd0f1ee688299ef790f');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('822eae7a756d2ccafbec8fcf48602fe4', '9e08241a3fdcbe3d98d29955a1abc091');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('e4fa6570b27c876670b4b25aceed6fe4', '48d07c7f98c102cd4b2913ef8f703394');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('8fd15efed1bbf04c4c0f943be47e7441', '09509dc742f04ad80f00ee9823ac1bbb');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('a30f8c51e8e58bf6aa584e6e696e43cd', '09509dc742f04ad80f00ee9823ac1bbb');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('6cb0a7ec85bc7ef375954d87022b1fe5', '09509dc742f04ad80f00ee9823ac1bbb');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('4e9ae7a9a8f5c295678229916124de5a', '09509dc742f04ad80f00ee9823ac1bbb');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('78778f531e89f923e84c1584ab94b994', '09509dc742f04ad80f00ee9823ac1bbb');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('63b76034db30e058518308d1e62a39bd', '0e01087c5cc7ad8b2bd841dc7f28e145');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('46f390fad15a4a975e486e0b1af29bb0', '0e01087c5cc7ad8b2bd841dc7f28e145');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('b7da63eba4815c11d06ae58ac4d489ca', '0e01087c5cc7ad8b2bd841dc7f28e145');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('87a901fbda836f2597f0baabdd877bfe', '07050dc3fea0deca94f34d0ff59e698b');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('ae0d923bcf4c358e938662396ef17019', '07050dc3fea0deca94f34d0ff59e698b');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('da5307887c3b47e341803852fe63aef6', '07050dc3fea0deca94f34d0ff59e698b');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('2d8c820bdaad953f9f5da569f5f99ab5', '07050dc3fea0deca94f34d0ff59e698b');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('3ca763c16bbb7886d65a5aa9892f8abd', '07050dc3fea0deca94f34d0ff59e698b');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('96f371c2c841b371e9f01b5ab6670db7', '8f1deac07ca16ac59a921764f49dac6f');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('cb8ce749ebb980b502bb2f3ec92741c9', '8f1deac07ca16ac59a921764f49dac6f');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('3d62fe92f73e2e12316c13aa6c9f1593', '8f1deac07ca16ac59a921764f49dac6f');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('7279c06cbe65d36cd394072d33ca0854', '8f1deac07ca16ac59a921764f49dac6f');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('574bf30944d7c42571f371bd70d6de49', '8f1deac07ca16ac59a921764f49dac6f');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('4bdf10086039842b23ddb7cf1ce2b6bb', '209a6bbbec20bf120c482b1971fc9a86');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('4261385d162079f70b0f89f01f7573b4', '209a6bbbec20bf120c482b1971fc9a86');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('7bbd05a127521904eec21f40e8b1c070', 'feec65308df108cc5ab4531b5f8b1b5a');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('3d302786fb04a60fa21357b24071442d', 'feec65308df108cc5ab4531b5f8b1b5a');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('d9a760826e458f86a705fb30988ce3d0', 'feec65308df108cc5ab4531b5f8b1b5a');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('3cb8e6eb07a98719ed6b2a08bc25a945', 'feec65308df108cc5ab4531b5f8b1b5a');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('101dabac2f02ee47995065481e1a00b5', '5c2a7ae114c5b4f7fc006ffd54669d3a');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('f198b3a705019e764e37c92a4c945fae', '67773a3120921c0a09f8e95552b0a3fd');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('10f3a38c4e801c8f87e47ba3316bb476', '67773a3120921c0a09f8e95552b0a3fd');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('820507aa839744da422acb37d04eaa1f', '67773a3120921c0a09f8e95552b0a3fd');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('5aee037debb6b6c879edab5e1904f88a', '902a8bf2cac69ecec3902fccb824d885');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('61b1ec4dd3b521ccc1f427dded0c2655', '902a8bf2cac69ecec3902fccb824d885');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('6f1fa4f14227982dc47a4ea0a1c00af2', '902a8bf2cac69ecec3902fccb824d885');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('6abc32dcce505db5e8d2733ad5e21592', '902a8bf2cac69ecec3902fccb824d885');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('10e5d3b156429f98878acfbb17052123', '902a8bf2cac69ecec3902fccb824d885');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('43420a787e9a7ec58c86be1298138168', '8c17aac3ef9069baa2b395f54b87bc29');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('b92445b73d5346c7afe2b8be73312d56', '8c17aac3ef9069baa2b395f54b87bc29');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('8b215644a2eac602082e53cd1c9a5967', '8c17aac3ef9069baa2b395f54b87bc29');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('384f584fbafeeb7d7bac1445dcfde6d0', 'ec65a81a825f51bbf55517dee7ac2ee1');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('caf89f0b2b78dd9090e812897f81e208', 'ec65a81a825f51bbf55517dee7ac2ee1');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('698612a80baa8b54da873d81cc24af5e', 'c56efdf9e1929defd261f66b215f1c5b');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('8633d2399b8c7faebe67f3b23aead8fb', 'c56efdf9e1929defd261f66b215f1c5b');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('270325029997fb2c43d93db69b1b33be', 'c56efdf9e1929defd261f66b215f1c5b');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('ce3fac7ec0b3eaa5defbfc9b013b19a0', 'c56efdf9e1929defd261f66b215f1c5b');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('1ab7c8e50c099476705951bf57eb6aee', '527d64e9f7819965cc25e152dac820ed');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('48858e7b74fbfba8a8faf4b6c0177a72', '527d64e9f7819965cc25e152dac820ed');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('4631548f3d293cae30b5c4a44563aacb', '527d64e9f7819965cc25e152dac820ed');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('8b902cb7c1017fe77e7301a94289d618', '527d64e9f7819965cc25e152dac820ed');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('e08fc2cf32df940e0cbf665715a1fd96', '527d64e9f7819965cc25e152dac820ed');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('6281752c0b7266d9d4d9295ada44cbbe', '527d64e9f7819965cc25e152dac820ed');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('2d9a26be6f4a81b242430587a0699ab8', 'be6d1bdecb2fbbaa99abfeddeddce7bb');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('4f13b542d92fdfca7c774507d1b0c360', 'de49acd5d2e0aabf332d2c477a468ce7');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('0432072296062511f19bfa6f749cb4f1', 'de49acd5d2e0aabf332d2c477a468ce7');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('7866994e2f1957cbbfd1ca54efcef20b', 'de49acd5d2e0aabf332d2c477a468ce7');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('b78fc2c1ffe0806c624ad30d574ac6c5', 'de49acd5d2e0aabf332d2c477a468ce7');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('359ef8a7824c1bb8a1e8f02924c9578c', 'de49acd5d2e0aabf332d2c477a468ce7');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('ac67e74d6a1333e8320d1339078ab26b', 'de49acd5d2e0aabf332d2c477a468ce7');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('4e6f7b706adb06f98b0c7b2721713c40', '575f8ec6389e33e05ca89aa2b03b16cb');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('844c3857ea0960a0c510ab8f62d7f0b5', '575f8ec6389e33e05ca89aa2b03b16cb');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('c9b27bfebe38e204d28bc3de75c0ab46', 'b97b5a2241597dcb0d0a286aa3c2b72a');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('d2b83c67ea1617cb204762c96e782b77', 'b97b5a2241597dcb0d0a286aa3c2b72a');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('9fba58ff47348a3675f1a47baa71a32b', 'b97b5a2241597dcb0d0a286aa3c2b72a');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('432365d18800017ef76cd945d631c177', 'b97b5a2241597dcb0d0a286aa3c2b72a');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('b61d6b14051084fe6fbbe66af0306c47', 'f4fb843feed1d47cb67de5e951b8ed25');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('fd4467554c3b3d90e09bb93a27b8572c', 'f4fb843feed1d47cb67de5e951b8ed25');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('dc7955476b390cbe2c0597895dffc447', 'f4fb843feed1d47cb67de5e951b8ed25');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('739f9f36975b76e72d2037dda6a85f7a', '55fd5331b4a67abff8f2a4bb1dbe7c5f');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('3355ba69ae8a779a61b19b72472b4790', '55fd5331b4a67abff8f2a4bb1dbe7c5f');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('08de759a1a7d9ea194431395b514693d', '218f3fa909b15752467d271fa224c5f1');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('93d2eb4b5637f81f42aca0d2cbb06720', '218f3fa909b15752467d271fa224c5f1');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('a1cb089c3311eb1278002cd74a3c9afd', '218f3fa909b15752467d271fa224c5f1');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('5cc52f646ee591131f1f54afcb7ec73b', '218f3fa909b15752467d271fa224c5f1');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('830cef0858375587499d39446f70bd48', '218f3fa909b15752467d271fa224c5f1');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('a3fcbed3a86c9ac71aa5220b5868e5bd', '218f3fa909b15752467d271fa224c5f1');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('113a7698f0ffbcbbbe706de3fb4b38d4', 'ba5b102a10d22ec34dae97a7c2cad677');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('4d650fc4975d416706aab3e39b9caef9', 'ba5b102a10d22ec34dae97a7c2cad677');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('0ba6a6dcf54b5b4061db8fc61a74bb21', 'ba5b102a10d22ec34dae97a7c2cad677');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('8bab6c519e7173965f0e9a4e842b9839', 'ba5b102a10d22ec34dae97a7c2cad677');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('764e8206bf748153f73aa70e78f6b583', 'ba5b102a10d22ec34dae97a7c2cad677');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('028d54cfa391090e25b9c231f647d248', '0cf56a304a4826bdef3e2f25e468f675');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('82c19e96bf7e636e6ec5b5a91ab3cd08', '0cf56a304a4826bdef3e2f25e468f675');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('f81520bf0997a38a59200fc8b83b9b7a', '0cf56a304a4826bdef3e2f25e468f675');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('45cc12f2d687844b2a29f038ffd4323e', '0cf56a304a4826bdef3e2f25e468f675');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('739a589598197cde0bb9f542c3afa8ec', '0cf56a304a4826bdef3e2f25e468f675');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('a3618c7164311c810de1ff1b792596ec', '0cf56a304a4826bdef3e2f25e468f675');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('af4273c87f54afb7d3347ec20082eaca', '8bef5026937e532e4a85f641292b3341');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('cdae52c4f94b1036beed588c1d938388', '8bef5026937e532e4a85f641292b3341');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('961c1afbc72b16a6e605e0b24beb7c0c', '8bef5026937e532e4a85f641292b3341');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('e505c4898600a9e31f18930036373e13', '8bef5026937e532e4a85f641292b3341');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('79af00c09e37334742b4be0b1075b46a', '8bef5026937e532e4a85f641292b3341');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('2f6758e517dafb93af26638bb6a16f3f', '8bef5026937e532e4a85f641292b3341');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('cd044cab704cb4104bcaa3c751e6691b', '53fbaeba245b14f555a4b0529a568c3d');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('1de7f6aee323e41f5b6fc7c2a519971f', '53fbaeba245b14f555a4b0529a568c3d');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('18a146b66e3e7bedb0e23d2c34c714f0', '53fbaeba245b14f555a4b0529a568c3d');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('febee04c2e6389e89ca3d604ca875e35', '53fbaeba245b14f555a4b0529a568c3d');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('63af99fadaf71017bfa50f102b40f5e9', '53fbaeba245b14f555a4b0529a568c3d');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('bc86d86dc93af21faae73160771e23a7', '53fbaeba245b14f555a4b0529a568c3d');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('ae21365aa4a970b3afbb8585c5396e82', 'b127606e8fca823f574ba3bd6aba6a51');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('0db1da7118bc93564dd1f933e8984921', 'b127606e8fca823f574ba3bd6aba6a51');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('a5678baa5332c0dc5540b879a7553fef', '702121f666a6fa59d671aebe6b2f3dc6');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('9ce9e0b9bffa1f3a2fd36a3a5067e8c8', 'b82e525688e956e9e63ca793b88060e2');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('eb05374c27db0ec7f98f19eabd62aca5', 'b82e525688e956e9e63ca793b88060e2');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('ed1ed9fa66c72eddfc586d44981df7fe', 'b82e525688e956e9e63ca793b88060e2');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('06af3f26743d7930ca99cea295685adb', 'b82e525688e956e9e63ca793b88060e2');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('a27f3f52c4d14993e9051c5cdbea3b06', 'b82e525688e956e9e63ca793b88060e2');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('c0c677ba59e8efd695ccea36d600bec4', 'b82e525688e956e9e63ca793b88060e2');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('cb591c2d01e659ec9dc2a715f7f171ff', '8c8de92c656042dc4d4b319975010209');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('4c7aa0b69d8460839242fea8d82e39d9', '8c8de92c656042dc4d4b319975010209');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('3240f0e127d31172dde7fefe9a2578ae', '8c8de92c656042dc4d4b319975010209');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('5fe5a75f77d6fee5ca1b5a94dc0f53d2', 'a6b48587bb55651be6b09aba0142f1d5');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('4a3492907b48d54d62e8e33d78545e52', 'c4fbd4d8b210363a9e45b37a66528c6b');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('ee31e4c2271f581d17aec3224e455f78', 'c4fbd4d8b210363a9e45b37a66528c6b');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('6d774b9413594b6b4501bd2881c6f7d3', 'c4fbd4d8b210363a9e45b37a66528c6b');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('4c0e0724e29d2f6455c8510191b4132a', 'c4fbd4d8b210363a9e45b37a66528c6b');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('95edea8fd73960cea72333c769312c02', '31111e4d4fd86709dc96f563ab5e64e9');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('2e3f91568d557ea4fcab2e6ef4135031', '31111e4d4fd86709dc96f563ab5e64e9');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('ff90a1a65d215a2440b8cce01234e1ad', '31111e4d4fd86709dc96f563ab5e64e9');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('f3b52255533ad4efcc55839783f3f138', 'a6d2b7226dc420a93506e12fe77701a3');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('56c0885f48a3af4754f1b0aa9b3cd250', '391bd394d082d9b042679d547290a6b6');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('289c7a39b3fc97baed1a733eaf3b05b1', '391bd394d082d9b042679d547290a6b6');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('d594cbda0c4828996437b4af30bdc8cc', '23373dbc310bcc976b5c0e15e90eab2e');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('7b2d61b50b88945c081d29dcd9bf2761', 'ef049568db442527aad823cd255d89d5');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('1c06b0532a2f9abbdbcc70d0e21aec82', '0de0deada60fa8b96f1ecc0d6a4800de');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('41ec97d62893c4ac5630d7ca833eeb32', '4384d92068b511e5b0eafc949413a508');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('57f07e539554a6db095fa17686c7fc27', '1187e55a2905d227fd4cf2f8105242ef');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('f4f2dac088f4d7ca8f8c565906b3bb44', '1187e55a2905d227fd4cf2f8105242ef');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('02ca05acc31d7ba9c474b9bb5799b06b', '1187e55a2905d227fd4cf2f8105242ef');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('b2e4796bf865526675b7a38089452585', '1187e55a2905d227fd4cf2f8105242ef');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('9fd80d3a54b3b8715c79f82ae8946cd7', '1187e55a2905d227fd4cf2f8105242ef');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('727d94f0237c987098b935ab80eb051b', 'cdf00633079ce459f076c3ff8e02d291');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('e3bef5818d39905a1333ca08e1ed5ff3', 'cdf00633079ce459f076c3ff8e02d291');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('a5a1fae932f46b0559a2f8d66948882b', 'cdf00633079ce459f076c3ff8e02d291');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('cb4329b58d0a93049b2642c37bbc17ea', '5fd877af43b6212a95ba3539b7138a80');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('cd7dad4b805550afad307d5e7565b7f0', '5fd877af43b6212a95ba3539b7138a80');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('4155f975110c5fb3e23f28cd171e5b10', '5fd877af43b6212a95ba3539b7138a80');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('e153f471c8051eb218bdc6d3d1f313f2', '5fd877af43b6212a95ba3539b7138a80');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('9edc75c260db3ff0df27364e7a47b6bf', '57841d2378ee6aed05bbca59bb601c00');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('9f0b189827aa134972909cf66903bf88', '57841d2378ee6aed05bbca59bb601c00');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('41634912120b4833d999797f86b1bc40', '57841d2378ee6aed05bbca59bb601c00');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('fbcdbc73065d5981bfa9ab189a53fb54', '57841d2378ee6aed05bbca59bb601c00');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('48f15820af62ce9baaff82af2ec74122', 'b80a5071a9f78ccd0a4b364061b34da4');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('3a90472f254822c90ca85cb0bcae0267', 'b80a5071a9f78ccd0a4b364061b34da4');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('180d6aba9da7f4bcaa7ad9d2975cd2e1', 'b80a5071a9f78ccd0a4b364061b34da4');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('9247d851b2f61e9f230c1b89ea8ca67b', 'b80a5071a9f78ccd0a4b364061b34da4');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('3596b294aafcfcd5e3e2310ee7981e41', 'b80a5071a9f78ccd0a4b364061b34da4');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('dc4091bd41109b5a45b43e35f49006c5', 'f47cac1eabb4a2759abee6ea3d67b38c');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('81aaa92f000270e87d32dee6cc845043', 'efebe2f22264f184b483b615e38a253c');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('488f7863c9f991ac01606220ab099706', 'efebe2f22264f184b483b615e38a253c');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('6d261a84c77e17962c9a2588b27520b0', 'efebe2f22264f184b483b615e38a253c');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('d4cd91be62638a8acdca7fd2d0b340f4', '53b21d506279be7ef4a030bbb7bfc8f5');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('a01fbcd22a9de3b178d7c0b09fdd9b96', '53b21d506279be7ef4a030bbb7bfc8f5');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('4543f7139d65093dbb05abfeb0e43bf5', '53b21d506279be7ef4a030bbb7bfc8f5');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('7562aff2ee3224884bbbea38f55e74c6', '53b21d506279be7ef4a030bbb7bfc8f5');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('dce27ca7fe5d752aae23fb7638d967a8', '53b21d506279be7ef4a030bbb7bfc8f5');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('289de5f557b3a25627670c473e40fab2', 'ddae773ecdc3f922d1354fc12f9866d6');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('04b98bf9b83c27856b4f6c34949ed136', 'ddae773ecdc3f922d1354fc12f9866d6');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('632415e527568f53d48305240a40a09c', 'ddae773ecdc3f922d1354fc12f9866d6');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('898f5299ae1819d054a82b0621aae72a', '8c3d5de00fe9604f72f2e24036921327');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('c30714cfd8131043e64c4d362af256c3', '8c3d5de00fe9604f72f2e24036921327');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('9551ce357286d8eb259201321aabf5ea', '8c3d5de00fe9604f72f2e24036921327');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('26546eb3379e7243c60b14580178ceb9', '7c24d1559a9d75968595708f4d69d80d');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('ddc2bc3ecd53204f27cacf0840735297', '7c24d1559a9d75968595708f4d69d80d');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('1edaef8aaa30bab19b871282232cbf2e', '7c24d1559a9d75968595708f4d69d80d');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('271167e689ceddfc7b85d3a6e7a7fd9a', '7c24d1559a9d75968595708f4d69d80d');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('00a89ed5ee94a61f5d54b2a5ff654bf3', 'b23a7525b44438490047ad681fba2ebd');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('fbccf338aa2e1827324af224e3fcb169', 'b23a7525b44438490047ad681fba2ebd');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('d7dfdd3d2a358f10280321ea416d1e93', '4d40a9884f4b0eb71e47f744c1b8b4a8');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('981df914e4bd2c9babd3a6c078b8fc03', '4d40a9884f4b0eb71e47f744c1b8b4a8');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('e30e9d6bc35f94d3dc3fade7653a4769', '4d40a9884f4b0eb71e47f744c1b8b4a8');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('20f7d1be226a786c7b0e0c5672930421', '4d40a9884f4b0eb71e47f744c1b8b4a8');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('20aa3d811d560c45a26cdb86569cf0af', '4d40a9884f4b0eb71e47f744c1b8b4a8');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('a2e66f65c16dabaf12442390a26e0b27', '4d40a9884f4b0eb71e47f744c1b8b4a8');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('32f64d85f23ade91ce9d05ee4410dfaf', 'a7c121938ed19c4ba9cf452060f209f4');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('51b97f6572f1cdfce6fdadb7996d2c49', 'a7c121938ed19c4ba9cf452060f209f4');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('04189b840fe85c5d3cdaed2a9107e6dc', 'd34b8c719b4b0a4d51b904652282699e');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('3242f5e9ad613e05696976a245e0f127', 'd34b8c719b4b0a4d51b904652282699e');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('3282834341e52455b375f3c9a9070a97', 'd34b8c719b4b0a4d51b904652282699e');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('bc1cb1fef73832e1b96aaabae1394415', 'd34b8c719b4b0a4d51b904652282699e');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('b5ce116acbf072ab3a0217938e958a25', 'd34b8c719b4b0a4d51b904652282699e');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('6b52a4dbfd1880dac0f4769eda63c60c', 'd34b8c719b4b0a4d51b904652282699e');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('f01ef170a17a609db632f4ea67e9798f', '37c0b81a4f3f1720ae120a07bf0c18f4');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('b65050219daa5c08627428241f8ef8d3', '8a91804a02f6544b2ee2565996362c8b');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('8cd54b592ee9102a9bc71bbf0af37e23', '8a91804a02f6544b2ee2565996362c8b');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('8ba03da03a07bb6f632e41dcd124c9c8', '09a0d9ba401a92d203e03ceb41768cd4');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('9706494ba9fc4834c1ef1dc185267d7b', '09a0d9ba401a92d203e03ceb41768cd4');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('946260fe98b18db25486f6048ab059a1', '09a0d9ba401a92d203e03ceb41768cd4');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('53d875efc8903eb263e6024224449a1a', '09a0d9ba401a92d203e03ceb41768cd4');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('b075d3ee1a7955d95500f88403c12b90', '09a0d9ba401a92d203e03ceb41768cd4');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('f9568f6acb4de29f2339ffbf14ed08c2', '92e9e0dbacb60be592abb93d97761e8b');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('226b681d71d210afc9f97fc1eb0c0559', '92e9e0dbacb60be592abb93d97761e8b');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('5bf37f2078afa99b3e1e2294be85fb2c', '92e9e0dbacb60be592abb93d97761e8b');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('9d05bd5b494d798c011038a70f5a9f55', '92e9e0dbacb60be592abb93d97761e8b');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('06aa5df674dad4587fbd21b6a99ce740', '92e9e0dbacb60be592abb93d97761e8b');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('73a5d9e8732b848e912dfcc76b5cb2de', '92e9e0dbacb60be592abb93d97761e8b');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('9c1a161c90ea5a2b05a8aad92fc05e7d', '2be9e615388a54a4aa7e131a89b18e8f');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('e5a18532b3c29c4d8d51841e7b6f07a0', '2be9e615388a54a4aa7e131a89b18e8f');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('02341231363d688ab55ba51492eae968', '2be9e615388a54a4aa7e131a89b18e8f');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('4f0dce0b0dbadbb7d9fe066bc7151ecf', '2be9e615388a54a4aa7e131a89b18e8f');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('95151bbe92a22a5fa904023cebcece82', '2be9e615388a54a4aa7e131a89b18e8f');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('ee6767a0b8072e35e96480c440cf13ee', 'ceb502d2c43a77dad8ba5bb3292e736d');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('ee05429b3e10831ffb1b1e61be390a6e', '67ee8de4d76482be15f37154c3cd7cb0');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('42922ba44dcabee0401681a3c7a6f7ee', '83468fb8ad911493c7b2ce41c21f1b83');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('bddde09ade1b6f7b8f707a3de0b4cc48', '83468fb8ad911493c7b2ce41c21f1b83');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('0bfb1e13ab8f5affcad6ea0c54923a66', '83468fb8ad911493c7b2ce41c21f1b83');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('cb49d789a07e377f9d88f3abc52bc0f0', '83468fb8ad911493c7b2ce41c21f1b83');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('5beb9242da862eccfd41e7e2b2e19f11', '83468fb8ad911493c7b2ce41c21f1b83');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('91931928c05e40c73a7964c72b634742', 'adb030fbb53cb645ad4bd6e54b4fbb7e');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('718d615442322b94e122ba31422606c1', 'adb030fbb53cb645ad4bd6e54b4fbb7e');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('aa5b3e404462a56640e976a07143f48c', 'c44cbc6fd59daf73c00fde117450133f');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('c83a88f5f52d10ff217656d4e4ec6651', 'c44cbc6fd59daf73c00fde117450133f');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('7212660174c057e27a1e019eefcef6c4', 'c44cbc6fd59daf73c00fde117450133f');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('5c54dd16ea30493a9b78b376d53d181f', 'a39881291c261ec0be12c67487ac7b49');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('f032a26837fd8c340846f0eeff59d459', 'a39881291c261ec0be12c67487ac7b49');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('94bdce8b9639854e5257c5ed8743dd71', 'a39881291c261ec0be12c67487ac7b49');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('e281918e5f358b399f4dce33c65ed500', 'a39881291c261ec0be12c67487ac7b49');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('e26010825638f36549f83c2d6f87fa54', 'a39881291c261ec0be12c67487ac7b49');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('299ed923585c334013f2a543bbbc6241', '636a6ca797ed8b3165eef6e00f757e6b');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('1a42ca9b376bd74b390fa77ab8235a01', '636a6ca797ed8b3165eef6e00f757e6b');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('6a186c8adfe1f8b75a6e9363f58c0e41', '636a6ca797ed8b3165eef6e00f757e6b');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('2980ce6875e77ecc01b4e4d93f65df98', '636a6ca797ed8b3165eef6e00f757e6b');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('ae81b9e5e25654153eb043a863ec17c0', '636a6ca797ed8b3165eef6e00f757e6b');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('921fc3ca9f40b6e9bbe047b01d2726eb', '636a6ca797ed8b3165eef6e00f757e6b');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('487d7c719f9525494628c75f3ab5b6a7', '43edebb6d871f5db8498ab573ea89452');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('ff382a711fd33170c429d31d2b189346', '43edebb6d871f5db8498ab573ea89452');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('585ddf537b9d617a080022381574ff66', '43edebb6d871f5db8498ab573ea89452');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('e83bb3e770769d30ee76014bd4f8b11f', '43edebb6d871f5db8498ab573ea89452');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('63b073e42ae588e45451d33f6a909652', '43edebb6d871f5db8498ab573ea89452');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('e812330e8d13e2ff82fe28fe4cc02f22', '43edebb6d871f5db8498ab573ea89452');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('6ac682d93dd1c9190eb919dc1fd1f45b', 'eb6c384ea036c31025e66071682acf18');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('963a3df02a3e90208d14fa2f95edbdee', 'eb6c384ea036c31025e66071682acf18');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('e7e775ef70911da4ae773d8dbc67663a', 'eb6c384ea036c31025e66071682acf18');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('9213cbbdb379878411f602c1e4190ab7', 'eb6c384ea036c31025e66071682acf18');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('ae25fa58a7cce3ec5cd40271ece61f51', 'eb6c384ea036c31025e66071682acf18');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('efab7dd8411a5c076379840c1e37fe37', 'eb6c384ea036c31025e66071682acf18');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('d6d61b6f57cc7b6b5c1ec815ff1891dd', 'f6b0b72f2619b30f1ea89538ba2dabd6');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('05d1196ab2819cb8a83f3b5b022570ef', 'f6b0b72f2619b30f1ea89538ba2dabd6');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('cc3dc2b1aa8bc11043d361c2b499a965', 'f6b0b72f2619b30f1ea89538ba2dabd6');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('3010767caf9387be8952482cf3ac9029', 'f6b0b72f2619b30f1ea89538ba2dabd6');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('8f028188f913370ca5cafdf619e8d103', 'f6b0b72f2619b30f1ea89538ba2dabd6');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('84871f502e98e21ba16bfe37e19249cf', 'aa19bdffd51796b3703d178e2b2e9495');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('8a635b0e8ce8195dd768ac7234008d61', '0d4ceaa517b5c31729f65668e8c75358');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('1703f5dfa2eb12bdab21b162622b4a30', '0d4ceaa517b5c31729f65668e8c75358');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('6a3312f68bc9d91c5d506073bdb29267', '0d4ceaa517b5c31729f65668e8c75358');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('792f7ca741635c87cdceb7ecb5f21df1', '1311a9982c7467b15f7e0246cb848716');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('267c0513baedcbb76a4ed324e75675d5', '1311a9982c7467b15f7e0246cb848716');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('bd45cabbf7ed66dba0d99acf496404e5', '59982851b8b1e6b38f2c338837066348');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('8c85e37eb2a8d4a5ff8456d47b39d5dc', '59982851b8b1e6b38f2c338837066348');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('979a9d431248bda10753704a7d87391d', '59982851b8b1e6b38f2c338837066348');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('69a15aa6567ee8b036acf15f8694b2ee', '59982851b8b1e6b38f2c338837066348');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('a98b52b401b8987e7824f5b74cfbc589', '7e24584fcd1dcd1060681b7c1d04a919');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('9fac3d87b62e9e4124f41b913dd31436', '7e24584fcd1dcd1060681b7c1d04a919');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('162ed9e219ef9b104fad4d2ce1419f32', 'fff0f3f1c8db7e21a9657679ac644305');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('7df923e58e2a752351a4efb787cca045', 'fff0f3f1c8db7e21a9657679ac644305');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('fd4946431435363c3b69ba94707528bb', 'fff0f3f1c8db7e21a9657679ac644305');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('26c1d0027cd792c6cf961a888e65c048', '82629bb992420c0c3db1e1782247cf65');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('40269695fc620ff26f2822f06b832bd4', 'd277bad47e2ee37fc06b04e7aad32dc6');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('4fdec4084bbb422abdbeb69f501c54a4', 'd277bad47e2ee37fc06b04e7aad32dc6');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('7fd505d1169f008fc345c6484bf50f5f', 'd277bad47e2ee37fc06b04e7aad32dc6');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('4dc80730777100b6fd9ece03f514ca46', 'd277bad47e2ee37fc06b04e7aad32dc6');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('697858b5ce151ece6da24775656bcbe1', 'd277bad47e2ee37fc06b04e7aad32dc6');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('f677e3b7f61ce1a274e8434d881d0e7e', 'd277bad47e2ee37fc06b04e7aad32dc6');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('559bf2a0812dea6a2092c3259f90d8e1', '85ff9b81bd2e709ea2ccaaa3158a91dd');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('ef0cfd6f7f97a1c8ae4d3eef503d99d1', '85ff9b81bd2e709ea2ccaaa3158a91dd');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('3822e15e4d219a7b17a1b206ea280d90', 'c6d0b15025aa83a14744c696dfc4f8b3');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('b48369ff42249702814d0dea915dee09', 'c6d0b15025aa83a14744c696dfc4f8b3');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('b6e986aca8c8cd8a217d073df54e796a', 'c6d0b15025aa83a14744c696dfc4f8b3');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('d9c8d3ae6be79e5b5a4e3509753f3771', 'c6d0b15025aa83a14744c696dfc4f8b3');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('88f1df8dab6d7c0913567896c8e9dfe0', 'c6d0b15025aa83a14744c696dfc4f8b3');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('446be551eaf10ac54315c1015be6b831', 'c6d0b15025aa83a14744c696dfc4f8b3');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('d1fd459c008ca0f985a571b401eaf3c9', 'f9212111e24601c846d6931f82ce304f');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('3a6d6b0e4d0ed0219500faa2856f70a7', '1555dc0fe8821c545006ee62178cec94');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('c056ad7afa2cadc91efd9cac221fb62f', '1555dc0fe8821c545006ee62178cec94');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('f46b066cf0702a999cc7e0234ea825f4', '1555dc0fe8821c545006ee62178cec94');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('2ba455e86ccfaa2675db69ca49d6089a', '1555dc0fe8821c545006ee62178cec94');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('c92ae69da340892055ed03e383d9d313', '1555dc0fe8821c545006ee62178cec94');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('d8c8de2660611b77f41252370a180977', '1555dc0fe8821c545006ee62178cec94');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('05b3eac309746b0d9eb39c365d9724a7', '2130b9824c2e53fa0ca086a1ff1aaf66');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('ae25f35618efce8fab8de7abc78613a8', '2130b9824c2e53fa0ca086a1ff1aaf66');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('a8566a087c0b367ccad3b3ac0aafc86f', '2130b9824c2e53fa0ca086a1ff1aaf66');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('eb76b193cf8b9d05f1547368e7d702a7', '2130b9824c2e53fa0ca086a1ff1aaf66');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('214f7d737433089efa2ea2d4f30d684d', '2130b9824c2e53fa0ca086a1ff1aaf66');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('8ab0002fc0a117ad9334e96f974f08a6', 'd6644b15c9c0c0abf040e6c00b004628');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('a4bc1bd8ce6cd6066dc71a264257597b', 'd6644b15c9c0c0abf040e6c00b004628');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('eeffbdf8a4b83233c966116c2276327b', 'd6644b15c9c0c0abf040e6c00b004628');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('d0fdcae8bed564b407896bf2129e3832', 'd6644b15c9c0c0abf040e6c00b004628');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('ea218dc694c7be4e24aa1949dea5d26c', '785850a36be502d69ca1ae4c600e2f26');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('e9d3cfc06d1ed598e519ba4cee492e4c', '785850a36be502d69ca1ae4c600e2f26');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('50893c8b09ed60bedf7850cbabb82453', '785850a36be502d69ca1ae4c600e2f26');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('a2487e3996eb8c83c0cea4b4de65c774', 'bc7b3be3017376df35202c004dbe5ec3');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('497f9259127db6b94f41e39f7a55e971', 'bc7b3be3017376df35202c004dbe5ec3');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('9e5e50b2775a894680fb82085aad1d67', '20a59b0f2d35fdf06280f6894036d354');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('94ea5d608db5139a018e7c5571c0553e', '20a59b0f2d35fdf06280f6894036d354');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('c772175ac5792e0c0f3cf5040edcfccc', '20a59b0f2d35fdf06280f6894036d354');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('c011ac9b9255d64f4d77828bb4ab2874', '20a59b0f2d35fdf06280f6894036d354');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('ed2d9a44b0d88448ade429e60f810c62', '20a59b0f2d35fdf06280f6894036d354');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('6508a59e1ef20cbb67d4de4eec7ecf3f', '20a59b0f2d35fdf06280f6894036d354');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('7d365d8f31ee18b401396d51aed89372', '184301881fb14d7d0a035c909d80e8ca');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('06c7043f29646b8953cd1f5910c5b974', '51f0ca0e3ad8b040fd67457d68439bd8');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('2f93c20eb9a44b929005ab66e3e3a298', '51f0ca0e3ad8b040fd67457d68439bd8');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('cb4fd59cadfe1cae33abc9c46b8e6858', '51f0ca0e3ad8b040fd67457d68439bd8');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('b84e6d01b7bab744c47bdf9c43068855', '009ca7e9ddf3f0285eee5c68ddbc6c64');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('212233499fc31ddf49568712ccfd43eb', '713b4cb50da304d5d46eec1e2afea8a3');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('c1cff98dad44988108767215a8c2fe15', 'ea84287b6093a6148571177994358967');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('15210463283ae8cc6dd941b0c51561a7', 'b9339436008b5fdb3be4a23c8833609d');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('4544372fde352b332cc919d8996c08ff', 'b9339436008b5fdb3be4a23c8833609d');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('c9f68197b16f3a568b573d3ab6b2cd32', 'fbf43d440b3589be1c4e24d201842a1d');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('d28fd04fec2d97dffb023c544b51c780', 'fbf43d440b3589be1c4e24d201842a1d');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('6e8d6305dd15aa19826dfbdf16d474ab', 'fbf43d440b3589be1c4e24d201842a1d');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('79650c2d2510ff42b79237484af1ae39', 'fbf43d440b3589be1c4e24d201842a1d');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('bfbf2a045efb8f7706eca22204746421', 'fbf43d440b3589be1c4e24d201842a1d');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('99c87a84bc252716cc0e63d92ce2a048', 'fbf43d440b3589be1c4e24d201842a1d');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('4728c3b0a83e287507592d07d0575e0c', '406dd65c452f55c67db4cae44641e303');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('f3e51517ebfbee0cac5fefcd28789de7', '406dd65c452f55c67db4cae44641e303');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('b99cab55019d02483c7236f278d429c4', '406dd65c452f55c67db4cae44641e303');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('86316e9ab6429573daaa315f081aa0d7', '406dd65c452f55c67db4cae44641e303');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('47120bd070c82f2c9fb33e7e93ee2922', '406dd65c452f55c67db4cae44641e303');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('1cd403150c0d990c5cff4fa55609cd6b', '406dd65c452f55c67db4cae44641e303');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('2e709ea886600731ebdd0ca741334944', 'a24d705bfa0c42d6d20d77a664b10150');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('2cb78b99d6fc19a017aea01ca6040618', 'a24d705bfa0c42d6d20d77a664b10150');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('e289f56342b39533fd984762eb899ff2', '3c8fddfa71e6b08014d8d203c07c0cd3');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('178f326f4a696decdac76e8eec13851f', '3c8fddfa71e6b08014d8d203c07c0cd3');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('1a89143eab7588471fa64f37bf64f41f', '3c8fddfa71e6b08014d8d203c07c0cd3');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('b2eab3ab87c0a859ed3558f80cbeb488', '3c8fddfa71e6b08014d8d203c07c0cd3');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('47f2581b075f879db4a889fc0403dde7', '3c8fddfa71e6b08014d8d203c07c0cd3');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('93349d4c9e39c7fb876d88de8a301873', '4827fc00b2eaba41e4d44bdfad9772e2');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('c26a91a53a77f661825aebb157108eff', '4827fc00b2eaba41e4d44bdfad9772e2');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('ff5ad9c5a4b33ad4e5c3568f73f4ae51', '4827fc00b2eaba41e4d44bdfad9772e2');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('3d5b75d2c11b6a3516b44215c100385c', '4827fc00b2eaba41e4d44bdfad9772e2');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('dab12f1cec7a842e08a2c06b367f32bf', '7b61773ac307174b2d11264f5020310c');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('1f896b5a72b865b6f3f8aa203491c08b', '31de707ec8d607dd8c063b3440b307d0');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('9be5829269d2253ff37e0b8ef5c90e77', '31de707ec8d607dd8c063b3440b307d0');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('125c9ae2fcbf1dc42d8f9601e2256eb0', '31de707ec8d607dd8c063b3440b307d0');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('472e96a5bf570bb13e72e8893f87a88a', '31de707ec8d607dd8c063b3440b307d0');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('e7a000168d58369f5f737da4c6fab95c', '31de707ec8d607dd8c063b3440b307d0');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('620c3bb2cac7408d78487fd39a1b55a0', '31de707ec8d607dd8c063b3440b307d0');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('df0d15618edaa24c14118f86b07b6786', '551d62a1dbe38278a0c141a7c3f5cf07');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('f12d7c6d7500b79612d677215b87d49b', '551d62a1dbe38278a0c141a7c3f5cf07');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('71a66dc555c3b76d3f03d918370dce3e', '551d62a1dbe38278a0c141a7c3f5cf07');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('7d5676bbfdcbf9e62f78cd88f4a4e69b', '8a4254297ede04972d34bc4d0ca490ff');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('40f289bf02cd3ecdd5d486e7b8f9c9d5', '8a4254297ede04972d34bc4d0ca490ff');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('cee6427a3364616eac61f578210d62c8', '8a4254297ede04972d34bc4d0ca490ff');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('754062186abd2323c6ecc82b79cadd91', '8a4254297ede04972d34bc4d0ca490ff');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('af6547a190d3f50c8178cc709914d153', '8a4254297ede04972d34bc4d0ca490ff');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('ad51d2e338b835a4b2d1d4d7a68867d7', '8a4254297ede04972d34bc4d0ca490ff');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('85565adc9f4d52935f22374956b2c649', 'aacb7ccb3da54ac98c147eaead32a531');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('a56186642a6cbbf47c3177daebaef4af', 'aacb7ccb3da54ac98c147eaead32a531');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('d68bf08fb272c7f3bf690519b30bc9da', 'aacb7ccb3da54ac98c147eaead32a531');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('8f71d9d3f51fa83fc8e4e0be04fdc219', 'aacb7ccb3da54ac98c147eaead32a531');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('02062054ab3cb119c42d2a9a2da5f379', 'aacb7ccb3da54ac98c147eaead32a531');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('742469d773dfccf28939a1013156ce22', 'aacb7ccb3da54ac98c147eaead32a531');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('4e539d208176239a3bddf50af55c9eac', 'e4c3d668c6367becf3942d41217dcb94');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('5d1e6a8b10dd002e3067068538c8afc7', 'a83019acd7e7dbba42be246406a7c108');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('e7d74920ab8f76525f87a75d86809c1b', 'a83019acd7e7dbba42be246406a7c108');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('c454bde6ff9ee34fe6b274aa5063b1f6', 'a83019acd7e7dbba42be246406a7c108');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('c386cba98a38e282ef77af180e53e628', 'b09046dad5687605e179b2d49794c2f7');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('794cec1730847ce88e0b13d76fa91eba', 'b09046dad5687605e179b2d49794c2f7');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('4c4bcaba44580846f961699773e42f22', 'b09046dad5687605e179b2d49794c2f7');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('b4f8a983d9182309f46cd9d401ae3427', 'b09046dad5687605e179b2d49794c2f7');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('6a074b7d4a3b764312a305dff9922184', 'b09046dad5687605e179b2d49794c2f7');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('951213e03bff05784966bf0b6480378b', '1cea89293a4dc00b22543159118eeb22');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('8e22143b9f27570990bfc5f6587646ff', '1cea89293a4dc00b22543159118eeb22');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('31b19abb5ca4874101029a7275bbe1d9', '1cea89293a4dc00b22543159118eeb22');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('6a815e6871204f21650fbe2dc660f7d0', '1cea89293a4dc00b22543159118eeb22');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('98cea720c3b88221d5cbce69c7d2ff1d', '1cea89293a4dc00b22543159118eeb22');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('d7671e698dacee7cbc9d9e3fcdce1b55', '52984d175e00c594760a6e359f543038');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('a3795b9366e3e71186fd841c18d0ddab', '52984d175e00c594760a6e359f543038');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('890fca0919347571bb241acf06d586d5', '52984d175e00c594760a6e359f543038');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('83100cf029e2bbcb22bf1df76f89c198', '52984d175e00c594760a6e359f543038');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('8ed5515bece122446b1c3d944a8f9db7', 'd9f1058c3c096a388a0df1721f1c9472');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('5ae90313d80c8248d48d74a292dd0039', 'd9f1058c3c096a388a0df1721f1c9472');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('1be7f96fa47f39d703e4f8b0f611d819', 'd9f1058c3c096a388a0df1721f1c9472');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('dbf85fbec5253402a2806e91bf8d7f85', 'd9f1058c3c096a388a0df1721f1c9472');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('1bf2d15917dc3afeebaaaf9ecfc21846', 'd9f1058c3c096a388a0df1721f1c9472');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('0258a62872132340f25de8a556040376', 'babb346028b5e28ba6c7a4ff041f841d');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('f432ca8b70ebba15e669f01477e6e51e', '8c2b8fb26978f39a19fac76bafb4e7b8');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('e4acfd80c205acc4af65b97014db2405', '8c2b8fb26978f39a19fac76bafb4e7b8');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('ef6177f107b862207a6405e7b4852c12', '8c2b8fb26978f39a19fac76bafb4e7b8');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('20a3e23b1433df702692eb5e894c7b8b', '8c2b8fb26978f39a19fac76bafb4e7b8');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('ae43f63d299b371ad78dcfd94462bb85', '8c2b8fb26978f39a19fac76bafb4e7b8');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('b170df58d91b1e5db6df915e3355ff43', '8c2b8fb26978f39a19fac76bafb4e7b8');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('4770d0f4b579384d28ff066e47416fa0', 'e5433f4391863cf5a3dc58b11cbd54af');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('31b6812abe4b4e58b78e7cee11acd3a1', 'e5433f4391863cf5a3dc58b11cbd54af');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('ea59f7fa1e2e2c1b7c1b95b6389df986', 'e5433f4391863cf5a3dc58b11cbd54af');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('296e53e485e9d7648a4453cde6044d60', 'e5433f4391863cf5a3dc58b11cbd54af');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('0e28e17e50ef0800ffc821548e1866b5', 'e5433f4391863cf5a3dc58b11cbd54af');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('3a1611baed053411128b5a8e0e2df420', 'e5433f4391863cf5a3dc58b11cbd54af');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('060b2d6f4fe2b6a6d7d47bad6c446bc5', 'c7eb504470c5fd340d87e916d5b9c012');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('3cb76d2d8be65b5aa8bc1ac6d1d12e01', 'c7eb504470c5fd340d87e916d5b9c012');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('a1bbb063da5114f9384f77316ef7bb6f', 'c7eb504470c5fd340d87e916d5b9c012');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('db3bd1c455e1cbb9a5cbed5a8c11f2a4', 'c7eb504470c5fd340d87e916d5b9c012');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('da3b47843effa01e665a9868a2f3eab7', 'c7eb504470c5fd340d87e916d5b9c012');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('5a93172337757a40389e08f34d4d24d0', '38d5c053b0b4fbb06ec953fd8f4fb945');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('eb1e7e6ae0b09c1d57c1ddcd93322869', '38d5c053b0b4fbb06ec953fd8f4fb945');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('1401e15a67f19f2b04d14de5b02ab4e4', '38d5c053b0b4fbb06ec953fd8f4fb945');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('82f810b36927d064ddc8247cb22e8cbb', '38d5c053b0b4fbb06ec953fd8f4fb945');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('6b6c9727657976aa5d5118373e8cdc58', '38d5c053b0b4fbb06ec953fd8f4fb945');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('df8f1f97142f01275420bb6e02603c06', 'b28a74fecee1b19561beccc62a361cd2');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('f7955c4f48516aac573b8fa0d27de711', '56b2ecffd32013185f8074292a4d1d61');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('c1f2625e0d9e443783ac5fcdffdaf4b0', '56b2ecffd32013185f8074292a4d1d61');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('1505213e44a2363b67e2de423882073e', '56b2ecffd32013185f8074292a4d1d61');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('efcb9a69106cc97fb4323f09f6723947', '852ff00f725609f35c9d11b8e2bcbbfa');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('c13ec0ca0e86d0df7ef9aaf56071999d', '852ff00f725609f35c9d11b8e2bcbbfa');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('ec7817c61189f658d5cc17ccfb58e3c8', '852ff00f725609f35c9d11b8e2bcbbfa');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('bcfafda5dbc35c69874f5b37d635da0e', '84595d97cb2df42092be869c3a7ac02d');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('1c36982cb46e81e0355b341aa2a7a489', '84595d97cb2df42092be869c3a7ac02d');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('9c780544526baa071263de35c561158d', '84595d97cb2df42092be869c3a7ac02d');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('059225b24fdb9beb6fd90acfc9d83c6e', '84595d97cb2df42092be869c3a7ac02d');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('e8ce846c76b1e046a73049053f10c357', '84595d97cb2df42092be869c3a7ac02d');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('6c337f1c3528cb324e3c4367fb0a2a4a', '84595d97cb2df42092be869c3a7ac02d');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('d0aec3db4b5647564721fe3defe3322a', '2d0d892a058fb84536d0ba6824cc8fd9');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('4b75257068e0b499db745d73a8ab2a54', '2d0d892a058fb84536d0ba6824cc8fd9');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('0f1554d2fdace350e57630e7248a043c', '2d0d892a058fb84536d0ba6824cc8fd9');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('f9d41cc736ffb92e5ac590b41cbe970a', '2d0d892a058fb84536d0ba6824cc8fd9');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('b37c61b90b9602426e9748508a7cf79d', '2d0d892a058fb84536d0ba6824cc8fd9');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('17619d0e883bd1a33df9496c08779bb3', '2d0d892a058fb84536d0ba6824cc8fd9');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('6ed6b166b7b817198e29254e9812a82e', '6d1fb453735d7c041fb45e1b50e2d9dd');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('48a7c844e73c710748c7708a59eb15ac', '6d1fb453735d7c041fb45e1b50e2d9dd');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('a55cb1983e12bc11f43de41e89efa6ef', '7a7c3d975723a4e0eea6a410c956158a');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('120159c82dbe6e6a834d7b69c451c07e', '7a7c3d975723a4e0eea6a410c956158a');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('c00da8ae7e00be70b44dec5107ef4cf1', '7a7c3d975723a4e0eea6a410c956158a');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('f9009843cfdba49eb37cc981a97834c6', 'a04bae4d5b99c08a01840c28ae10ec6f');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('a3ef26ab0c60b4ccd63e84b9a809f23c', 'a04bae4d5b99c08a01840c28ae10ec6f');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('0f1ba4d87d72827da86bb028deded987', 'dfb696c14c6dede09676c0b26e4ceda4');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('232bdd5d3260855c4d3f6733710c5fda', 'dfb696c14c6dede09676c0b26e4ceda4');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('a62dd2bd4441bd23186aebd91211f4ff', '7cec65222a4b21e45409e6124613d66f');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('f74355b3207890cbd6c9a6a760d8146b', '7cec65222a4b21e45409e6124613d66f');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('7edaa97ec1e8c46133c13cc7df00f71e', '7cec65222a4b21e45409e6124613d66f');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('434bf2f2c272023d95665d86ea0bc158', '9f1e2ef759e79a32bbf177031ac381a2');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('0dc07762c60d8a19e53360c76f1d5d7a', 'edbf450293acd64f8940133c4163f927');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('9cc40f72686a6f6b5d85e3a533b02de9', 'edbf450293acd64f8940133c4163f927');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('c0b7c2d524ca5776de81e17762312069', 'edbf450293acd64f8940133c4163f927');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('5bd5df8abdcba522b893f2040841bee1', 'edbf450293acd64f8940133c4163f927');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('ac8076556a0949b984871bbd3e06d0e1', 'edbf450293acd64f8940133c4163f927');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('32c84248075c9c63fd8297de33002618', '0a705282fdbe8b5ad7de5ca97c0c89ca');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('11db52d1db294a5e5bfeec85df31e2ea', '0a705282fdbe8b5ad7de5ca97c0c89ca');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('c6c72b920699b8f5c5b1d06e521b3b0f', '0a705282fdbe8b5ad7de5ca97c0c89ca');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('7b6ed8e1c750a5cc4ca37ae54534a366', '0a705282fdbe8b5ad7de5ca97c0c89ca');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('3de889173cd537d79bc15be49070e964', '7944666ea47eb89ed625f788e1dd3ead');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('700e86cc782439bb1cf2e6972fa0f18d', '7944666ea47eb89ed625f788e1dd3ead');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('bde9ce6595811cd5f3f6eda896329b9b', '7944666ea47eb89ed625f788e1dd3ead');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('a6ff4de6a5c042cf67a2b8640280173c', '6bb5381ccfece4e4d0b16f07f9e63452');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('f4b06d8b75b4c662b9b4e9c9a13a68fe', '6bb5381ccfece4e4d0b16f07f9e63452');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('08b6729f8ea2f67a2dcef7201eaf8945', '6bb5381ccfece4e4d0b16f07f9e63452');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('03e02b6a580836b9b2ec68b6e3853312', '6bb5381ccfece4e4d0b16f07f9e63452');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('34481f88008ee1da10acf343468f12d8', '6bb5381ccfece4e4d0b16f07f9e63452');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('ac6fa1ff069e164d3eeba1f0372f90bf', '8ed7d6ea281b0a5d9a28681960661c28');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('a44da93076b9529149a8d22201708a47', '8ed7d6ea281b0a5d9a28681960661c28');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('9527c787af196fb6a74625273d35726f', '8ed7d6ea281b0a5d9a28681960661c28');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('7bb60f351a6fa49e094aa36450e1d3b1', 'f69c4f545e3f0fd532692aef00acc5ad');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('1b1b30b338c1c22ec46842e3b796e69b', 'f69c4f545e3f0fd532692aef00acc5ad');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('e9e2ba5ee2c5fa646ccb16b10c15a265', 'f69c4f545e3f0fd532692aef00acc5ad');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('1ae2ace957d4bbf7077d2e9225a77173', 'f69c4f545e3f0fd532692aef00acc5ad');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('0f1dc28f5267e55d28baf0f1dd55b245', '77453a3152da2dba3be2a24ccf0ffd40');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('238496c760fcd7ad0bd963d602f7d2e6', '77453a3152da2dba3be2a24ccf0ffd40');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('1449dc96224ed9c41ff07c187fb2d548', '77453a3152da2dba3be2a24ccf0ffd40');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('d3e737998c35e5315a79dff944ad0ca2', '77453a3152da2dba3be2a24ccf0ffd40');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('a8ceb6e8c1122b5282a14b907615ce53', '77453a3152da2dba3be2a24ccf0ffd40');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('b659dc6071bd02df7ff1776567f605a8', 'abb6eb79274604afc6534f43d314f98a');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('3f7e2c79a12d1e85e2833e27b61fef6a', 'abb6eb79274604afc6534f43d314f98a');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('edec610bb43f815bb11e13a2f6d8fe7c', 'abb6eb79274604afc6534f43d314f98a');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('2ab8789527a808f3b927f13004d4735f', 'abb6eb79274604afc6534f43d314f98a');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('7b6f61201d1f1458789133e5e515e8b8', '1c5f1f1e30fb47ce8eeaec8b23342ff8');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('d1138fd2d3074867775b7f8ed8919a51', '1c5f1f1e30fb47ce8eeaec8b23342ff8');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('2bd27383d11436fdb96a93eff1416a77', '1c5f1f1e30fb47ce8eeaec8b23342ff8');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('9caef85410b21c87b227f44dfb7e0953', '1c5f1f1e30fb47ce8eeaec8b23342ff8');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('7798ecbbaf2a8f318419aec5f794dbb7', 'bfc92e753f0d3992deead61421364dcc');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('aba196512dd079c2e2186f71d1e39790', 'bfc92e753f0d3992deead61421364dcc');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('d0629893b9931d215e9de92e07b1d788', 'bfc92e753f0d3992deead61421364dcc');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('92f675f23ca3c26ff42336115ece15ed', 'bfc92e753f0d3992deead61421364dcc');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('5d144af7f499cefaa3838b3ec569b818', '9d39d89c83d3e855e0d26baf37507ec2');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('8efedc19c6f8f6a3dbd2d02ecae3a9da', '9b44106291d72900dc192f05d8248e6f');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('56c56d16b9f98fcedd3d9be5124a88d6', '86bf14ec88a8ad08e316e8b2c108c788');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('a0afd8fb4d0f0584bfa1f335d4af74ea', '86bf14ec88a8ad08e316e8b2c108c788');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('5d5a224c81fe306eee3c713e5fc7dbe1', '86bf14ec88a8ad08e316e8b2c108c788');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('795182f08f91d628b91d8218b5b36cef', '86bf14ec88a8ad08e316e8b2c108c788');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('37061e53fe5b512bc50484bc81689ab6', 'e4a1e03a799c19b4794bc7271f288c1e');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('2431ce5ed72edde2d167044c40d54fb4', 'e4a1e03a799c19b4794bc7271f288c1e');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('ad17c60f490436e3746cd77a0f274988', 'e4a1e03a799c19b4794bc7271f288c1e');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('480d0c0c748867ed3f976acebaa444df', 'e4a1e03a799c19b4794bc7271f288c1e');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('9288d838f269ad6e2c47c12db60bc3f5', '4d7867217f18fa91200bfa08856bb7ad');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('c1059a1dd009659a3a733efa2f7c8d93', '4d7867217f18fa91200bfa08856bb7ad');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('65405ff1d3cf44f19a85557c4efbff8c', '8f9f01a61e3f71f833e27ffd53af55d4');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('046e73774554b2d673b94dee9f2bcccd', '8f9f01a61e3f71f833e27ffd53af55d4');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('1d8d706bf0a7b166f887f42892169d7b', '8f9f01a61e3f71f833e27ffd53af55d4');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('0de52b5acf17f8cf920730f917ee3ff1', '8f9f01a61e3f71f833e27ffd53af55d4');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('71241cf33dc16a5e9e6fee5cc965c82b', '8f9f01a61e3f71f833e27ffd53af55d4');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('aacfcda80f3c35cad6a891d9c891f6c7', '8f9f01a61e3f71f833e27ffd53af55d4');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('90dd1235de7c08aab64cec7c7a0bb96f', '81aee1170a934ec479712fac583cd5cf');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('66e00b49d4cc7a802a00dbbc9e642790', '932d40168dede9edcf09da5939a6e598');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('3d8b353c02d7afe76698d04eb9de85b4', '12c396fe31245c57124829541a923fb8');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('5f1a0d1708eae959a45f1e863d4da7f4', '12c396fe31245c57124829541a923fb8');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('934242e6c24cedcba1dcbf198433de36', '12c396fe31245c57124829541a923fb8');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('76b9cfc0413a3b4fe278356b2b5a8770', '12c396fe31245c57124829541a923fb8');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('85e0791f0d279d9ad0578ab8bcedcf6d', '12c396fe31245c57124829541a923fb8');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('99ad362349842d73aaaa2b4294cb696f', '9f877790499da7853b26c796bd600e95');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('5e5094d0bb6cd803c4f731a8cb451a48', '9f877790499da7853b26c796bd600e95');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('7bcbd64330fc0b7a2f9d42e53bf69d31', '9f877790499da7853b26c796bd600e95');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('e4f8cac5b272cd7ac91a292e9e8fcd42', '9f877790499da7853b26c796bd600e95');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('a20f258e164214200adf2d80f86ff453', '9f877790499da7853b26c796bd600e95');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('d0fbc6c6ee45d6659794ee83cb985433', '9f877790499da7853b26c796bd600e95');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('01d6e7d714c15261c32de97eb096a236', 'bfe48c0438022de07411c54a96ebe928');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('0d475f1ec22e48f4d3c33471c4cf12d2', 'bfe48c0438022de07411c54a96ebe928');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('ccf990cea879e3ca0789aecbaad579e0', 'b7989d5904bdca064daa222b24e84451');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('99be073105f6814fbf9ad62023cbb4f2', '45f22fbd89c8d7d7fd282c03a97e19d1');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('451955b74639088615a64247779d72eb', '45f22fbd89c8d7d7fd282c03a97e19d1');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('0b317fabca1aac31b858c5175e78ff76', '45f22fbd89c8d7d7fd282c03a97e19d1');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('9838043c6e0ff340b7448e81aa26621a', '45f22fbd89c8d7d7fd282c03a97e19d1');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('7d23961a93480f8dbb08e344dcd92609', '45f22fbd89c8d7d7fd282c03a97e19d1');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('b3cc6184a8192a6ad8120dd5907c5fc5', '45f22fbd89c8d7d7fd282c03a97e19d1');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('b256cc42e7dd337cea573717fb2a38d9', 'f928912dd009e8a6e63ae5a8b03026ec');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('716467a0874281e7b0f72065bd001590', 'f928912dd009e8a6e63ae5a8b03026ec');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('26af9c43981456755d3ee2f34baf0543', 'f928912dd009e8a6e63ae5a8b03026ec');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('9897792ee23ef89049798b71c98b2120', 'ddb424c44eb81aad3ac4e306d2b115a2');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('2119bf93a5eb21a2d21cf620c3b3cc58', 'ddb424c44eb81aad3ac4e306d2b115a2');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('76b4ec7cb080c63751ce3d3e61ac8c2d', 'ddb424c44eb81aad3ac4e306d2b115a2');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('32b28bc0537e0db46d64300503ee9139', 'ddb424c44eb81aad3ac4e306d2b115a2');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('eb3459441d3989b733f9ce457ff1d91f', 'ddb424c44eb81aad3ac4e306d2b115a2');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('dadc57917ba6e7858c181cb7f632f841', 'ddb424c44eb81aad3ac4e306d2b115a2');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('ed4cb27356f23b9649b037271e5bd566', 'e8257d9dce99c1588c5f95e4f636dfec');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('85bc2f1481eac63437d2ea3e61d0ce1a', 'e8257d9dce99c1588c5f95e4f636dfec');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('bb409c27b62c9a37f20f95b5aa14ed7c', 'e8257d9dce99c1588c5f95e4f636dfec');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('038e892d711edaeda862b159ef0f40c4', 'e8257d9dce99c1588c5f95e4f636dfec');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('4225ba764faa5745bd1aae3a6a4f72c8', 'e8257d9dce99c1588c5f95e4f636dfec');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('58f5172286d0cb3e9c3a3244aca7d15f', '2f983cce1d38929db6a7d8159efc7592');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('8ba5c1c15a1a8500c5f1db037fe0b13e', '2f983cce1d38929db6a7d8159efc7592');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('2248d8851b7d91c3c1c3349c95755ab9', '2f983cce1d38929db6a7d8159efc7592');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('df692cb6045a4f2af1aa254b149cca2c', '2f983cce1d38929db6a7d8159efc7592');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('6eb2853f6bc10b9212b68c58ae6465a5', '2f983cce1d38929db6a7d8159efc7592');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('a80b5a08d04c0958b099bfb5c79c5430', '2f983cce1d38929db6a7d8159efc7592');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('0f9f6319b76a11f3946fb66b9d5f6b6f', '37442d116cb6551e0865fd340a20f3b2');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('5f39ee5e82070bc4de9dfa6f5a00a5c3', '37442d116cb6551e0865fd340a20f3b2');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('2ccd6f24b7a986f791d8fcb959ba8822', '37442d116cb6551e0865fd340a20f3b2');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('d71eefda9594803e84f77543742332cc', 'd25abf7a800d00b40c57d8573bfaaaf7');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('e514da0043192217b9578b32949f442f', '45e95ade17dc026b2168c409ccc5f516');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('03e81d98d1dee150caa26a7c4427f23d', '45e95ade17dc026b2168c409ccc5f516');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('52b737cca2549ab2eaa3281cd95a87c8', '45e95ade17dc026b2168c409ccc5f516');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('a4f247397bc4064327cf5fe56c3d9dfa', '45e95ade17dc026b2168c409ccc5f516');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('16193b75d9c48b527a1a3b51cfabb46c', '45e95ade17dc026b2168c409ccc5f516');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('00626c2275efd7616a5348f0cf335b94', 'ff9809e15656af4d80ca4c32c2d77d4c');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('b1824e18476f4750e0b195f610872a4a', 'ff9809e15656af4d80ca4c32c2d77d4c');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('11dcb877eb5dbb83e3f3e79b86552c50', 'ff9809e15656af4d80ca4c32c2d77d4c');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('4974d40a147859b500fb02611f1c246f', '73eabe994b939cd9f3f45705264eb7e9');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('af84535fd5b75e246d17d1589eb483e7', '4dd724c2986bafe97805d45a7a634f98');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('005b8b37f2173c32090e3b6258fbe978', '4dd724c2986bafe97805d45a7a634f98');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('0128fabf7e88cb427cbad6a55c902ebe', '4dd724c2986bafe97805d45a7a634f98');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('c1103f350a5d976fc079d082776dab25', '4dd724c2986bafe97805d45a7a634f98');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('c186f3eb01cf8006868bf0f896c8d6ce', '4dd724c2986bafe97805d45a7a634f98');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('e8883ee84aeb5ab5a787cb69457bfb8f', '4dd724c2986bafe97805d45a7a634f98');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('ae4587be2e277650042ba139b7ba613d', '872d28c19783b93b13e053df1924628b');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('1bb4d3da44c4dc999ac2162cfa3a30fa', '872d28c19783b93b13e053df1924628b');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('cada870d1817428571f2f71ef6e8b9c1', '872d28c19783b93b13e053df1924628b');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('a36039cf129d58a20326c852e0831037', '8cb4ad30540db0fc0ee98e080623f086');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('6207b517c4fd7081f291e270978bf2dd', '8cb4ad30540db0fc0ee98e080623f086');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('dff1061e2e3d0203b543ad521a3db0d8', '8cb4ad30540db0fc0ee98e080623f086');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('4639c0c92f68a54d17e0b9811fb060e0', '7838c638bb76e98141e68b42273ccc8b');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('f2d33c624d0b2640fd8af0859a3c687d', '7838c638bb76e98141e68b42273ccc8b');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('ce8fd5b0fc07c54e89cfc2e96f1684f5', 'aba69cc22d1e7d455b335f3b6a3e35eb');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('873c0f750c23a3b7ad67a507bad54dbb', 'aba69cc22d1e7d455b335f3b6a3e35eb');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('9039e63b535d4625f120fdc444999423', 'aba69cc22d1e7d455b335f3b6a3e35eb');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('8b7f5380cccd20237339d08c20a1ea6e', 'aba69cc22d1e7d455b335f3b6a3e35eb');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('c86595b20569d13415f85483612a7459', 'aba69cc22d1e7d455b335f3b6a3e35eb');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('5cc032ccd99d5511b1acd498d6d22dc5', 'a5dc651734940d6e96bae500fd91545f');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('f06ed8a9381ddd5ba708d102713d91a3', 'a5dc651734940d6e96bae500fd91545f');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('53a1da48f2a466499b20c4bf329030eb', 'a5dc651734940d6e96bae500fd91545f');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('d545cccc7162a485c3f5d6e712388eaa', 'a5dc651734940d6e96bae500fd91545f');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('733acf539914a33ea6907ea479e83a40', 'a5dc651734940d6e96bae500fd91545f');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('102678a89b069c71bab1540b6d97a61b', '26d934d9592e8149f98aecf24b06f721');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('188c7ca20d323839f3d8435fab5dccf7', '26d934d9592e8149f98aecf24b06f721');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('120d7b82d50858595b00d28fadf9ea3a', '26d934d9592e8149f98aecf24b06f721');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('dd1aaaafcb544ed5713f78e02ac92713', '26d934d9592e8149f98aecf24b06f721');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('39210b09682f4d8824efd11ba928edaa', '26d934d9592e8149f98aecf24b06f721');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('7599d888d8640e386ebadff06eeecd14', 'a2fc5bf2a93ecef8938b35e930c28863');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('d7d213170b75def2e087270a4ba1ddcf', 'a2fc5bf2a93ecef8938b35e930c28863');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('773f80155e04a4f019422fbee7758fb2', '813304752aa40e1d7f02b2aebbaa1a35');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('95128ea0a08e040df4fc52e5540239fd', '813304752aa40e1d7f02b2aebbaa1a35');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('df372f4da863998f4ab6a835393216c0', '813304752aa40e1d7f02b2aebbaa1a35');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('690917d3537f3b1cb85643c77196b0d2', '813304752aa40e1d7f02b2aebbaa1a35');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('034674f9f2b2ddc6420e20dd5a8f6721', '7b20debb9ccb401e558dba42fdfedf9e');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('3401d12e49222fc05c8702de691c1ce5', '7b20debb9ccb401e558dba42fdfedf9e');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('f8c5faf050a6535a32b2bef594fbed89', '7b20debb9ccb401e558dba42fdfedf9e');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('b99d8008cc0a597d098721161b66c517', '7b20debb9ccb401e558dba42fdfedf9e');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('7a3a2dc2f2fa227bb2517e204ee1c583', '7b20debb9ccb401e558dba42fdfedf9e');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('722adc98e7423addc5897e8b5afbca32', '64c2ea10aa83b452bb760cb31509f900');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('37ab6132a37867f055d0e8ddc7594f2c', 'e1fd4cbf7cbedcdaa8de71724d07a8e9');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('7a8aa304833320d4258a397d67deb43b', 'e1fd4cbf7cbedcdaa8de71724d07a8e9');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('3908c1090e46bf09071c554d26652ee4', '560c49e9f5dd59dc899a28eaed34a2dc');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('19c9e20e5a8bce0aa0eeba2348ebad8a', '560c49e9f5dd59dc899a28eaed34a2dc');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('0f1c7fc8fc7af07c135b37f5ea14c674', 'd73c8892147ee2d1dcc2cc59491cd8d2');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('c7e4c3de63be0fcde63ef3241e3799dc', 'd73c8892147ee2d1dcc2cc59491cd8d2');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('7da0eb619b64c9a818b5ee6785235cf8', 'd73c8892147ee2d1dcc2cc59491cd8d2');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('1131406f4281cec134e65d5bac3769eb', 'd73c8892147ee2d1dcc2cc59491cd8d2');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('46b0cae349e3c00ceac6f19b1faaa699', 'd73c8892147ee2d1dcc2cc59491cd8d2');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('5c96f99332e848a57d3b7e6391967ff9', 'd73c8892147ee2d1dcc2cc59491cd8d2');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('71d5310d0b350317ba047ca6291ecc7d', '63e9fcc8b161ad878a406a879d1b26da');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('10650fadc85e00c8815aea158792f1ce', '63e9fcc8b161ad878a406a879d1b26da');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('8ccc46a621321a7b736b008e25cee1eb', '63e9fcc8b161ad878a406a879d1b26da');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('7f441dd8d7c14713bd1cccc1bdd7de2c', 'f737629bb9b42abb5af951094f75062f');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('28ec65d0c74f3beb6948bb902442a9b5', 'f737629bb9b42abb5af951094f75062f');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('ea2276158e7352a62f0018d31ade8d1f', 'f737629bb9b42abb5af951094f75062f');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('4afe2e1d933c2e5bea45512c1498d0ac', 'f737629bb9b42abb5af951094f75062f');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('6893db5075ef38a136c41590a8862315', 'f737629bb9b42abb5af951094f75062f');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('e0b650f4c928b0cc32e84ff05e83e863', 'f737629bb9b42abb5af951094f75062f');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('94e966ff10e9390534a7b4bb7a7dca12', '8177b34efb1c9a79205e9f5dee88f477');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('d565750fe8ca2a767432d3f69ff3e1ca', '8177b34efb1c9a79205e9f5dee88f477');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('0761641d9d94a45d01c9587f12c0aef5', '3278c49ed9ab128d8e2cc0ac90271aa7');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('e8670b75daf3a9ef82d7c9b54c41eaa3', '3278c49ed9ab128d8e2cc0ac90271aa7');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('17afe2c50b4330b4ff3688e49523bd10', '3278c49ed9ab128d8e2cc0ac90271aa7');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('53ac6e7767d4b0a9430b5c6d969461e8', '74fdb202bca92558c2813d0b43380b4b');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('c9fa08d56e24c500217547e22ff21ee9', '74fdb202bca92558c2813d0b43380b4b');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('f3d9ae75a8170be9eb28d56940236f06', '74fdb202bca92558c2813d0b43380b4b');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('196fbf76d3f9e866594158cad276961f', 'c53496c65ae5b31a6e1e4489b584ceb8');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('5e9db218d08fab653e86cb45b57c6e4c', 'c53496c65ae5b31a6e1e4489b584ceb8');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('41546766c0ddd548546cfdbd5a25daf6', 'c53496c65ae5b31a6e1e4489b584ceb8');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('605275dbd723d6effc0700037b9812de', 'c53496c65ae5b31a6e1e4489b584ceb8');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('9babfc58f8a43dfb4a00605010e4c9a8', 'c53496c65ae5b31a6e1e4489b584ceb8');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('58a866562478087b29e61dbbcced5da3', 'c53496c65ae5b31a6e1e4489b584ceb8');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('74bbec938b63b0d8f344bfcea46b373e', '744be03b6e97d0d2ad40601b8977a9fd');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('f372e4e56c589fe1c71205fec04b914c', '744be03b6e97d0d2ad40601b8977a9fd');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('8b355a79f005b7e5b2f73bc7e8dca956', '744be03b6e97d0d2ad40601b8977a9fd');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('9bf7043c8c30ce572f82dc830b45fe8f', '744be03b6e97d0d2ad40601b8977a9fd');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('abb09c3111811a30b76c2a50f7f7f648', '744be03b6e97d0d2ad40601b8977a9fd');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('1c1daa927ff08a2b37e4a21aa1412d34', '85d1f96f9c090e7328977af6b02bed52');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('2eadefe07acfbebb1718241e7d8681ef', '85d1f96f9c090e7328977af6b02bed52');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('f4efb1963f0d9a089e33696f5b9196d0', '85d1f96f9c090e7328977af6b02bed52');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('56f71761d09f319c2e03eb5cdad2b464', '85d1f96f9c090e7328977af6b02bed52');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('79af9ed295df45039af353818c0dbb44', '0174b4e651a03d50c03c7d0cf2477d1a');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('0f7309ce4c566a06c8160ffdbe76935e', '0174b4e651a03d50c03c7d0cf2477d1a');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('187b565dcbe4e03e2bd100fb4fa80c4c', 'b46680b4764bf1e131e7a68d835d99d9');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('e400976dd524869f9cbd574b36273dd8', 'b46680b4764bf1e131e7a68d835d99d9');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('7fab24fe8b8bb3cc434d2501076d8409', 'b46680b4764bf1e131e7a68d835d99d9');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('d563cf849833f272ca07ea9ba925b388', '7e9f28c36f3cc78036ed52ace48ca048');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('236eaa6f084983d5d6227191a916e434', '7e9f28c36f3cc78036ed52ace48ca048');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('3740fafe2582b5bab05ff77d74da4db2', '7e9f28c36f3cc78036ed52ace48ca048');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('50fa1aded0b1c60bf5c8334ef8222644', '7e9f28c36f3cc78036ed52ace48ca048');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('2472960f243b164066b63f24f5b42897', '7e9f28c36f3cc78036ed52ace48ca048');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('8e4aa308c89db618fd9143a4d233415f', '7e9f28c36f3cc78036ed52ace48ca048');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('8cda2c1892c52c98c59a381fd98a4055', '87cac9e1332e12ae3b86780a06595d38');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('c5232557ef57b3e992c744f70e06038c', '87cac9e1332e12ae3b86780a06595d38');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('0375910eab17bad1365f06aabad6a238', '87cac9e1332e12ae3b86780a06595d38');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('7b319b2eb0093dc1d9e29add9adca7a1', '87cac9e1332e12ae3b86780a06595d38');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('80fb45df84b442955123714896c25916', '87cac9e1332e12ae3b86780a06595d38');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('8a6cfd85ed001bf1b354bf5bc5780013', '87cac9e1332e12ae3b86780a06595d38');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('e9a73620e721c6ad69fa5f43e2358111', '7d67da07816ddd51b26e5bc7b283afde');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('0d26ed9ff1e1395dde1aace745de394e', '7d67da07816ddd51b26e5bc7b283afde');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('a3e80ca9d6de6ad4b4b20f1047ef22aa', '7d67da07816ddd51b26e5bc7b283afde');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('535da1cad5c934c31f0f36c3cdf4abf7', '7d67da07816ddd51b26e5bc7b283afde');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('4ac9531d210290d31c7a48b53f204022', '90f39aa27342a9ee112ee41001bf5626');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('779ad2cf3944372ed1078438484bbcde', '800f5141037464bdfeb88b12bc8550c7');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('2278416f487759f6894f77ad0328ada7', '800f5141037464bdfeb88b12bc8550c7');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('5097e22f1f7db25ab27678561e5bf303', '800f5141037464bdfeb88b12bc8550c7');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('a29aa6b0f15d51ba33c09c7dbd5737e6', 'acf7cc208c3aa633ed5fb74ceb0d0847');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('ce3db356e4cea9aa7379c93273a03206', 'acf7cc208c3aa633ed5fb74ceb0d0847');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('52707ee9c6dd5ff8abbae7375cd5bddf', 'acf7cc208c3aa633ed5fb74ceb0d0847');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('9aa9ee012aeacb4c1a47f2cd31596588', 'de31d367c7a42d9d02716359011bfb74');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('f0ff190a07c94158754c71af2be9efcc', 'de31d367c7a42d9d02716359011bfb74');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('90493bed284f419716ac017bb5fd795f', 'de31d367c7a42d9d02716359011bfb74');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('9b3297260255af3a574e885c8e5b2b17', 'de31d367c7a42d9d02716359011bfb74');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('60ecf38f9179315eb1da7a52ab403851', 'de31d367c7a42d9d02716359011bfb74');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('b95d009f1a060a64da91cddf6728b102', 'de31d367c7a42d9d02716359011bfb74');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('cad76954f603d405c59cf590934da6df', '4b524e73a75184005ba65dd156833f2a');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('2cf4874639129cbc88720647ad3a5d1c', '4b524e73a75184005ba65dd156833f2a');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('75ea2dc6624dfa69aa8d415978170597', '4b524e73a75184005ba65dd156833f2a');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('644b18b6434f79fc307bc0e6e27ddcfd', '4b524e73a75184005ba65dd156833f2a');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('c6918ebb2be6370a5831d1bf19387350', '2f2b0aca2e85a0db8e74b8dcb2d9feaa');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('292826848bcde6578149b90dc36247e8', '2f2b0aca2e85a0db8e74b8dcb2d9feaa');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('5aa340dd9871211d7e907e20b6c5f9b4', '2f2b0aca2e85a0db8e74b8dcb2d9feaa');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('835a499eac0f2338a8130ac9ce9bf612', '2f2b0aca2e85a0db8e74b8dcb2d9feaa');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('461bdfeea9a3f701df9c28d3feafcbb0', '2f2b0aca2e85a0db8e74b8dcb2d9feaa');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('19cd7b0d69bdc1424bd6643d4d7e2574', '0aada211b1bcbd14f01e367d5c301cc3');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('5f5197a2d8b0cd4b36be9c3efeb81075', '0aada211b1bcbd14f01e367d5c301cc3');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('0865bc3f9b94f1a34c7d71f86bc8ef8f', '0aada211b1bcbd14f01e367d5c301cc3');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('1dd6672db063920b4a20433e9bb4ab36', '0aada211b1bcbd14f01e367d5c301cc3');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('1e86cf1e6821bf8cab7baf12387f986f', '0aada211b1bcbd14f01e367d5c301cc3');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('bc253c746f7e0c64e1fb80cdbd1c7a21', 'd3d18cdcf2dab63bde3bf513371ca20d');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('0efd4933f264a3a583a58d8018d55289', '2839ae3b697f52a90e7beebfb40ba451');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('26520921379f02c5aeced46b9026c423', '2839ae3b697f52a90e7beebfb40ba451');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('eecd35b3026af2e905bb8905ca354ecf', 'dbc4d2df82fc5506d1adfb4ced8416d2');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('68786d77ca6e2ecdfffadb32e4324a56', 'dbc4d2df82fc5506d1adfb4ced8416d2');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('217384c9ecce2fa3d23386127781f7c4', 'dbc4d2df82fc5506d1adfb4ced8416d2');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('76d5357b164b8a3f57eca76f88740a35', 'dbc4d2df82fc5506d1adfb4ced8416d2');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('a5dd5619d3c4d4bde155b14e0a405996', 'e874c1a94c4d442bf09c8cfac0c61562');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('3db5984f65eb9366b219be11f46e1977', 'e874c1a94c4d442bf09c8cfac0c61562');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('f0101967637690f1c3c4b1fb2b150669', 'e0e48655963a0bf860c947c363ff9143');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('2a73a84fa2057580326bc8f6bf87cabd', 'e0e48655963a0bf860c947c363ff9143');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('bc626a79d090b6043f487d6f9b74f21b', 'e0e48655963a0bf860c947c363ff9143');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('8565db8e1e61013dc272b0e34d581598', 'e0e48655963a0bf860c947c363ff9143');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('014f6087f4dd82cfefdb3b86d37a59e4', '98763715261a09e2071cec405cbc1957');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('694b5d5f9119f1fc2e38525449325fb4', '98763715261a09e2071cec405cbc1957');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('eb35a8e18d939480db1dbc4958b5920b', '8562d3b6e4841dc8abc0ad4c189b6b31');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('e497f9fee2c8cc5fbf694541e00dfd33', '8562d3b6e4841dc8abc0ad4c189b6b31');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('d4a7f20e0976cd44d21de1c73fc2fd8b', '9940882e65754fbd8544549c4bd40ec2');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('15d217a97351f2e9a81936d00d12864d', '9940882e65754fbd8544549c4bd40ec2');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('9a9000584d26408471f27e069039fe04', '9940882e65754fbd8544549c4bd40ec2');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('c74c72e5f9600caa180ad4217ab2efbb', '9940882e65754fbd8544549c4bd40ec2');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('0b3243ecb2ee9c4bd8bbb62370d9c231', '5bd7ededc9ce09228fa2fd44f6fac97a');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('c21f82751c8d6571150f2afd8fa1ddf3', '5bd7ededc9ce09228fa2fd44f6fac97a');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('be7cc9d3aa94cfbdc521cf40755c7165', '5bd7ededc9ce09228fa2fd44f6fac97a');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('495aa9ec50eca6324e709ba257548a67', '5bd7ededc9ce09228fa2fd44f6fac97a');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('1a6d235bfebd7dcf3b58d8942f1a08e0', '5bd7ededc9ce09228fa2fd44f6fac97a');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('21d5f5f39b6eb23c4c0aa968b82f6d8f', '5bd7ededc9ce09228fa2fd44f6fac97a');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('caec4a434e72436513d69d815b0772df', 'fc3bf89648989d1f7566e0d1bdf24105');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('0b4e8c612f8f78394123a4b2620a4bdf', '697cf65273ac243c0e0d02fdccf30f64');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('76da9c12d98ad5fe3cff25a438218240', '84ac0984c32b6698a5eed82a9b61f40b');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('f57b0a5e7f51999a7ef0ab88ac63c1a7', '84ac0984c32b6698a5eed82a9b61f40b');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('2938844e4997b84c143e96032d2df21f', '84ac0984c32b6698a5eed82a9b61f40b');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('fec587745039453cff40e8121ed0ae88', '84ac0984c32b6698a5eed82a9b61f40b');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('542b7e9432ee27f87f335d2e94bdbbb2', '84ac0984c32b6698a5eed82a9b61f40b');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('1a94420e3421638f1c00e9bde7b3b48c', '84ac0984c32b6698a5eed82a9b61f40b');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('9552bbc6672b54ae9f48eaba53bc8edf', '3d610029d33565e29a6e881758836560');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('b6e25cd0fe6bed7dd134996578737ba7', '3d610029d33565e29a6e881758836560');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('1eb846f59308f819607deb223df52e46', '3d610029d33565e29a6e881758836560');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('d4fced00c1b1eed21bbe911bee05ddf1', 'd8d5b7e0d1eafdb9f950cf0edac4f614');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('040b52242b889462f0f7cff529e499b1', 'd8d5b7e0d1eafdb9f950cf0edac4f614');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('4dd6a6ebcbfdb8c47f3bff3eeca8f2cc', 'd8d5b7e0d1eafdb9f950cf0edac4f614');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('cd0aaee155151b6d2c2c1442050c9dab', 'd8d5b7e0d1eafdb9f950cf0edac4f614');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('bb63c26907cd65e61957a60a410f2b36', 'd8d5b7e0d1eafdb9f950cf0edac4f614');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('6fdc1a9b56180c80103dd0d35d60f3e0', 'd8d5b7e0d1eafdb9f950cf0edac4f614');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('6699084e3e9ac99d81247f6e03abe6bd', '011aa6ba065ee4681a77e7f23068d021');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('f79e47f673d8a8039a350a93831d60b6', '011aa6ba065ee4681a77e7f23068d021');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('784eeb6a1d280fe9cb98fb3f3c91f36e', '011aa6ba065ee4681a77e7f23068d021');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('cb6063f3ef750d0482434bee2a2e226a', '011aa6ba065ee4681a77e7f23068d021');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('830b266d4389a1e6761314b6a72482d4', '011aa6ba065ee4681a77e7f23068d021');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('18e10e9586906e17cb068f9998fa5276', '011aa6ba065ee4681a77e7f23068d021');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('d8a7ff64241bbd7f5a35597fcaf550a7', 'caaab10820e8c0fafa296b111a0c55d7');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('4c0984b098e1a604db63341069153269', 'd82c3abc50b0b52edebbf7c1b22b4f63');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('1743a4d7d189ffac7884abc5caaf99ce', 'd82c3abc50b0b52edebbf7c1b22b4f63');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('df5de09c6bc3cde525a9d8c7d41263d4', 'd82c3abc50b0b52edebbf7c1b22b4f63');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('da230992f205f706106c89fe5731d8d5', 'd82c3abc50b0b52edebbf7c1b22b4f63');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('107c3a9e5f2677e2afae7c9516c2ae06', 'd82c3abc50b0b52edebbf7c1b22b4f63');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('6907b65eab4f7b877a853ccae9c576f5', '9512c0f09801f3b2623442744e15a959');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('e6ddbf78e54f83c342adc363502ca50c', '9512c0f09801f3b2623442744e15a959');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('fe06a5d9ef76c923c53001126529ac9d', '9512c0f09801f3b2623442744e15a959');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('cfbdfb94e9e08184cf2a2db80740d929', '9512c0f09801f3b2623442744e15a959');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('547015138ce3aabd0bafb48b30c2f489', '9512c0f09801f3b2623442744e15a959');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('1cbe767c591ab4fcde78a8b986519b83', 'a4025f3b3077b558a5f8412cb0b9c6d8');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('9ba7c266e9a2b13a872ab45a309f9866', 'a4025f3b3077b558a5f8412cb0b9c6d8');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('3cc92212a7cdc01f842ce2232263119d', 'a4025f3b3077b558a5f8412cb0b9c6d8');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('d0d89971e213c44575be3ed8466e595b', 'a4025f3b3077b558a5f8412cb0b9c6d8');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('c31746492415f6783b1f1b4153029425', 'a4025f3b3077b558a5f8412cb0b9c6d8');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('a9cdd3507e047dda3a158699177243fe', '030f1460a85382190d983f1bb483808a');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('d1b43063ec8a46711c5455b222d38b21', '030f1460a85382190d983f1bb483808a');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('28fe60f58aaf2b0c67107032c1b11ed5', '030f1460a85382190d983f1bb483808a');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('e7b826fc2fe55547606098f74e7c6f36', 'bde889116c5bf6c826cfa935ed395e0e');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('b4b20e3f80ec26f482f722344e9bd164', '2f70e8ba91b8381487e0bd6f35e8c460');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('31a1fbd7bb68a79a365af3ea84b9b217', 'de302762ff46c456ddc29647b79c48a9');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('c7af6663a454e798c6bf16b5c6b13273', 'de302762ff46c456ddc29647b79c48a9');
INSERT INTO "public"."consume_using" ("consume_hash", "using_hash") VALUES ('74a4871ea3e062832124ef4e90a2e401', 'de302762ff46c456ddc29647b79c48a9');


--
-- Data for Name: danger_class; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO "public"."danger_class" ("id", "name", "position") VALUES (0, '--', 0);
INSERT INTO "public"."danger_class" ("id", "name", "position") VALUES (3, 'Перший (І)', 0);
INSERT INTO "public"."danger_class" ("id", "name", "position") VALUES (1, 'Третій (ІІІ)', 0);
INSERT INTO "public"."danger_class" ("id", "name", "position") VALUES (4, 'Четвертий (IV)', 0);
INSERT INTO "public"."danger_class" ("id", "name", "position") VALUES (5, 'Хімічна речовина', 0);
INSERT INTO "public"."danger_class" ("id", "name", "position") VALUES (6, 'Розхідний матеріал', 0);
INSERT INTO "public"."danger_class" ("id", "name", "position") VALUES (2, 'Другий (ІІ)', 0);


--
-- Data for Name: dispersion; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO "public"."dispersion" ("id", "stock_id", "ts", "inc_expert_id", "out_expert_id", "quantity_inc", "quantity_left", "group_id", "inc_date", "comment", "created_ts") VALUES (33, 292, '2020-05-18 16:37:39.740936', 3, 4, 25, 25, 1, '2020-05-12', '1 упаковка з пластинками 20*20 мм', '2020-05-18 16:37:39.740936+03');
INSERT INTO "public"."dispersion" ("id", "stock_id", "ts", "inc_expert_id", "out_expert_id", "quantity_inc", "quantity_left", "group_id", "inc_date", "comment", "created_ts") VALUES (0, 0, '2020-01-02 15:37:24.48078', 0, 0, 0, 0, 0, '1970-01-01', '', '2020-03-13 11:54:36.766118+02');
INSERT INTO "public"."dispersion" ("id", "stock_id", "ts", "inc_expert_id", "out_expert_id", "quantity_inc", "quantity_left", "group_id", "inc_date", "comment", "created_ts") VALUES (29, 292, '2020-05-18 16:30:27.715373', 3, 3, 25, 25, 1, '2020-05-06', 'Передано Столяру на використання 1 уп з пластинками на 20*20 мм', '2020-05-18 16:30:27.715373+03');
INSERT INTO "public"."dispersion" ("id", "stock_id", "ts", "inc_expert_id", "out_expert_id", "quantity_inc", "quantity_left", "group_id", "inc_date", "comment", "created_ts") VALUES (34, 404, '2020-05-18 16:40:46.266979', 3, 3, 1000, 1000, 1, '2020-05-14', 'Передано в сектор біологів для використання в дослідженнях', '2020-05-18 16:40:46.266979+03');
INSERT INTO "public"."dispersion" ("id", "stock_id", "ts", "inc_expert_id", "out_expert_id", "quantity_inc", "quantity_left", "group_id", "inc_date", "comment", "created_ts") VALUES (35, 146, '2020-05-18 16:41:54.234759', 3, 3, 2500, 2500, 1, '2020-05-18', 'Передано в лабораторію для використання', '2020-05-18 16:41:54.234759+03');
INSERT INTO "public"."dispersion" ("id", "stock_id", "ts", "inc_expert_id", "out_expert_id", "quantity_inc", "quantity_left", "group_id", "inc_date", "comment", "created_ts") VALUES (24, 291, '2020-04-17 09:34:37.52125', 3, 3, 500, 450, 1, '2020-04-17', 'Передано в лабораторію для використання', '2020-04-17 09:34:37.52125+03');
INSERT INTO "public"."dispersion" ("id", "stock_id", "ts", "inc_expert_id", "out_expert_id", "quantity_inc", "quantity_left", "group_id", "inc_date", "comment", "created_ts") VALUES (39, 281, '2020-06-10 10:27:20.462045', 3, 8, 2500, 2500, 1, '2020-05-27', 'Передано в лабораторію для використання', '2020-06-10 10:27:20.462045+03');
INSERT INTO "public"."dispersion" ("id", "stock_id", "ts", "inc_expert_id", "out_expert_id", "quantity_inc", "quantity_left", "group_id", "inc_date", "comment", "created_ts") VALUES (36, 312, '2020-05-18 16:50:52.101473', 3, 3, 2500, 2500, 1, '2020-05-13', 'Передано в лабораторію для використання', '2020-05-18 16:50:52.101473+03');
INSERT INTO "public"."dispersion" ("id", "stock_id", "ts", "inc_expert_id", "out_expert_id", "quantity_inc", "quantity_left", "group_id", "inc_date", "comment", "created_ts") VALUES (37, 143, '2020-05-21 10:26:00.957111', 3, 4, 600, 600, 1, '2020-05-21', 'Передано в лабораторію для використання', '2020-05-21 10:26:00.957111+03');
INSERT INTO "public"."dispersion" ("id", "stock_id", "ts", "inc_expert_id", "out_expert_id", "quantity_inc", "quantity_left", "group_id", "inc_date", "comment", "created_ts") VALUES (38, 25, '2020-06-10 10:23:08.131573', 3, 8, 1000, 1000, 1, '2020-05-27', 'Передано в лабораторію для використання', '2020-06-10 10:23:08.131573+03');
INSERT INTO "public"."dispersion" ("id", "stock_id", "ts", "inc_expert_id", "out_expert_id", "quantity_inc", "quantity_left", "group_id", "inc_date", "comment", "created_ts") VALUES (40, 121, '2020-06-10 10:30:33.806773', 3, 3, 1000, 1000, 1, '2020-06-10', 'Передано в лабораторію для використання', '2020-06-10 10:30:33.806773+03');
INSERT INTO "public"."dispersion" ("id", "stock_id", "ts", "inc_expert_id", "out_expert_id", "quantity_inc", "quantity_left", "group_id", "inc_date", "comment", "created_ts") VALUES (41, 284, '2020-06-10 10:31:29.615671', 3, 3, 2500, 2500, 1, '2020-06-01', 'Передано в лабораторію для використання', '2020-06-10 10:31:29.615671+03');
INSERT INTO "public"."dispersion" ("id", "stock_id", "ts", "inc_expert_id", "out_expert_id", "quantity_inc", "quantity_left", "group_id", "inc_date", "comment", "created_ts") VALUES (42, 94, '2020-06-10 10:32:22.280326', 3, 3, 2000, 2000, 1, '2020-06-05', 'Передано в лабораторію для використання', '2020-06-10 10:32:22.280326+03');
INSERT INTO "public"."dispersion" ("id", "stock_id", "ts", "inc_expert_id", "out_expert_id", "quantity_inc", "quantity_left", "group_id", "inc_date", "comment", "created_ts") VALUES (43, 150, '2020-06-10 10:35:21.948875', 3, 3, 1000, 1000, 1, '2020-05-04', 'Передано в лабораторію для використання', '2020-06-10 10:35:21.948875+03');
INSERT INTO "public"."dispersion" ("id", "stock_id", "ts", "inc_expert_id", "out_expert_id", "quantity_inc", "quantity_left", "group_id", "inc_date", "comment", "created_ts") VALUES (44, 26, '2020-06-10 10:37:49.76442', 3, 3, 2500, 2500, 1, '2020-05-04', 'Передано в лабораторію для використання', '2020-06-10 10:37:49.76442+03');
INSERT INTO "public"."dispersion" ("id", "stock_id", "ts", "inc_expert_id", "out_expert_id", "quantity_inc", "quantity_left", "group_id", "inc_date", "comment", "created_ts") VALUES (45, 298, '2020-06-10 10:40:57.63234', 3, 3, 1000, 1000, 1, '2020-04-27', 'Передано в лабораторію для використання', '2020-06-10 10:40:57.63234+03');
INSERT INTO "public"."dispersion" ("id", "stock_id", "ts", "inc_expert_id", "out_expert_id", "quantity_inc", "quantity_left", "group_id", "inc_date", "comment", "created_ts") VALUES (46, 93, '2020-06-10 10:46:17.995287', 3, 3, 1000, 1000, 1, '2020-06-09', 'Передано Столяру на використання', '2020-06-10 10:46:17.995287+03');
INSERT INTO "public"."dispersion" ("id", "stock_id", "ts", "inc_expert_id", "out_expert_id", "quantity_inc", "quantity_left", "group_id", "inc_date", "comment", "created_ts") VALUES (47, 154, '2020-06-10 10:46:56.881611', 3, 3, 1000, 1000, 1, '2020-06-09', 'Передано Столяру на використання', '2020-06-10 10:46:56.881611+03');
INSERT INTO "public"."dispersion" ("id", "stock_id", "ts", "inc_expert_id", "out_expert_id", "quantity_inc", "quantity_left", "group_id", "inc_date", "comment", "created_ts") VALUES (48, 171, '2020-06-10 10:47:15.114634', 3, 3, 1000, 1000, 1, '2020-06-09', 'Передано Столяру на використання', '2020-06-10 10:47:15.114634+03');
INSERT INTO "public"."dispersion" ("id", "stock_id", "ts", "inc_expert_id", "out_expert_id", "quantity_inc", "quantity_left", "group_id", "inc_date", "comment", "created_ts") VALUES (49, 190, '2020-06-10 10:47:32.32793', 3, 3, 1000, 1000, 1, '2020-06-09', 'Передано Столяру на використання', '2020-06-10 10:47:32.32793+03');
INSERT INTO "public"."dispersion" ("id", "stock_id", "ts", "inc_expert_id", "out_expert_id", "quantity_inc", "quantity_left", "group_id", "inc_date", "comment", "created_ts") VALUES (50, 21, '2020-06-10 11:04:40.862015', 3, 3, 1000, 1000, 1, '2020-04-15', 'Передано в лабораторію для використання', '2020-06-10 11:04:40.862015+03');
INSERT INTO "public"."dispersion" ("id", "stock_id", "ts", "inc_expert_id", "out_expert_id", "quantity_inc", "quantity_left", "group_id", "inc_date", "comment", "created_ts") VALUES (51, 285, '2020-06-10 11:05:53.058323', 3, 3, 1000, 1000, 1, '2020-04-15', 'Передано в лабораторію для використання', '2020-06-10 11:05:53.058323+03');
INSERT INTO "public"."dispersion" ("id", "stock_id", "ts", "inc_expert_id", "out_expert_id", "quantity_inc", "quantity_left", "group_id", "inc_date", "comment", "created_ts") VALUES (52, 68, '2020-06-10 11:07:09.087362', 3, 3, 1000, 1000, 1, '2020-04-22', 'Передано в лабораторію для використання', '2020-06-10 11:07:09.087362+03');
INSERT INTO "public"."dispersion" ("id", "stock_id", "ts", "inc_expert_id", "out_expert_id", "quantity_inc", "quantity_left", "group_id", "inc_date", "comment", "created_ts") VALUES (53, 84, '2020-06-10 11:08:55.870714', 3, 3, 1000, 1000, 1, '2020-04-07', 'Передано в лабораторію для використання', '2020-06-10 11:08:55.870714+03');
INSERT INTO "public"."dispersion" ("id", "stock_id", "ts", "inc_expert_id", "out_expert_id", "quantity_inc", "quantity_left", "group_id", "inc_date", "comment", "created_ts") VALUES (54, 85, '2020-06-10 11:10:03.030772', 3, 3, 1000, 1000, 1, '2020-03-26', 'Передано в лабораторію для використання', '2020-06-10 11:10:03.030772+03');
INSERT INTO "public"."dispersion" ("id", "stock_id", "ts", "inc_expert_id", "out_expert_id", "quantity_inc", "quantity_left", "group_id", "inc_date", "comment", "created_ts") VALUES (55, 171, '2020-06-10 11:12:39.125654', 3, 3, 1000, 1000, 1, '2020-04-09', 'Передано в лабораторію для використання', '2020-06-10 11:12:39.125654+03');
INSERT INTO "public"."dispersion" ("id", "stock_id", "ts", "inc_expert_id", "out_expert_id", "quantity_inc", "quantity_left", "group_id", "inc_date", "comment", "created_ts") VALUES (56, 87, '2020-06-10 11:14:27.698051', 3, 3, 1000, 1000, 1, '2020-04-08', 'Передано в лабораторію для використання', '2020-06-10 11:14:27.698051+03');
INSERT INTO "public"."dispersion" ("id", "stock_id", "ts", "inc_expert_id", "out_expert_id", "quantity_inc", "quantity_left", "group_id", "inc_date", "comment", "created_ts") VALUES (57, 186, '2020-06-10 11:16:42.981374', 3, 3, 1000, 1000, 1, '2020-04-09', 'Передано в лабораторію для використання', '2020-06-10 11:16:42.981374+03');
INSERT INTO "public"."dispersion" ("id", "stock_id", "ts", "inc_expert_id", "out_expert_id", "quantity_inc", "quantity_left", "group_id", "inc_date", "comment", "created_ts") VALUES (58, 271, '2020-06-10 11:17:50.097693', 3, 3, 100, 100, 1, '2020-05-12', 'Передано в лабораторію для використання', '2020-06-10 11:17:50.097693+03');
INSERT INTO "public"."dispersion" ("id", "stock_id", "ts", "inc_expert_id", "out_expert_id", "quantity_inc", "quantity_left", "group_id", "inc_date", "comment", "created_ts") VALUES (59, 262, '2020-06-10 11:19:27.24903', 3, 3, 100, 100, 1, '2020-04-09', 'Передано в лабораторію для використання', '2020-06-10 11:19:27.24903+03');
INSERT INTO "public"."dispersion" ("id", "stock_id", "ts", "inc_expert_id", "out_expert_id", "quantity_inc", "quantity_left", "group_id", "inc_date", "comment", "created_ts") VALUES (19, 327, '2020-04-14 14:21:55.06768', 3, 3, 5, 5, 1, '2020-04-14', 'Поміщено в холодильник для зберігання та використання в приготуванні розчинів', '2020-04-14 14:21:55.06768+03');
INSERT INTO "public"."dispersion" ("id", "stock_id", "ts", "inc_expert_id", "out_expert_id", "quantity_inc", "quantity_left", "group_id", "inc_date", "comment", "created_ts") VALUES (20, 226, '2020-04-14 14:40:23.706829', 3, 3, 1, 1, 1, '2020-04-14', 'На використання при дослідженні спиртів', '2020-04-14 14:40:23.706829+03');
INSERT INTO "public"."dispersion" ("id", "stock_id", "ts", "inc_expert_id", "out_expert_id", "quantity_inc", "quantity_left", "group_id", "inc_date", "comment", "created_ts") VALUES (21, 340, '2020-04-14 15:59:52.218936', 3, 3, 4, 4, 1, '2020-04-14', 'На використання при дослідженні спиртів', '2020-04-14 15:59:52.218936+03');
INSERT INTO "public"."dispersion" ("id", "stock_id", "ts", "inc_expert_id", "out_expert_id", "quantity_inc", "quantity_left", "group_id", "inc_date", "comment", "created_ts") VALUES (22, 342, '2020-04-14 16:23:04.221482', 3, 3, 2000, 2000, 1, '2020-04-14', 'Передано в сектор біологів для використання в дослідженнях', '2020-04-14 16:23:04.221482+03');
INSERT INTO "public"."dispersion" ("id", "stock_id", "ts", "inc_expert_id", "out_expert_id", "quantity_inc", "quantity_left", "group_id", "inc_date", "comment", "created_ts") VALUES (27, 131, '2020-05-18 15:10:42.975361', 3, 3, 1000, 1000, 1, '2020-04-29', '1 упаковка з накінечниками', '2020-05-18 15:10:42.975361+03');
INSERT INTO "public"."dispersion" ("id", "stock_id", "ts", "inc_expert_id", "out_expert_id", "quantity_inc", "quantity_left", "group_id", "inc_date", "comment", "created_ts") VALUES (60, 276, '2020-06-10 11:20:38.023882', 3, 3, 100, 100, 1, '2020-04-16', 'Передано в лабораторію для використання', '2020-06-10 11:20:38.023882+03');
INSERT INTO "public"."dispersion" ("id", "stock_id", "ts", "inc_expert_id", "out_expert_id", "quantity_inc", "quantity_left", "group_id", "inc_date", "comment", "created_ts") VALUES (61, 49, '2020-06-10 11:21:48.248847', 3, 3, 1000, 1000, 1, '2020-03-11', 'Передано в лабораторію для використання', '2020-06-10 11:21:48.248847+03');
INSERT INTO "public"."dispersion" ("id", "stock_id", "ts", "inc_expert_id", "out_expert_id", "quantity_inc", "quantity_left", "group_id", "inc_date", "comment", "created_ts") VALUES (25, 20, '2020-05-15 15:47:25.941327', 3, 3, 10.8699999999999992, 10.8699999999999992, 1, '2020-05-15', '', '2020-05-15 15:47:25.941327+03');
INSERT INTO "public"."dispersion" ("id", "stock_id", "ts", "inc_expert_id", "out_expert_id", "quantity_inc", "quantity_left", "group_id", "inc_date", "comment", "created_ts") VALUES (26, 357, '2020-05-15 15:48:41.959608', 3, 3, 100, 100, 1, '2020-05-15', '', '2020-05-15 15:48:41.959608+03');
INSERT INTO "public"."dispersion" ("id", "stock_id", "ts", "inc_expert_id", "out_expert_id", "quantity_inc", "quantity_left", "group_id", "inc_date", "comment", "created_ts") VALUES (30, 282, '2020-05-18 16:31:49.611919', 3, 8, 2500, 2500, 1, '2020-05-07', '1 пляшка на 2,5 л', '2020-05-18 16:31:49.611919+03');
INSERT INTO "public"."dispersion" ("id", "stock_id", "ts", "inc_expert_id", "out_expert_id", "quantity_inc", "quantity_left", "group_id", "inc_date", "comment", "created_ts") VALUES (31, 194, '2020-05-18 16:34:21.182802', 3, 5, 1000, 1000, 1, '2020-05-12', '1 пляшка з прозорою рідиною на 1,0 л', '2020-05-18 16:34:21.182802+03');
INSERT INTO "public"."dispersion" ("id", "stock_id", "ts", "inc_expert_id", "out_expert_id", "quantity_inc", "quantity_left", "group_id", "inc_date", "comment", "created_ts") VALUES (32, 331, '2020-05-18 16:35:12.581231', 3, 3, 500, 500, 1, '2020-05-12', '1 упаковка з накінечниками', '2020-05-18 16:35:12.581231+03');
INSERT INTO "public"."dispersion" ("id", "stock_id", "ts", "inc_expert_id", "out_expert_id", "quantity_inc", "quantity_left", "group_id", "inc_date", "comment", "created_ts") VALUES (62, 88, '2020-06-10 11:25:27.425764', 3, 3, 1000, 1000, 1, '2020-02-19', 'Передано в лабораторію для використання', '2020-06-10 11:25:27.425764+03');
INSERT INTO "public"."dispersion" ("id", "stock_id", "ts", "inc_expert_id", "out_expert_id", "quantity_inc", "quantity_left", "group_id", "inc_date", "comment", "created_ts") VALUES (63, 104, '2020-06-10 11:26:27.677581', 3, 3, 1000, 1000, 1, '2020-02-17', 'Передано в лабораторію для використання', '2020-06-10 11:26:27.677581+03');
INSERT INTO "public"."dispersion" ("id", "stock_id", "ts", "inc_expert_id", "out_expert_id", "quantity_inc", "quantity_left", "group_id", "inc_date", "comment", "created_ts") VALUES (64, 183, '2020-06-10 11:33:21.300209', 3, 3, 1000, 1000, 1, '2020-04-21', 'Передано в лабораторію для використання', '2020-06-10 11:33:21.300209+03');
INSERT INTO "public"."dispersion" ("id", "stock_id", "ts", "inc_expert_id", "out_expert_id", "quantity_inc", "quantity_left", "group_id", "inc_date", "comment", "created_ts") VALUES (65, 254, '2020-06-10 11:36:16.188486', 3, 3, 1000, 1000, 1, '2020-05-01', 'Передано в лабораторію для використання', '2020-06-10 11:36:16.188486+03');
INSERT INTO "public"."dispersion" ("id", "stock_id", "ts", "inc_expert_id", "out_expert_id", "quantity_inc", "quantity_left", "group_id", "inc_date", "comment", "created_ts") VALUES (66, 160, '2020-06-10 12:08:09.516684', 3, 8, 1000, 1000, 1, '2020-03-02', 'Передано в лабораторію для використання', '2020-06-10 12:08:09.516684+03');
INSERT INTO "public"."dispersion" ("id", "stock_id", "ts", "inc_expert_id", "out_expert_id", "quantity_inc", "quantity_left", "group_id", "inc_date", "comment", "created_ts") VALUES (67, 381, '2020-06-10 16:50:52.893702', 3, 3, 100, 100, 1, '2020-03-10', 'Передано в лабораторію для використання', '2020-06-10 16:50:52.893702+03');
INSERT INTO "public"."dispersion" ("id", "stock_id", "ts", "inc_expert_id", "out_expert_id", "quantity_inc", "quantity_left", "group_id", "inc_date", "comment", "created_ts") VALUES (69, 162, '2020-06-11 08:50:24.792784', 3, 3, 100, 100, 1, '2020-04-06', 'Передано в лабораторію для використання', '2020-06-11 08:50:24.792784+03');
INSERT INTO "public"."dispersion" ("id", "stock_id", "ts", "inc_expert_id", "out_expert_id", "quantity_inc", "quantity_left", "group_id", "inc_date", "comment", "created_ts") VALUES (70, 59, '2020-06-11 08:50:52.248254', 3, 3, 100, 100, 1, '2020-03-20', 'Передано в лабораторію для використання', '2020-06-11 08:50:52.248254+03');
INSERT INTO "public"."dispersion" ("id", "stock_id", "ts", "inc_expert_id", "out_expert_id", "quantity_inc", "quantity_left", "group_id", "inc_date", "comment", "created_ts") VALUES (71, 48, '2020-06-11 08:51:30.145994', 3, 3, 1000, 1000, 1, '2020-03-16', 'Передано в лабораторію для використання', '2020-06-11 08:51:30.145994+03');
INSERT INTO "public"."dispersion" ("id", "stock_id", "ts", "inc_expert_id", "out_expert_id", "quantity_inc", "quantity_left", "group_id", "inc_date", "comment", "created_ts") VALUES (72, 69, '2020-06-11 08:51:59.998595', 3, 3, 1000, 1000, 1, '2020-04-24', 'Передано в лабораторію для використання', '2020-06-11 08:51:59.998595+03');
INSERT INTO "public"."dispersion" ("id", "stock_id", "ts", "inc_expert_id", "out_expert_id", "quantity_inc", "quantity_left", "group_id", "inc_date", "comment", "created_ts") VALUES (73, 53, '2020-06-11 08:52:23.999891', 3, 3, 100, 100, 1, '2020-03-05', 'Передано в лабораторію для використання', '2020-06-11 08:52:23.999891+03');
INSERT INTO "public"."dispersion" ("id", "stock_id", "ts", "inc_expert_id", "out_expert_id", "quantity_inc", "quantity_left", "group_id", "inc_date", "comment", "created_ts") VALUES (74, 331, '2020-06-11 10:31:05.081284', 3, 8, 500, 500, 1, '2020-06-11', 'Передано в лабораторію для використання', '2020-06-11 10:31:05.081284+03');
INSERT INTO "public"."dispersion" ("id", "stock_id", "ts", "inc_expert_id", "out_expert_id", "quantity_inc", "quantity_left", "group_id", "inc_date", "comment", "created_ts") VALUES (75, 189, '2020-06-11 10:59:54.661749', 3, 3, 1000, 1000, 1, '2020-06-11', 'Передано в лабораторію для використання', '2020-06-11 10:59:54.661749+03');
INSERT INTO "public"."dispersion" ("id", "stock_id", "ts", "inc_expert_id", "out_expert_id", "quantity_inc", "quantity_left", "group_id", "inc_date", "comment", "created_ts") VALUES (76, 381, '2020-06-15 12:22:59.585309', 3, 3, 100, 100, 1, '2020-06-01', 'Передано в лабораторію для використання', '2020-06-15 12:22:59.585309+03');
INSERT INTO "public"."dispersion" ("id", "stock_id", "ts", "inc_expert_id", "out_expert_id", "quantity_inc", "quantity_left", "group_id", "inc_date", "comment", "created_ts") VALUES (77, 376, '2020-06-15 12:23:21.306787', 3, 3, 100, 100, 1, '2020-05-18', 'Передано в лабораторію для використання', '2020-06-15 12:23:21.306787+03');
INSERT INTO "public"."dispersion" ("id", "stock_id", "ts", "inc_expert_id", "out_expert_id", "quantity_inc", "quantity_left", "group_id", "inc_date", "comment", "created_ts") VALUES (78, 363, '2020-06-15 12:24:07.771092', 3, 3, 100, 100, 1, '2020-06-02', 'Передано в лабораторію для використання', '2020-06-15 12:24:07.771092+03');
INSERT INTO "public"."dispersion" ("id", "stock_id", "ts", "inc_expert_id", "out_expert_id", "quantity_inc", "quantity_left", "group_id", "inc_date", "comment", "created_ts") VALUES (28, 281, '2020-05-18 15:12:02.483103', 3, 2, 2500, 2500, 1, '2020-05-04', '1 пляшка на 2,5 л', '2020-05-18 15:12:02.483103+03');
INSERT INTO "public"."dispersion" ("id", "stock_id", "ts", "inc_expert_id", "out_expert_id", "quantity_inc", "quantity_left", "group_id", "inc_date", "comment", "created_ts") VALUES (23, 315, '2020-04-16 14:27:35.452721', 3, 3, 25, 25, 1, '2020-04-16', 'Видано Курочці А.В. для проведення експертиз по нафтопродуктах', '2020-04-16 14:27:35.452721+03');
INSERT INTO "public"."dispersion" ("id", "stock_id", "ts", "inc_expert_id", "out_expert_id", "quantity_inc", "quantity_left", "group_id", "inc_date", "comment", "created_ts") VALUES (79, 295, '2020-06-16 08:53:43.303891', 3, 3, 100, 100, 1, '2020-06-16', 'Передано в лабораторію для використання', '2020-06-16 08:53:43.303891+03');
INSERT INTO "public"."dispersion" ("id", "stock_id", "ts", "inc_expert_id", "out_expert_id", "quantity_inc", "quantity_left", "group_id", "inc_date", "comment", "created_ts") VALUES (86, 295, '2020-06-22 11:54:06.603359', 3, 3, 100, 100, 1, '2020-06-22', 'Передано в лабораторію для використання', '2020-06-22 11:54:06.603359+03');
INSERT INTO "public"."dispersion" ("id", "stock_id", "ts", "inc_expert_id", "out_expert_id", "quantity_inc", "quantity_left", "group_id", "inc_date", "comment", "created_ts") VALUES (87, 299, '2020-06-22 11:54:34.590456', 3, 3, 100, 100, 1, '2020-06-22', 'Передано в лабораторію для використання', '2020-06-22 11:54:34.590456+03');
INSERT INTO "public"."dispersion" ("id", "stock_id", "ts", "inc_expert_id", "out_expert_id", "quantity_inc", "quantity_left", "group_id", "inc_date", "comment", "created_ts") VALUES (83, 366, '2020-06-17 09:36:57.197881', 3, 3, 100, 100, 1, '2020-06-17', 'Передано в лабораторію для використання', '2020-06-17 09:36:57.197881+03');
INSERT INTO "public"."dispersion" ("id", "stock_id", "ts", "inc_expert_id", "out_expert_id", "quantity_inc", "quantity_left", "group_id", "inc_date", "comment", "created_ts") VALUES (84, 295, '2020-06-18 14:29:15.803411', 3, 4, 100, 100, 1, '2020-06-18', 'Передано в лабораторію для використання', '2020-06-18 14:29:15.803411+03');
INSERT INTO "public"."dispersion" ("id", "stock_id", "ts", "inc_expert_id", "out_expert_id", "quantity_inc", "quantity_left", "group_id", "inc_date", "comment", "created_ts") VALUES (88, 202, '2020-06-24 13:53:21.408324', 3, 3, 1000, 1000, 1, '2020-06-24', 'Передано в сектор біологів для використання в дослідженнях', '2020-06-24 13:53:21.408324+03');
INSERT INTO "public"."dispersion" ("id", "stock_id", "ts", "inc_expert_id", "out_expert_id", "quantity_inc", "quantity_left", "group_id", "inc_date", "comment", "created_ts") VALUES (85, 285, '2020-06-18 15:06:35.218231', 3, 3, 1000, 1000, 1, '2020-06-18', 'Передано в лабораторію для використання', '2020-06-18 15:06:35.218231+03');
INSERT INTO "public"."dispersion" ("id", "stock_id", "ts", "inc_expert_id", "out_expert_id", "quantity_inc", "quantity_left", "group_id", "inc_date", "comment", "created_ts") VALUES (89, 331, '2020-07-01 12:02:47.255339', 3, 3, 500, 500, 1, '2020-07-01', 'Передано в лабораторію для використання', '2020-07-01 12:02:47.255339+03');
INSERT INTO "public"."dispersion" ("id", "stock_id", "ts", "inc_expert_id", "out_expert_id", "quantity_inc", "quantity_left", "group_id", "inc_date", "comment", "created_ts") VALUES (90, 232, '2020-07-01 12:03:53.4075', 3, 3, 5, 5, 1, '2020-06-22', 'Передано в лабораторію для використання', '2020-07-01 12:03:53.4075+03');
INSERT INTO "public"."dispersion" ("id", "stock_id", "ts", "inc_expert_id", "out_expert_id", "quantity_inc", "quantity_left", "group_id", "inc_date", "comment", "created_ts") VALUES (91, 314, '2020-07-06 11:36:00.245465', 3, 8, 50, 50, 1, '2020-07-06', 'Передано в лабораторію для використання', '2020-07-06 11:36:00.245465+03');
INSERT INTO "public"."dispersion" ("id", "stock_id", "ts", "inc_expert_id", "out_expert_id", "quantity_inc", "quantity_left", "group_id", "inc_date", "comment", "created_ts") VALUES (68, 55, '2020-06-11 08:49:52.394321', 1, 3, 100, 100, 1, '2020-03-05', 'Передано в лабораторію для використання', '2020-06-11 08:49:52.394321+03');
INSERT INTO "public"."dispersion" ("id", "stock_id", "ts", "inc_expert_id", "out_expert_id", "quantity_inc", "quantity_left", "group_id", "inc_date", "comment", "created_ts") VALUES (977, 1305, '2020-07-08 00:47:52.909622', 1, 1, 475, 97, 2, '2018-11-24', 'Запис створено автоматично', '2020-07-08 00:47:52.909622+03');
INSERT INTO "public"."dispersion" ("id", "stock_id", "ts", "inc_expert_id", "out_expert_id", "quantity_inc", "quantity_left", "group_id", "inc_date", "comment", "created_ts") VALUES (966, 1281, '2020-07-08 00:47:52.397842', 1, 1, 220, 65, 2, '2020-03-19', 'Запис створено автоматично', '2020-07-08 00:47:52.397842+03');
INSERT INTO "public"."dispersion" ("id", "stock_id", "ts", "inc_expert_id", "out_expert_id", "quantity_inc", "quantity_left", "group_id", "inc_date", "comment", "created_ts") VALUES (968, 1277, '2020-07-08 00:47:52.498646', 1, 1, 440, 101, 2, '2020-07-04', 'Запис створено автоматично', '2020-07-08 00:47:52.498646+03');
INSERT INTO "public"."dispersion" ("id", "stock_id", "ts", "inc_expert_id", "out_expert_id", "quantity_inc", "quantity_left", "group_id", "inc_date", "comment", "created_ts") VALUES (974, 1271, '2020-07-08 00:47:52.776195', 1, 1, 520, 131, 2, '2019-05-13', 'Запис створено автоматично', '2020-07-08 00:47:52.776195+03');
INSERT INTO "public"."dispersion" ("id", "stock_id", "ts", "inc_expert_id", "out_expert_id", "quantity_inc", "quantity_left", "group_id", "inc_date", "comment", "created_ts") VALUES (971, 1289, '2020-07-08 00:47:52.631937', 1, 1, 100, 23, 2, '2020-01-16', 'Запис створено автоматично', '2020-07-08 00:47:52.631937+03');
INSERT INTO "public"."dispersion" ("id", "stock_id", "ts", "inc_expert_id", "out_expert_id", "quantity_inc", "quantity_left", "group_id", "inc_date", "comment", "created_ts") VALUES (975, 1269, '2020-07-08 00:47:52.820671', 1, 1, 900, 289, 2, '2019-08-16', 'Запис створено автоматично', '2020-07-08 00:47:52.820671+03');
INSERT INTO "public"."dispersion" ("id", "stock_id", "ts", "inc_expert_id", "out_expert_id", "quantity_inc", "quantity_left", "group_id", "inc_date", "comment", "created_ts") VALUES (980, 1293, '2020-07-08 00:47:53.042895', 1, 1, 950, 394, 2, '2018-04-21', 'Запис створено автоматично', '2020-07-08 00:47:53.042895+03');
INSERT INTO "public"."dispersion" ("id", "stock_id", "ts", "inc_expert_id", "out_expert_id", "quantity_inc", "quantity_left", "group_id", "inc_date", "comment", "created_ts") VALUES (972, 1280, '2020-07-08 00:47:52.687337', 1, 1, 40, 9, 2, '2019-07-20', 'Запис створено автоматично', '2020-07-08 00:47:52.687337+03');
INSERT INTO "public"."dispersion" ("id", "stock_id", "ts", "inc_expert_id", "out_expert_id", "quantity_inc", "quantity_left", "group_id", "inc_date", "comment", "created_ts") VALUES (979, 1295, '2020-07-08 00:47:52.998405', 1, 1, 400, 171, 2, '2018-06-17', 'Запис створено автоматично', '2020-07-08 00:47:52.998405+03');
INSERT INTO "public"."dispersion" ("id", "stock_id", "ts", "inc_expert_id", "out_expert_id", "quantity_inc", "quantity_left", "group_id", "inc_date", "comment", "created_ts") VALUES (969, 1301, '2020-07-08 00:47:52.542925', 1, 1, 580, 45, 2, '2019-11-14', 'Запис створено автоматично', '2020-07-08 00:47:52.542925+03');
INSERT INTO "public"."dispersion" ("id", "stock_id", "ts", "inc_expert_id", "out_expert_id", "quantity_inc", "quantity_left", "group_id", "inc_date", "comment", "created_ts") VALUES (970, 1292, '2020-07-08 00:47:52.587343', 1, 1, 367, 148, 2, '2019-07-26', 'Запис створено автоматично', '2020-07-08 00:47:52.587343+03');
INSERT INTO "public"."dispersion" ("id", "stock_id", "ts", "inc_expert_id", "out_expert_id", "quantity_inc", "quantity_left", "group_id", "inc_date", "comment", "created_ts") VALUES (995, 1297, '2020-07-08 00:47:53.709912', 1, 1, 220, 65, 2, '2016-02-19', 'Запис створено автоматично', '2020-07-08 00:47:53.709912+03');
INSERT INTO "public"."dispersion" ("id", "stock_id", "ts", "inc_expert_id", "out_expert_id", "quantity_inc", "quantity_left", "group_id", "inc_date", "comment", "created_ts") VALUES (997, 1283, '2020-07-08 00:47:53.822598', 1, 1, 340, 83, 2, '2016-10-06', 'Запис створено автоматично', '2020-07-08 00:47:53.822598+03');
INSERT INTO "public"."dispersion" ("id", "stock_id", "ts", "inc_expert_id", "out_expert_id", "quantity_inc", "quantity_left", "group_id", "inc_date", "comment", "created_ts") VALUES (990, 1291, '2020-07-08 00:47:53.487493', 1, 1, 1300, 80, 2, '2017-02-01', 'Запис створено автоматично', '2020-07-08 00:47:53.487493+03');
INSERT INTO "public"."dispersion" ("id", "stock_id", "ts", "inc_expert_id", "out_expert_id", "quantity_inc", "quantity_left", "group_id", "inc_date", "comment", "created_ts") VALUES (1005, 1275, '2020-07-08 00:47:54.176452', 1, 1, 20, 6, 2, '2015-11-11', 'Запис створено автоматично', '2020-07-08 00:47:54.176452+03');
INSERT INTO "public"."dispersion" ("id", "stock_id", "ts", "inc_expert_id", "out_expert_id", "quantity_inc", "quantity_left", "group_id", "inc_date", "comment", "created_ts") VALUES (988, 1296, '2020-07-08 00:47:53.398538', 1, 1, 500, 262, 2, '2017-12-04', 'Запис створено автоматично', '2020-07-08 00:47:53.398538+03');
INSERT INTO "public"."dispersion" ("id", "stock_id", "ts", "inc_expert_id", "out_expert_id", "quantity_inc", "quantity_left", "group_id", "inc_date", "comment", "created_ts") VALUES (984, 1303, '2020-07-08 00:47:53.226129', 1, 1, 260, 30, 2, '2018-01-12', 'Запис створено автоматично', '2020-07-08 00:47:53.226129+03');
INSERT INTO "public"."dispersion" ("id", "stock_id", "ts", "inc_expert_id", "out_expert_id", "quantity_inc", "quantity_left", "group_id", "inc_date", "comment", "created_ts") VALUES (1003, 1284, '2020-07-08 00:47:54.097673', 1, 1, 160, 62, 2, '2015-05-26', 'Запис створено автоматично', '2020-07-08 00:47:54.097673+03');
INSERT INTO "public"."dispersion" ("id", "stock_id", "ts", "inc_expert_id", "out_expert_id", "quantity_inc", "quantity_left", "group_id", "inc_date", "comment", "created_ts") VALUES (1004, 1282, '2020-07-08 00:47:54.132013', 1, 1, 700, 303, 2, '2015-05-20', 'Запис створено автоматично', '2020-07-08 00:47:54.132013+03');
INSERT INTO "public"."dispersion" ("id", "stock_id", "ts", "inc_expert_id", "out_expert_id", "quantity_inc", "quantity_left", "group_id", "inc_date", "comment", "created_ts") VALUES (1001, 1290, '2020-07-08 00:47:54.009185', 1, 1, 567, 24, 2, '2015-03-23', 'Запис створено автоматично', '2020-07-08 00:47:54.009185+03');
INSERT INTO "public"."dispersion" ("id", "stock_id", "ts", "inc_expert_id", "out_expert_id", "quantity_inc", "quantity_left", "group_id", "inc_date", "comment", "created_ts") VALUES (993, 1273, '2020-07-08 00:47:53.620732', 1, 1, 100, 25, 2, '2017-04-21', 'Запис створено автоматично', '2020-07-08 00:47:53.620732+03');
INSERT INTO "public"."dispersion" ("id", "stock_id", "ts", "inc_expert_id", "out_expert_id", "quantity_inc", "quantity_left", "group_id", "inc_date", "comment", "created_ts") VALUES (985, 1302, '2020-07-08 00:47:53.265272', 1, 1, 1450, 325, 2, '2017-04-29', 'Запис створено автоматично', '2020-07-08 00:47:53.265272+03');
INSERT INTO "public"."dispersion" ("id", "stock_id", "ts", "inc_expert_id", "out_expert_id", "quantity_inc", "quantity_left", "group_id", "inc_date", "comment", "created_ts") VALUES (982, 1276, '2020-07-08 00:47:53.142897', 1, 1, 234, 55, 2, '2018-04-19', 'Запис створено автоматично', '2020-07-08 00:47:53.142897+03');
INSERT INTO "public"."dispersion" ("id", "stock_id", "ts", "inc_expert_id", "out_expert_id", "quantity_inc", "quantity_left", "group_id", "inc_date", "comment", "created_ts") VALUES (983, 1306, '2020-07-08 00:47:53.187231', 1, 1, 450, 154, 2, '2017-06-17', 'Запис створено автоматично', '2020-07-08 00:47:53.187231+03');
INSERT INTO "public"."dispersion" ("id", "stock_id", "ts", "inc_expert_id", "out_expert_id", "quantity_inc", "quantity_left", "group_id", "inc_date", "comment", "created_ts") VALUES (999, 1268, '2020-07-08 00:47:53.920902', 1, 1, 650, 60, 2, '2016-11-07', 'Запис створено автоматично', '2020-07-08 00:47:53.920902+03');
INSERT INTO "public"."dispersion" ("id", "stock_id", "ts", "inc_expert_id", "out_expert_id", "quantity_inc", "quantity_left", "group_id", "inc_date", "comment", "created_ts") VALUES (991, 1288, '2020-07-08 00:47:53.53186', 1, 1, 1250, 414, 2, '2017-02-07', 'Запис створено автоматично', '2020-07-08 00:47:53.53186+03');
INSERT INTO "public"."dispersion" ("id", "stock_id", "ts", "inc_expert_id", "out_expert_id", "quantity_inc", "quantity_left", "group_id", "inc_date", "comment", "created_ts") VALUES (996, 1287, '2020-07-08 00:47:53.754109', 1, 1, 280, 83, 2, '2016-05-09', 'Запис створено автоматично', '2020-07-08 00:47:53.754109+03');
INSERT INTO "public"."dispersion" ("id", "stock_id", "ts", "inc_expert_id", "out_expert_id", "quantity_inc", "quantity_left", "group_id", "inc_date", "comment", "created_ts") VALUES (986, 1300, '2020-07-08 00:47:53.3098', 1, 1, 40, 8, 2, '2017-06-11', 'Запис створено автоматично', '2020-07-08 00:47:53.3098+03');
INSERT INTO "public"."dispersion" ("id", "stock_id", "ts", "inc_expert_id", "out_expert_id", "quantity_inc", "quantity_left", "group_id", "inc_date", "comment", "created_ts") VALUES (976, 1307, '2020-07-08 00:47:52.86504', 1, 1, 267, 104, 2, '2018-05-17', 'Запис створено автоматично', '2020-07-08 00:47:52.86504+03');
INSERT INTO "public"."dispersion" ("id", "stock_id", "ts", "inc_expert_id", "out_expert_id", "quantity_inc", "quantity_left", "group_id", "inc_date", "comment", "created_ts") VALUES (994, 1270, '2020-07-08 00:47:53.665208', 1, 1, 200, 8, 2, '2017-03-12', 'Запис створено автоматично', '2020-07-08 00:47:53.665208+03');
INSERT INTO "public"."dispersion" ("id", "stock_id", "ts", "inc_expert_id", "out_expert_id", "quantity_inc", "quantity_left", "group_id", "inc_date", "comment", "created_ts") VALUES (973, 1274, '2020-07-08 00:47:52.731718', 1, 1, 300, 70, 2, '2019-05-29', 'Запис створено автоматично', '2020-07-08 00:47:52.731718+03');
INSERT INTO "public"."dispersion" ("id", "stock_id", "ts", "inc_expert_id", "out_expert_id", "quantity_inc", "quantity_left", "group_id", "inc_date", "comment", "created_ts") VALUES (981, 1279, '2020-07-08 00:47:53.087173', 1, 1, 350, 96, 2, '2018-05-15', 'Запис створено автоматично', '2020-07-08 00:47:53.087173+03');
INSERT INTO "public"."dispersion" ("id", "stock_id", "ts", "inc_expert_id", "out_expert_id", "quantity_inc", "quantity_left", "group_id", "inc_date", "comment", "created_ts") VALUES (978, 1304, '2020-07-08 00:47:52.954008', 1, 1, 200, 57, 2, '2018-12-08', 'Запис створено автоматично', '2020-07-08 00:47:52.954008+03');
INSERT INTO "public"."dispersion" ("id", "stock_id", "ts", "inc_expert_id", "out_expert_id", "quantity_inc", "quantity_left", "group_id", "inc_date", "comment", "created_ts") VALUES (967, 1278, '2020-07-08 00:47:52.454576', 1, 1, 650, 182, 2, '2020-03-06', 'Запис створено автоматично', '2020-07-08 00:47:52.454576+03');
INSERT INTO "public"."dispersion" ("id", "stock_id", "ts", "inc_expert_id", "out_expert_id", "quantity_inc", "quantity_left", "group_id", "inc_date", "comment", "created_ts") VALUES (992, 1285, '2020-07-08 00:47:53.576446', 1, 1, 80, 9, 2, '2017-03-02', 'Запис створено автоматично', '2020-07-08 00:47:53.576446+03');
INSERT INTO "public"."dispersion" ("id", "stock_id", "ts", "inc_expert_id", "out_expert_id", "quantity_inc", "quantity_left", "group_id", "inc_date", "comment", "created_ts") VALUES (989, 1294, '2020-07-08 00:47:53.44309', 1, 1, 934, 233, 2, '2017-09-09', 'Запис створено автоматично', '2020-07-08 00:47:53.44309+03');
INSERT INTO "public"."dispersion" ("id", "stock_id", "ts", "inc_expert_id", "out_expert_id", "quantity_inc", "quantity_left", "group_id", "inc_date", "comment", "created_ts") VALUES (1000, 1299, '2020-07-08 00:47:53.965387', 1, 1, 100, 17, 2, '2015-06-27', 'Запис створено автоматично', '2020-07-08 00:47:53.965387+03');
INSERT INTO "public"."dispersion" ("id", "stock_id", "ts", "inc_expert_id", "out_expert_id", "quantity_inc", "quantity_left", "group_id", "inc_date", "comment", "created_ts") VALUES (998, 1272, '2020-07-08 00:47:53.876901', 1, 1, 580, 254, 2, '2016-05-10', 'Запис створено автоматично', '2020-07-08 00:47:53.876901+03');
INSERT INTO "public"."dispersion" ("id", "stock_id", "ts", "inc_expert_id", "out_expert_id", "quantity_inc", "quantity_left", "group_id", "inc_date", "comment", "created_ts") VALUES (987, 1298, '2020-07-08 00:47:53.354121', 1, 1, 1500, 182, 2, '2017-09-26', 'Запис створено автоматично', '2020-07-08 00:47:53.354121+03');
INSERT INTO "public"."dispersion" ("id", "stock_id", "ts", "inc_expert_id", "out_expert_id", "quantity_inc", "quantity_left", "group_id", "inc_date", "comment", "created_ts") VALUES (1002, 1286, '2020-07-08 00:47:54.053316', 1, 1, 400, 178, 2, '2015-04-23', 'Запис створено автоматично', '2020-07-08 00:47:54.053316+03');


--
-- Data for Name: expert; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO "public"."expert" ("id", "surname", "name", "phname", "visible", "ts", "login", "password", "token", "group_id", "last_ip", "access_id") VALUES (1, 'Пташкін', 'Роман', 'Леонідович', 1, '2020-07-08 00:57:34.196864', 'root', '855cb86bd065112c52899ef9ea7b9918', '617dac8e3c8918ef3cdcbc8b1e2198d9', 2, '192.168.137.168', 1);
INSERT INTO "public"."expert" ("id", "surname", "name", "phname", "visible", "ts", "login", "password", "token", "group_id", "last_ip", "access_id") VALUES (8, 'Цинда', 'Роман', 'Володимирович', 1, '2020-05-13 15:19:01.423968', 'TSYNDA_ROMAN', '88baebeb0b1bba69c6d1091d09fcfc17', '', 1, '0.0.0.0', 4);
INSERT INTO "public"."expert" ("id", "surname", "name", "phname", "visible", "ts", "login", "password", "token", "group_id", "last_ip", "access_id") VALUES (3, 'Шинкаренко', 'Дмитро', 'Юрійович', 1, '2020-07-07 15:55:21.435218', 'shinkarenko', '1174b4363b1661f9b2c480440a97deea', 'e8ff0a22bc43422318e6584459bcd650', 1, '192.168.2.127', 3);
INSERT INTO "public"."expert" ("id", "surname", "name", "phname", "visible", "ts", "login", "password", "token", "group_id", "last_ip", "access_id") VALUES (2, 'Шкурдода', 'Сергій', 'Вікторович', 1, '2020-07-04 09:44:22.424133', 'shkurdoda', 'd80daf84242523a7c25c1162a314d3d3', 'c81ca9264594fed818045889c46bc269', 1, '192.168.2.118', 3);
INSERT INTO "public"."expert" ("id", "surname", "name", "phname", "visible", "ts", "login", "password", "token", "group_id", "last_ip", "access_id") VALUES (4, 'Курочка', 'Альона', 'Вікторівна', 1, '2020-05-13 12:45:28.033254', 'kurochka_alona', '367351bf60f9f27578c468f6de2a3dbc', '', 1, '0.0.0.0', 4);
INSERT INTO "public"."expert" ("id", "surname", "name", "phname", "visible", "ts", "login", "password", "token", "group_id", "last_ip", "access_id") VALUES (6, 'Тищенко', 'Владислав', 'Валерійович', 1, '2020-05-13 12:51:12.018755', 'tyshchenko_vladyslav', 'fdc633a1cdff96e4de0bb502b11a3426', '', 1, '0.0.0.0', 4);
INSERT INTO "public"."expert" ("id", "surname", "name", "phname", "visible", "ts", "login", "password", "token", "group_id", "last_ip", "access_id") VALUES (7, 'Крикуненко', 'Олександр', 'Юрійович', 1, '2020-07-01 11:26:31.920189', 'krykunenko_oleksandr', 'ce06f5f52a91795ac79fdcf31e867121', '7555f5ec8f126bfc900bfe859d0bc0fd', 2, '192.168.2.162', 3);
INSERT INTO "public"."expert" ("id", "surname", "name", "phname", "visible", "ts", "login", "password", "token", "group_id", "last_ip", "access_id") VALUES (0, '', '', '', 1, '2019-12-28 11:10:20.623791', '', '', '', 0, '0.0.0.0', 0);
INSERT INTO "public"."expert" ("id", "surname", "name", "phname", "visible", "ts", "login", "password", "token", "group_id", "last_ip", "access_id") VALUES (5, 'Конопацька', 'Інна', 'Сергіївна', 1, '2020-05-13 12:47:50.616139', 'konopatska_inna', '9049e404aeac19bfb971c573c16978df', '', 1, '0.0.0.0', 4);


--
-- Data for Name: groups; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO "public"."groups" ("id", "ts", "name", "full_name", "region_id") VALUES (0, '2019-12-28 11:09:48.499219', '--', '--', 0);
INSERT INTO "public"."groups" ("id", "ts", "name", "full_name", "region_id") VALUES (2, '2020-05-13 13:59:14.272388', 'Лабораторія балістичних досліджень', 'Лабораторія балістичних досліджень', 1);
INSERT INTO "public"."groups" ("id", "ts", "name", "full_name", "region_id") VALUES (3, '2020-07-02 16:35:29.816604', 'Лабораторія хімічних досліджень', 'Лабораторія хімічних досліджень', 2);
INSERT INTO "public"."groups" ("id", "ts", "name", "full_name", "region_id") VALUES (1, '2019-12-29 23:20:15.009224', 'Тестова лабораторія', 'Тестова лабораторія', 1);


--
-- Data for Name: prolongation; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('200af4fec29bf42231950fe9f0a400d8', 20, '2019-03-01', '2020-09-01', '2020-05-12 16:42:23.126547', 3, '2020-05-12', '', '2019-03-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('c9603ea9a051b61d010ca59c47bf8ff7', 21, '2018-03-01', '2019-03-01', '2020-05-12 16:45:57.186833', 3, '2020-05-12', '', '2018-03-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('33f0e77882ef545e03644a8534465da8', 21, '2019-03-01', '2020-03-01', '2020-05-12 16:46:27.474232', 3, '2020-05-12', '', '2019-03-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('e8557c0bdf811cbe42c96e0d77d4bb07', 22, '2017-09-01', '2018-03-01', '2020-05-12 16:54:05.855576', 3, '2020-05-12', '', '2017-03-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('f7b0e7d6f0cada0a6ce0d2892ad5065d', 22, '2018-03-01', '2019-03-01', '2020-05-12 16:55:56.752713', 3, '2020-05-12', '', '2018-03-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('01cc63c3c91f33442dabe7db716abfee', 22, '2019-03-01', '2020-03-01', '2020-05-12 16:56:17.151476', 3, '2020-05-12', '', '2019-03-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('a2452a34968806fb197e92a7a36cbf8c', 23, '2018-04-01', '2019-04-01', '2020-05-12 16:57:35.659223', 3, '2020-05-12', '', '2018-04-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('3b5bd95c8d69df1b95215103b38373e2', 23, '2019-04-01', '2020-04-01', '2020-05-12 16:58:06.880544', 3, '2020-05-12', '', '2019-04-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('9d760fee399498f7fd2d85ddb3ad56c9', 24, '2018-10-31', '2020-10-31', '2020-05-12 16:59:16.688525', 3, '2020-05-12', '', '2018-10-31');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('be0e695e1955d5751296eaad51bdd2cb', 25, '2016-09-01', '2017-03-01', '2020-05-12 17:00:38.984882', 3, '2020-05-12', '', '2016-09-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('967edf84c0926ee5dc124151bb82a592', 25, '2017-03-01', '2017-09-01', '2020-05-12 17:01:01.383333', 3, '2020-05-12', '', '2017-03-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('bc369749788e53c5cae603265395362c', 25, '2017-09-01', '2018-03-01', '2020-05-12 17:01:24.815476', 3, '2020-05-12', '', '2017-09-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('1b3a4f5ffa058c21371e0273a44989a3', 25, '2018-03-01', '2018-09-01', '2020-05-12 17:01:56.673204', 3, '2020-05-12', '', '2018-03-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('01caad089d0d819ed97caa994acfadbd', 25, '2018-09-01', '2019-03-01', '2020-05-12 17:02:20.315497', 3, '2020-05-12', '', '2018-09-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('1fa779a402a6a67aeba781c8c1599380', 25, '2019-03-01', '2019-09-01', '2020-05-12 17:02:46.892173', 3, '2020-05-12', '', '2019-03-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('8074d82e909d5869c2a8b77f699bcd43', 25, '2019-09-01', '2020-03-01', '2020-05-12 17:16:20.694078', 3, '2020-05-12', '', '2019-09-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('a6e735a519b10b1bb99312a92502de47', 26, '2018-09-30', '2019-12-30', '2020-05-12 17:18:52.49906', 3, '2020-05-12', '', '2018-09-30');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('e0ba0d41bdc69bfaa4773e4a09bab8c6', 26, '2019-12-30', '2021-03-30', '2020-05-12 17:22:14.151294', 3, '2020-05-12', '', '2019-12-30');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('b3bab96732c6d0c7c0e62684f84d8097', 21, '2020-03-01', '2021-03-01', '2020-05-13 11:04:08.707839', 3, '2020-05-13', '1-2020', '2020-03-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('401053c99fa94118a80fd5765399bea5', 22, '2020-03-01', '2021-03-01', '2020-05-13 11:37:54.489609', 3, '2020-05-13', '2-2020', '2020-03-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('d6e44bad323eb4694c3218767d4af86d', 23, '2020-04-01', '2021-04-01', '2020-05-13 11:41:59.827651', 3, '2020-05-13', '3-2020', '2020-04-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('41c17f07a5660b01362b7fa1482ccfd9', 25, '2020-03-01', '2020-09-01', '2020-05-13 11:49:00.62879', 3, '2020-05-13', '4-2020', '2020-03-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('b0db437794dcfc4dc119e58484b198c6', 43, '2019-03-01', '2020-09-01', '2020-05-13 12:02:51.944662', 3, '2020-05-13', '', '2019-03-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('4fb1fbbd4e637cc5cd6cb71f8f22c983', 44, '2019-02-01', '2020-08-01', '2020-05-13 12:13:10.576433', 3, '2020-05-13', '', '2019-02-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('7831f0d5b413405af4e95e4a04966d03', 45, '2018-03-01', '2019-03-01', '2020-05-13 12:17:20.389459', 3, '2020-05-13', '', '2018-03-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('429113d708c6484280eb1baa29a4c07b', 45, '2019-03-01', '2020-03-01', '2020-05-13 12:18:04.520943', 3, '2020-05-13', '', '2019-03-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('206de402ab63d73f3239427f4fa55cab', 45, '2020-03-01', '2021-03-01', '2020-05-13 12:25:43.948557', 3, '2020-05-13', '5-2020', '2020-03-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('83b5bd2ca35b4318fa8c543fb8fe3060', 46, '2016-12-01', '2017-06-01', '2020-05-13 12:28:54.695994', 3, '2020-05-13', '', '2016-12-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('8bdede40b781c4b562ebe9f46c885301', 46, '2017-06-01', '2017-12-01', '2020-05-13 12:29:38.472666', 3, '2020-05-13', '', '2017-06-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('85be02e2aeadec08a13a9914679fa5b6', 46, '2017-12-01', '2018-06-01', '2020-05-13 12:30:06.3045', 3, '2020-05-13', '', '2017-12-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('3c38b84eebd739f4e385c83361b0ce20', 46, '2018-06-01', '2018-12-01', '2020-05-13 12:30:28.55946', 3, '2020-05-13', '', '2018-06-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('18cc2a1103562127271056dfc480ea05', 46, '2018-12-01', '2019-06-01', '2020-05-13 12:30:45.216103', 3, '2020-05-13', '', '2018-12-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('385d6b8f1073638e4da2350954bda37d', 46, '2019-06-01', '2019-12-01', '2020-05-13 12:36:28.146563', 3, '2020-05-13', '', '2019-06-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('a40db8e5011b6dee29f2ad07a24cc254', 46, '2019-12-01', '2020-06-01', '2020-05-13 12:36:53.922104', 3, '2020-05-13', '', '2019-12-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('67da7188e9e5c587d4419a282c174958', 47, '2018-10-01', '2020-02-01', '2020-05-13 12:39:53.404005', 3, '2020-05-13', '', '2018-10-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('22a3a8a37bf104d69f19e225be125181', 47, '2020-02-01', '2021-06-01', '2020-05-13 12:46:45.85813', 3, '2020-05-13', '6-2020', '2020-02-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('6870a5890adf0bb233c867f861af4ee0', 48, '2019-03-01', '2020-09-01', '2020-05-13 14:16:18.057264', 3, '2020-05-13', '', '2019-03-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('7c0d0579dc87c74766505e525608c71c', 49, '2019-01-01', '2020-05-01', '2020-05-13 14:21:01.956008', 3, '2020-05-13', '', '2019-01-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('ee1fe899a271fdb4b0808ae727f1f516', 49, '2020-05-01', '2021-09-01', '2020-05-13 14:22:31.085636', 3, '2020-05-13', '7-2020', '2020-05-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('723f586a4585f63a2aacc4c0feeb8141', 50, '2016-12-01', '2017-06-01', '2020-05-13 14:29:05.04977', 3, '2020-05-13', '', '2016-12-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('28c536d9d9b7a8ec7ba0df158393fb3b', 50, '2017-06-01', '2017-12-01', '2020-05-13 14:29:30.25962', 3, '2020-05-13', '', '2017-06-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('e99623d99abd95cb5cf5934843221bd4', 50, '2017-12-01', '2018-06-01', '2020-05-13 14:29:59.336201', 3, '2020-05-13', '', '2017-12-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('77d4beb104459e260f5b8e9baf757e42', 50, '2018-06-01', '2018-12-01', '2020-05-13 14:30:15.190873', 3, '2020-05-13', '', '2018-06-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('c689ff50e7de7d9dbc5c0b002668cd0b', 50, '2018-12-01', '2019-06-01', '2020-05-13 14:30:36.156934', 3, '2020-05-13', '', '2018-12-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('ae0cd93ba992fbb5f0b05949fa2c3349', 50, '2019-06-01', '2019-12-01', '2020-05-13 14:36:25.167045', 3, '2020-05-13', '', '2019-06-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('ae3de9b7eb1081388ba468e57bba87de', 50, '2019-12-01', '2020-06-01', '2020-05-13 14:36:41.622951', 3, '2020-05-13', '', '2019-12-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('dede979dbc0b457bfa738b8e65e1f783', 51, '2018-11-01', '2020-02-01', '2020-05-13 14:37:59.429408', 3, '2020-05-13', '', '2018-11-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('35c20c266288480baf1a39536464e50d', 51, '2020-02-01', '2021-05-01', '2020-05-13 14:44:02.5845', 3, '2020-05-13', '8-2020', '2020-02-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('e7bca5dd78e0c608077e8a430c026485', 52, '2017-03-01', '2017-09-01', '2020-05-13 14:45:48.048625', 3, '2020-05-13', '', '2017-03-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('47e9cac2a476dc806493149175f5d494', 52, '2017-09-01', '2018-03-01', '2020-05-13 14:46:10.817204', 3, '2020-05-13', '', '2017-09-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('7d8f427b29c6d1ed141d439e2a81cf40', 52, '2018-03-01', '2018-09-01', '2020-05-13 14:46:26.683106', 3, '2020-05-13', '', '2018-03-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('8b0ebc086f4b7aee848afb1d92477d6f', 52, '2018-09-01', '2019-03-01', '2020-05-13 14:46:43.61399', 3, '2020-05-13', '', '2018-09-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('fc97a81d5f0201f7b492878327c2d057', 52, '2019-03-01', '2019-09-01', '2020-05-13 14:47:00.513268', 3, '2020-05-13', '', '2019-03-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('91e304117d5c78f9318596da1ee4a75b', 52, '2019-09-01', '2020-03-01', '2020-05-13 14:54:37.219218', 3, '2020-05-13', '', '2019-09-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('629aa0cba072cc122f654f4ce2929c74', 52, '2020-03-01', '2020-09-01', '2020-05-13 14:55:31.840439', 3, '2020-05-13', '9-2020', '2020-03-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('5e4b778a76f16ba7d6ba0c4e8d45861f', 53, '2019-01-01', '2020-05-01', '2020-05-13 15:00:43.876323', 3, '2020-05-13', '', '2019-01-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('ac0e311d4e5a22958abe07b4b67c9bc9', 53, '2020-05-01', '2021-09-01', '2020-05-13 15:04:29.183333', 3, '2020-05-13', '', '2020-05-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('3d65df7d7dabc3f5ea2bac0962ec9bf4', 54, '2018-03-01', '2019-03-01', '2020-05-13 15:11:42.2782', 3, '2020-05-13', '', '2018-03-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('e047fabf3004cd8b8b549389f5b77d12', 54, '2019-03-01', '2020-03-01', '2020-05-13 15:12:05.489447', 3, '2020-05-13', '', '2019-03-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('0f1a247e4d05d2e60c9276c2ffcd0f52', 54, '2020-03-01', '2021-03-01', '2020-05-13 15:23:50.430906', 3, '2020-05-13', '11-2020', '2020-03-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('a117c7a12ba92c01a039a6bf4fba2e83', 55, '2018-03-01', '2019-03-01', '2020-05-13 15:31:22.172712', 3, '2020-05-13', '', '2018-03-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('df34122858483e4838392df7bf29edb8', 55, '2019-03-01', '2020-03-01', '2020-05-13 15:31:40.429406', 3, '2020-05-13', '', '2019-03-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('d801dfe1fdd82cd2ca50d69f522250f1', 55, '2020-03-01', '2021-03-01', '2020-05-13 15:45:34.487126', 3, '2020-05-13', '12-2020', '2020-03-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('24072baa835d473bd5bec2d5567d36cd', 56, '2019-03-01', '2020-09-01', '2020-05-13 16:02:07.540161', 3, '2020-05-13', '', '2019-03-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('e6f351bd2cb4c94da32036c0f908d067', 57, '2019-03-01', '2020-09-01', '2020-05-13 16:25:24.030571', 3, '2020-05-13', '', '2019-03-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('8cc05b22b5a7dc3dd60feb5974accd04', 58, '2018-03-01', '2019-03-01', '2020-05-13 16:31:14.387155', 3, '2020-05-13', '', '2018-03-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('0e61e48f92e8ccd96c2a133f62658e3a', 58, '2019-03-01', '2020-03-01', '2020-05-13 16:31:30.665016', 3, '2020-05-13', '', '2019-03-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('666d6eda713f7fd5da7f05291f3e684b', 59, '2018-02-01', '2019-02-01', '2020-05-13 16:51:27.9543', 3, '2020-05-13', '', '2018-02-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('bd1d0e93949e60d82d2b10c4935d72c8', 59, '2019-02-01', '2020-02-01', '2020-05-13 16:51:53.888179', 3, '2020-05-13', '', '2019-02-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('22d2796de1d07cc03d08838702156453', 59, '2020-02-01', '2021-02-01', '2020-05-13 16:55:32.223772', 3, '2020-05-13', '14-2020', '2020-02-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('d544b55c760d1b6f2f9a932385602f79', 58, '2020-03-01', '2021-03-01', '2020-05-13 16:56:23.511051', 3, '2020-05-13', '13-2020', '2020-03-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('eba37064a0a6dcea035d61dc65d3acb9', 65, '2017-03-01', '2017-09-01', '2020-05-13 17:07:21.8913', 3, '2020-05-13', '', '2017-03-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('9b86803a8be97851a9ddaa202eefecd3', 65, '2017-09-01', '2018-03-01', '2020-05-13 17:07:43.557379', 3, '2020-05-13', '', '2017-09-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('da646f908ea9baac4f55a91c1b2c4c99', 65, '2018-03-01', '2018-09-01', '2020-05-13 17:08:01.001706', 3, '2020-05-13', '', '2018-03-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('b75cdb53ca85b1a56066f81ca6ad1e8e', 65, '2018-09-01', '2019-03-01', '2020-05-13 17:08:24.790213', 3, '2020-05-13', '', '2018-09-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('e2704f3a7ab4e1107b10ad3d8d4c077a', 65, '2019-03-01', '2019-09-01', '2020-05-13 17:08:43.611793', 3, '2020-05-13', '', '2019-03-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('35100fae1e4a672bf9a0cce6612ff12d', 65, '2019-09-01', '2020-03-01', '2020-05-13 17:15:31.367212', 3, '2020-05-13', '', '2019-09-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('f189b6c24e4231e8262ea27da725f4c3', 65, '2020-03-01', '2020-09-01', '2020-05-13 17:18:14.004189', 3, '2020-05-13', '15-2020', '2020-03-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('8fe2182cc39336933fd2b2b14eff85f4', 66, '2017-03-01', '2017-09-01', '2020-05-13 17:19:53.521258', 3, '2020-05-13', '', '2017-03-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('e32eb44b52fc0d822c6bb2e07febc3ba', 66, '2017-09-01', '2018-03-01', '2020-05-13 17:20:19.731015', 3, '2020-05-13', '', '2017-09-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('266523b5dafd6508464671695d8caccf', 66, '2018-03-01', '2018-09-01', '2020-05-13 17:21:09.563205', 3, '2020-05-13', '', '2018-03-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('d42ec890c29ab6ea842c14474babddc8', 66, '2018-09-01', '2019-03-01', '2020-05-13 17:21:29.140873', 3, '2020-05-13', '', '2018-09-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('f24abf537528ea1ed80611fb05a58cf2', 66, '2019-03-01', '2019-09-01', '2020-05-13 17:22:07.950556', 3, '2020-05-13', '', '2019-03-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('47b988d59a0b91b7f6e7a3f78b53037e', 66, '2019-09-01', '2020-03-01', '2020-05-13 17:31:32.511883', 3, '2020-05-13', '', '2019-09-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('57d4019edc5e03b6f0dd87aaa7860942', 66, '2020-03-01', '2020-09-01', '2020-05-13 17:31:52.232944', 3, '2020-05-13', '16-2020', '2020-03-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('cf3da9459fd411f681cde4c04230dcac', 67, '2020-01-03', '2022-01-03', '2020-05-13 17:49:26.759706', 3, '2020-05-13', '17-2020', '2020-01-03');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('c554ea785b1dcc8d70e863c8e47d499d', 68, '2017-03-01', '2017-09-01', '2020-05-14 08:46:36.939793', 3, '2020-05-14', '', '2017-03-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('c6796dba26dc74f552fbe19c1c94c432', 68, '2017-09-01', '2018-03-01', '2020-05-14 08:46:58.849169', 3, '2020-05-14', '', '2017-09-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('b3a7a0d82a24edd166006b53d39c878d', 68, '2018-03-01', '2018-09-01', '2020-05-14 08:47:18.015118', 3, '2020-05-14', '', '2018-03-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('b9074ff4eebfe8e2b803da5ccb8f3d46', 68, '2018-09-01', '2019-03-01', '2020-05-14 08:47:39.736311', 3, '2020-05-14', '', '2018-09-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('4bb3b79a2687166961381545d42833dc', 68, '2019-03-01', '2019-09-01', '2020-05-14 08:47:58.435626', 3, '2020-05-14', '', '2019-03-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('33a82ae136bab0e6ada030c3c5240018', 68, '2019-09-01', '2020-03-01', '2020-05-14 08:54:59.762343', 3, '2020-05-14', '', '2019-09-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('6562164ac370cfd626703d2d80043c04', 68, '2020-03-01', '2020-09-01', '2020-05-14 08:55:19.239357', 3, '2020-05-14', '18-2020', '2020-03-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('4ac2560811c3b7fe01e4f923d8f94775', 70, '2018-07-01', '2019-09-01', '2020-05-14 08:59:01.429761', 3, '2020-05-14', '', '2018-07-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('208120f241c8e8c68c12fc2615ade5c3', 70, '2019-09-01', '2020-11-01', '2020-05-14 09:03:51.532818', 3, '2020-05-14', '', '2019-09-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('74c9eb9af0c0fb5b5354508e33721c73', 71, '2018-12-01', '2020-04-01', '2020-05-14 09:12:50.775916', 3, '2020-05-14', '', '2018-12-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('1fb2a717fe7e6af3643c865a918ee239', 71, '2020-04-01', '2021-08-01', '2020-05-14 09:23:24.580995', 3, '2020-05-14', '19-2020', '2020-04-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('a1eafba6f0b1e63f05f4d847f339cac6', 72, '2018-12-01', '2020-04-01', '2020-05-14 09:51:47.741586', 3, '2020-05-14', '', '2018-12-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('9296886bffa55d957bf450a2dcff2623', 72, '2020-04-01', '2021-08-01', '2020-05-14 09:52:03.199252', 3, '2020-05-14', '20-2020', '2020-04-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('4f6d4dfaedfd8046812ef1a605a9208c', 73, '2017-06-01', '2017-12-01', '2020-05-14 09:57:31.556226', 3, '2020-05-14', '', '2017-06-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('88c8e9ea6eda79eec4ebf6d57feb7f21', 73, '2017-12-01', '2018-06-01', '2020-05-14 09:57:48.830569', 3, '2020-05-14', '', '2017-12-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('2298a174828bf574ee94d0df45c48f05', 73, '2018-06-01', '2018-12-01', '2020-05-14 09:58:14.454128', 3, '2020-05-14', '', '2018-06-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('b38438ee447f7573abefce3dd34c32ef', 73, '2018-12-01', '2019-06-01', '2020-05-14 09:58:31.642342', 3, '2020-05-14', '', '2018-12-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('027607e36dbc545850b1a0bc5cd2a0b2', 73, '2019-06-01', '2019-12-01', '2020-05-14 10:25:41.189864', 3, '2020-05-14', '', '2019-06-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('22dea996b595178dd661e43ef9612430', 73, '2019-12-01', '2020-06-01', '2020-05-14 10:25:55.555965', 3, '2020-05-14', '', '2019-12-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('0167f3b8509b8ef949c3c03b633f5041', 74, '2018-03-01', '2019-03-01', '2020-05-14 10:27:27.030517', 3, '2020-05-14', '', '2018-03-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('b11250bf349ea2cc612f517c7e57ace4', 74, '2019-03-01', '2020-03-01', '2020-05-14 10:27:41.58532', 3, '2020-05-14', '', '2019-03-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('985291221a5bb15829d3cdb215c5f9fd', 74, '2020-03-01', '2021-03-01', '2020-05-14 10:35:32.734071', 3, '2020-05-14', '21-2020', '2020-03-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('b3e58bab67c3a21c955ea9e28f9843b3', 75, '2019-01-01', '2020-05-01', '2020-05-14 10:37:00.951994', 3, '2020-05-14', '', '2019-01-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('36f65df0d393f038e95693905a8b4a46', 75, '2020-05-01', '2021-09-01', '2020-05-14 10:45:09.793413', 3, '2020-05-14', '22-2020', '2020-05-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('e0bc7e362333c964366a8e40800be39a', 76, '2019-02-01', '2020-08-01', '2020-05-14 10:47:09.920812', 3, '2020-05-14', '', '2019-02-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('f94ebaca77bb6e849b5b1bae6f51af7a', 77, '2019-03-01', '2020-09-01', '2020-05-14 10:48:12.240446', 3, '2020-05-14', '', '2019-03-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('94da5977f467d55451059fad5caada02', 78, '2018-03-01', '2019-03-01', '2020-05-14 10:50:30.145311', 3, '2020-05-14', '', '2018-03-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('5329442b98929a1061790761a059afda', 78, '2019-03-01', '2020-03-01', '2020-05-14 10:50:48.629749', 3, '2020-05-14', '', '2019-03-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('adddfd92f618db4ba11177ecdc887808', 78, '2020-03-01', '2021-03-01', '2020-05-14 10:56:25.376329', 3, '2020-05-14', '23-2020', '2020-03-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('513e02282266af1f7203d402a771bffe', 79, '2018-02-01', '2019-07-01', '2020-05-14 10:58:11.761134', 3, '2020-05-14', '', '2018-02-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('0a3c1b4e37169bda5efc3bbcd0c4fe55', 79, '2019-07-01', '2020-12-01', '2020-05-14 11:03:31.927927', 3, '2020-05-14', '', '2019-07-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('791dd920db1e1c8b3f67778bb72ac66b', 84, '2018-02-01', '2019-02-01', '2020-05-14 11:09:39.490347', 3, '2020-05-14', '', '2018-02-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('d943dac65aab3518d2655c656bb9fd51', 84, '2019-02-01', '2020-02-01', '2020-05-14 11:09:53.963537', 3, '2020-05-14', '', '2019-02-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('066f5452f1c7acb97114864225ca980f', 84, '2020-02-01', '2021-02-01', '2020-05-14 11:17:25.67046', 3, '2020-05-14', '24-2020', '2020-02-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('c07056bcf883f3da780eb24c7b2de99b', 85, '2019-08-01', '2021-02-01', '2020-05-14 11:29:44.971467', 3, '2020-05-14', '', '2019-08-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('01f48339162e9fd7a32a1880badba0bd', 87, '2018-08-01', '2020-04-01', '2020-05-14 11:43:58.872505', 3, '2020-05-14', '', '2018-08-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('f1f715049cea15ffbc3de9e4a37e7459', 87, '2020-04-01', '2021-10-01', '2020-05-14 11:44:21.737824', 3, '2020-05-14', '25-2020', '2020-04-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('a0bfc540ea955e1fcce721e5a945f11b', 88, '2017-07-01', '2018-01-01', '2020-05-14 11:45:49.001968', 3, '2020-05-14', '', '2017-07-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('3623430bea698d6ddca6a452db1c0e48', 88, '2018-01-01', '2018-07-01', '2020-05-14 11:46:10.056344', 3, '2020-05-14', '', '2018-01-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('416575f05e2f9cd90ff09f2b59ed9a3d', 88, '2018-07-01', '2019-01-01', '2020-05-14 11:46:35.109635', 3, '2020-05-14', '', '2018-07-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('3e14e9964d931d17f5e6f5619e719bbc', 88, '2019-01-01', '2019-07-01', '2020-05-14 11:46:57.787708', 3, '2020-05-14', '', '2019-01-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('38fd1cf7048b9e4f926e6af7d16fbe65', 88, '2019-07-01', '2020-01-01', '2020-05-14 11:54:28.791863', 3, '2020-05-14', '', '2019-07-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('4d9f2b12ed87493bb08c2a2adc4dc7ab', 88, '2020-01-01', '2020-07-01', '2020-05-14 11:54:59.545594', 3, '2020-05-14', '26-2020', '2020-01-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('2ef51692d21558dd43fc1511b1598952', 89, '2019-07-01', '2020-10-01', '2020-05-14 12:09:29.824108', 3, '2020-05-14', '', '2019-07-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('b90b61abf299cda1610b16aa8f197333', 91, '2018-05-01', '2019-05-01', '2020-05-14 12:12:02.029836', 3, '2020-05-14', '', '2018-05-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('c566c4da7f25400af302ef7ed3ebf01a', 91, '2019-05-01', '2020-05-01', '2020-05-14 12:13:40.97031', 3, '2020-05-14', '', '2019-05-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('52fe111011d3698ddeca2185682bfebf', 91, '2020-05-01', '2021-05-01', '2020-05-14 13:39:54.633347', 3, '2020-05-14', '27-2020', '2020-05-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('8e96f3e2a2beda84474d2534d4a0568a', 92, '2018-03-01', '2018-09-01', '2020-05-14 13:42:27.461608', 3, '2020-05-14', '', '2018-03-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('8cf474448b1387875f1b55b3dbc70239', 92, '2018-09-01', '2019-03-01', '2020-05-14 13:42:49.98236', 3, '2020-05-14', '', '2018-09-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('5382f2f0a1856e6b7de4d67c15ea2d9b', 92, '2019-03-01', '2019-09-01', '2020-05-14 13:43:07.804346', 3, '2020-05-14', '', '2019-03-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('90ee91e52b2767bfededa6bee36e6093', 92, '2019-09-01', '2020-03-01', '2020-05-14 13:48:35.391307', 3, '2020-05-14', '', '2019-09-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('4417735c309ac1420127e53e68e8e59f', 92, '2020-03-01', '2020-09-01', '2020-05-14 13:48:52.358728', 3, '2020-05-14', '28-2020', '2020-03-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('c6c438f142e397c5b2aa93ee54a33d3c', 93, '2020-03-01', '2021-09-01', '2020-05-14 14:03:30.778556', 3, '2020-05-14', '29-2020', '2020-03-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('72427783bc4340b6976df8877b3a291b', 94, '2020-03-01', '2021-08-01', '2020-05-14 14:12:16.578327', 3, '2020-05-14', '29-2020', '2020-03-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('81b4b1dadb3771de26812e15bf5c994a', 104, '2018-08-01', '2019-08-01', '2020-05-14 14:20:34.312116', 3, '2020-05-14', '', '2018-08-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('2e7a33bb9f4030f2d74fee3741415397', 104, '2019-08-01', '2020-08-01', '2020-05-14 14:20:51.900758', 3, '2020-05-14', '', '2019-08-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('c0b9d8b0eaecced28812dbb164184bdc', 105, '2018-11-01', '2019-11-01', '2020-05-14 14:27:20.548148', 3, '2020-05-14', '', '2018-11-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('f9951df1e145b10f00546b14094d77f0', 105, '2019-11-01', '2020-11-01', '2020-05-14 14:27:33.903091', 3, '2020-05-14', '', '2019-11-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('7dead9b9a99a786f01c524e17becfbab', 106, '2018-01-02', '2018-06-02', '2020-05-14 14:42:22.96535', 3, '2020-05-14', '', '2018-01-02');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('87a6480d9c011a94c3fb143270b269e6', 106, '2018-06-02', '2019-01-02', '2020-05-14 14:42:42.97853', 3, '2020-05-14', '', '2018-06-02');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('76ba14379b1e95a39e3a2de8f3cd3af8', 106, '2019-01-02', '2019-06-02', '2020-05-14 14:43:10.518366', 3, '2020-05-14', '', '2019-01-02');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('7377d2548188e89e4ef3b47d63a98784', 106, '2019-06-02', '2020-01-02', '2020-05-14 14:46:47.654566', 3, '2020-05-14', '', '2019-06-02');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('c60cc0d65cc7b7e767374cc8bd6bc263', 106, '2020-01-02', '2020-07-02', '2020-05-14 14:53:43.815738', 3, '2020-05-14', '30-2020', '2020-01-02');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('9b103800bb8dbc0abddebe2ec0977b6c', 107, '2019-04-01', '2020-04-01', '2020-05-14 14:57:39.581725', 3, '2020-05-14', '', '2019-04-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('33d8c5b5d068b2a50fee939dbfc9bacd', 107, '2020-04-01', '2021-04-01', '2020-05-14 14:59:53.832177', 3, '2020-05-14', '31-2020', '2020-04-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('3e571e8a404e4d73149a49dff2c0e874', 108, '2019-01-02', '2020-01-02', '2020-05-14 15:00:44.385701', 3, '2020-05-14', '', '2019-01-02');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('e496291d7e36c50d705b5c23ec2741a3', 108, '2020-01-02', '2021-01-02', '2020-05-14 15:07:01.938138', 3, '2020-05-14', '32-2020', '2020-01-02');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('fe656b8e2ea5aa419a0ebc080f9c32fb', 110, '2018-01-02', '2019-01-02', '2020-05-14 15:09:00.316836', 3, '2020-05-14', '', '2018-01-02');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('bf664dcd3d58d75ddd7f698f9132a197', 110, '2019-01-02', '2020-01-02', '2020-05-14 15:09:27.185111', 3, '2020-05-14', '', '2019-01-02');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('9a8e5a9eedf7b5bf566442018470e5b8', 110, '2020-01-02', '2021-01-02', '2020-05-14 15:12:58.681026', 3, '2020-05-14', '33-2020', '2020-01-02');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('3ea29798a3b145170b5bed121c7202e0', 115, '2018-01-25', '2018-06-25', '2020-05-14 15:20:29.407153', 3, '2020-05-14', '', '2018-01-25');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('2db13cf4719ea626a48274dc9476b2d8', 115, '2018-06-25', '2019-01-25', '2020-05-14 15:21:08.791869', 3, '2020-05-14', '', '2018-06-25');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('b95d35411d0ec8fa6aed883e27bdae74', 115, '2019-01-25', '2019-06-25', '2020-05-14 15:21:48.928333', 3, '2020-05-14', '', '2019-01-25');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('8c21b258e53f764715980127e81a52c5', 115, '2019-06-25', '2020-01-25', '2020-05-14 15:30:05.106387', 3, '2020-05-14', '', '2019-06-25');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('f029aab45f9560c72aca7cb113a85a91', 115, '2020-01-25', '2020-07-25', '2020-05-14 15:37:45.264269', 3, '2020-05-14', '34-2020', '2020-01-25');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('780d5195079161a2001775e17c99f6d6', 116, '2017-12-10', '2018-06-10', '2020-05-14 15:40:02.102944', 3, '2020-05-14', '', '2017-12-10');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('cdf0afd191e6ccbc1a02e9d474771c49', 116, '2018-06-10', '2018-12-10', '2020-05-14 15:40:19.390797', 3, '2020-05-14', '', '2018-06-10');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('5300a0f5171f0c028928f995aa00c424', 116, '2018-12-10', '2019-06-10', '2020-05-14 15:40:39.523026', 3, '2020-05-14', '', '2018-12-10');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('f635f24a323427ff0a77ebc08d1a5646', 116, '2019-06-10', '2019-12-10', '2020-05-14 15:45:24.012337', 3, '2020-05-14', '', '2019-06-10');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('1316199c222466e5b4d15b134166c94b', 116, '2019-12-10', '2020-06-10', '2020-05-14 15:45:42.822143', 3, '2020-05-14', '', '2019-12-10');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('fa687531df24f21bc47975028b3f0eef', 118, '2018-07-01', '2019-01-02', '2020-05-14 15:47:27.428566', 3, '2020-05-14', '', '2018-07-02');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('df61c01d1e5089c24b35e2800b9b85dd', 118, '2019-01-02', '2019-07-02', '2020-05-14 15:47:44.7616', 3, '2020-05-14', '', '2019-01-02');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('60ed69e184116dcfe26107a53157a523', 118, '2019-07-02', '2020-01-02', '2020-05-14 15:52:43.935008', 3, '2020-05-14', '', '2019-07-02');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('af1c7469a69b24744f3b853e7c7865c3', 118, '2020-01-02', '2020-07-02', '2020-05-14 15:55:40.276244', 3, '2020-05-14', '35-2020', '2020-01-02');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('a9e10663e2b3aea1c4637cd35842c5c7', 119, '2020-03-01', '2021-05-01', '2020-05-14 16:01:37.829336', 3, '2020-05-14', '36-2020', '2020-03-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('238857cac27cc6dc711044adae98e391', 120, '2019-11-01', '2020-11-01', '2020-05-14 16:37:16.458341', 3, '2020-05-14', '', '2019-11-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('98c0a755e5e492588c3d16867ad5f5a3', 121, '2018-11-01', '2019-05-01', '2020-05-14 16:41:14.148177', 3, '2020-05-14', '', '2018-11-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('a286aee7a8ca512116bdd4719c51cf51', 121, '2019-05-01', '2019-11-01', '2020-05-14 16:48:19.640851', 3, '2020-05-14', '', '2019-05-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('f627b3aa2b26629b52d8edcc4c6c04f1', 121, '2019-11-01', '2020-05-01', '2020-05-14 16:48:35.57548', 3, '2020-05-14', '', '2019-11-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('0391b5d6b1a2314771bee14c74e5e20b', 121, '2020-05-01', '2020-11-01', '2020-05-14 16:49:30.35065', 3, '2020-05-14', '37-2020', '2020-05-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('a0c2b7d3a09f4d6ba4d5b81b198fe7c8', 122, '2018-05-01', '2018-11-01', '2020-05-14 16:51:11.557632', 3, '2020-05-14', '', '2018-05-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('a061de5705a56fec5a6ed86b5f8aca1b', 122, '2018-11-01', '2019-05-01', '2020-05-14 16:51:29.600861', 3, '2020-05-14', '', '2018-11-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('59a8f60aeeeaec36065e7340ea663dc4', 122, '2019-05-01', '2019-11-01', '2020-05-14 16:59:31.869657', 3, '2020-05-14', '', '2019-05-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('1060c819bd2c83f5105938d3cce6e981', 122, '2019-11-01', '2020-05-01', '2020-05-14 16:59:54.879229', 3, '2020-05-14', '', '2019-11-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('2e35294f504a7976cfc6bbae582a094c', 122, '2020-05-01', '2020-11-01', '2020-05-14 17:00:58.24236', 3, '2020-05-14', '38-2020', '2020-05-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('59cb80a04c91132618a111ac3e78aa6f', 123, '2019-07-01', '2020-07-01', '2020-05-14 17:12:37.936452', 3, '2020-05-14', '', '2019-07-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('d72fbbe6a1448e71479d9fb21bb025fc', 124, '2019-12-01', '2021-06-01', '2020-05-14 17:26:29.157522', 3, '2020-05-14', '', '2019-12-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('e57d634404c325a0c4b7aa5e8dd7f4ec', 125, '2018-08-01', '2020-02-01', '2020-05-14 17:36:12.975985', 3, '2020-05-14', '', '2018-08-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('561738f112fd01b6deb927852a1208f5', 125, '2020-02-01', '2021-08-01', '2020-05-14 17:41:12.763905', 3, '2020-05-14', '39-2020', '2020-02-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('13b0df8e613c168b92f66f1fb9060014', 126, '2019-09-01', '2020-09-01', '2020-05-15 08:34:13.708522', 3, '2020-05-15', '', '2019-09-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('56b03ec8e013a62c583a9985c814be18', 127, '2018-09-01', '2019-03-01', '2020-05-15 08:47:50.194487', 3, '2020-05-15', '', '2018-09-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('2ebabc49c311f4a70fa64f8f99998bc4', 127, '2019-03-01', '2019-09-01', '2020-05-15 08:48:15.516597', 3, '2020-05-15', '', '2019-03-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('e9082192c0b9f4e4e6463decbe979f19', 127, '2019-09-01', '2020-03-01', '2020-05-15 08:52:28.684879', 3, '2020-05-15', '', '2019-09-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('1a0e38177a9925e26f929e18c5489362', 127, '2020-03-01', '2020-09-01', '2020-05-15 08:52:53.471415', 3, '2020-05-15', '40-2020', '2020-03-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('ef1c3d0770a71ba12265088a5287d04b', 128, '2020-03-31', '2021-09-30', '2020-05-15 09:26:51.013955', 3, '2020-05-15', '41-2020', '2020-03-31');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('6c4eb54a315e5e7b0ba0c6873af561ad', 133, '2019-05-01', '2020-05-01', '2020-05-15 09:37:32.911116', 3, '2020-05-15', '', '2019-05-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('7ea9c1b15d1e0dc2335ecfda9b43a1e2', 133, '2020-05-01', '2021-05-01', '2020-05-15 09:41:36.020294', 3, '2020-05-15', '42-2020', '2020-05-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('dc6440b3b1e5cdbc18db6f64f26836b0', 134, '2018-11-01', '2019-05-01', '2020-05-15 09:54:29.667458', 3, '2020-05-15', '', '2018-11-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('604cb190ce2a26d56d7b8910fb8d1233', 134, '2019-05-01', '2019-11-01', '2020-05-15 09:54:47.02016', 3, '2020-05-15', '', '2019-05-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('2ea08ba558a9fbaf57daf7aab8e966f2', 134, '2019-11-01', '2020-05-01', '2020-05-15 09:55:01.122277', 3, '2020-05-15', '', '2019-11-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('f121844adce01d561e23d2aaa9f2792f', 134, '2020-05-01', '2020-11-01', '2020-05-15 09:55:19.177001', 3, '2020-05-15', '43-2020', '2020-05-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('3f2993e1a40e33fab6d5b9c627e0cc95', 135, '2018-06-01', '2018-12-01', '2020-05-15 09:57:42.726042', 3, '2020-05-15', '', '2018-06-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('c076d247d93e62a3714326569391e42a', 135, '2018-12-01', '2019-06-01', '2020-05-15 09:57:58.980821', 3, '2020-05-15', '', '2018-12-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('be2007cb86e1c3609714cd2adce99385', 135, '2019-06-01', '2019-12-01', '2020-05-15 10:04:35.87672', 3, '2020-05-15', '', '2019-06-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('612ed97e196882613cc39dec6ad0b0ba', 135, '2019-12-01', '2020-06-01', '2020-05-15 10:05:01.052508', 3, '2020-05-15', '', '2019-12-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('86bf8197a17660e375dc17bec706e3b9', 136, '2019-11-01', '2020-11-01', '2020-05-15 10:11:51.690337', 3, '2020-05-15', '', '2019-11-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('2a1f6c0a83bde2132862c9750ecf4dc4', 137, '2019-05-01', '2020-05-01', '2020-05-15 10:29:10.975596', 3, '2020-05-15', '', '2019-05-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('44cb23fc0ae2fc033075527303906200', 137, '2020-05-01', '2021-05-01', '2020-05-15 10:29:33.574341', 3, '2020-05-15', '44-2020', '2020-05-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('5f0eef0ea01b0de93aa2ac955da5d6b3', 138, '2019-10-01', '2020-10-01', '2020-05-15 10:32:57.376357', 3, '2020-05-15', '', '2019-10-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('b89dc69a7ae7b98d45096d4c0c4ad579', 140, '2019-02-01', '2020-02-01', '2020-05-15 10:36:50.344184', 3, '2020-05-15', '', '2020-02-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('d95e610ec582acbb116a99367068d590', 140, '2020-02-01', '2021-02-01', '2020-05-15 10:40:56.300894', 3, '2020-05-15', '45-2020', '2020-02-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('b8634110e2ea09157482eba2f4b5bcab', 141, '2019-11-01', '2020-11-01', '2020-05-15 11:06:13.948078', 3, '2020-05-15', '', '2019-11-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('6e5548310166b93cdd8b97859d3a3c7f', 142, '2020-03-01', '2021-09-01', '2020-05-15 11:13:30.552876', 3, '2020-05-15', '46-2020', '2020-03-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('29ab59cd38a47db41050d640fa6d9e6c', 143, '2020-04-01', '2021-10-01', '2020-05-15 11:18:33.206959', 3, '2020-05-15', '47-2020', '2020-04-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('3be715135fccfbab2cb88ba6d94f13fc', 144, '2018-08-01', '2019-02-01', '2020-05-15 11:20:28.43677', 3, '2020-05-15', '', '2018-08-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('cdfdf0736d79998c444dbb2f31968230', 144, '2019-02-01', '2019-08-01', '2020-05-15 11:21:58.558196', 3, '2020-05-15', '', '2019-02-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('f92832e90963f0d81b016acfee378cb6', 144, '2019-08-01', '2020-02-01', '2020-05-15 11:27:40.687749', 3, '2020-05-15', '', '2019-08-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('60730300526912d68c292de095c35b7f', 144, '2020-02-01', '2020-08-01', '2020-05-15 11:28:01.375569', 3, '2020-05-15', '48-2020', '2020-02-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('67e16492b7443c6963383d5c1c5617ce', 145, '2019-01-06', '2020-01-06', '2020-05-15 11:44:07.79532', 3, '2020-05-15', '', '2019-01-06');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('96739b4960de09ec890ca1785b173a85', 145, '2020-01-06', '2021-01-06', '2020-05-15 11:44:31.901374', 3, '2020-05-15', '49-2020', '2020-01-06');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('59141145496df59cdf14586d6634adda', 147, '2019-08-15', '2020-08-15', '2020-05-15 11:54:11.533836', 3, '2020-05-15', '', '2019-08-15');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('03ff2dd2669c079967ac13b1276d1256', 148, '2019-10-10', '2020-10-10', '2020-05-15 11:59:50.176916', 3, '2020-05-15', '', '2019-10-10');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('c45a4477adca974f792ec2b115e3cbfd', 149, '2019-04-03', '2019-10-03', '2020-05-15 12:18:58.825151', 3, '2020-05-15', '', '2019-04-03');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('2c35200a8f3684a39c4af60933a7117c', 149, '2019-10-03', '2020-04-03', '2020-05-15 12:23:05.283995', 3, '2020-05-15', '', '2019-10-03');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('964b614965b50a9d28ceb1d3b25f0075', 149, '2020-04-03', '2020-10-03', '2020-05-15 12:23:26.356348', 3, '2020-05-15', '50-2020', '2020-04-03');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('1101080a37e9fafec4a95fd596a63c30', 150, '2018-10-19', '2019-01-19', '2020-05-15 13:37:50.490253', 3, '2020-05-15', '', '2018-10-19');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('4bd966c6d36f341e5aeecb9ba722f10c', 150, '2019-01-19', '2019-04-19', '2020-05-15 13:38:10.834081', 3, '2020-05-15', '', '2019-01-19');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('845017ab246b96e9ee0c6b7592d10af6', 150, '2019-04-19', '2019-07-19', '2020-05-15 13:38:35.432912', 3, '2020-05-15', '', '2019-04-19');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('763b2ce7cf740aeed248b4d4a043df91', 150, '2019-07-19', '2019-10-19', '2020-05-15 13:48:21.658821', 3, '2020-05-15', '', '2019-07-19');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('b5aa1e849340cfdd3bea8d100bf37c31', 150, '2019-10-19', '2020-01-19', '2020-05-15 13:48:37.55633', 3, '2020-05-15', '', '2019-10-19');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('19e2483b47f4955ac2861c2a90432194', 150, '2020-01-19', '2020-04-19', '2020-05-15 13:48:58.744631', 3, '2020-05-15', '51-2020', '2020-01-19');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('2212040781d29938dc34eb77146b203d', 150, '2020-04-19', '2020-07-19', '2020-05-15 13:49:19.332738', 3, '2020-05-15', '52-2020', '2020-04-19');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('318e4a230037b5d5eddad24bbaaee775', 151, '2019-05-04', '2019-11-04', '2020-05-15 14:00:24.574361', 3, '2020-05-15', '', '2019-05-04');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('9778e809e0f38629c948e4bff05d98fa', 151, '2019-11-04', '2020-05-04', '2020-05-15 14:00:37.951833', 3, '2020-05-15', '', '2019-11-04');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('a633ef952f59839ab38b477504e8ec3f', 151, '2020-05-04', '2020-11-04', '2020-05-15 14:01:06.236208', 3, '2020-05-15', '53-2020', '2020-05-04');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('f418708f42b55c23a9593a0e8a224f44', 152, '2020-03-08', '2021-03-08', '2020-05-15 14:07:54.869994', 3, '2020-05-15', '54-2020', '2020-03-08');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('35f034b3ae3e2f8700529bf180d78b42', 153, '2019-04-23', '2019-10-23', '2020-05-15 14:25:50.612635', 3, '2020-05-15', '', '2019-04-23');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('39d5baafbc5c8423a5ff9a75184d1a30', 153, '2019-10-23', '2020-04-23', '2020-05-15 14:26:07.816707', 3, '2020-05-15', '', '2019-10-23');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('30296a74fd18998512defb7eac2a2ccc', 153, '2020-04-23', '2020-10-23', '2020-05-15 14:26:31.546892', 3, '2020-05-15', '55-2020', '2020-04-23');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('f6709ece16510971dcfe43f09b4b1dea', 154, '2020-01-18', '2021-01-18', '2020-05-15 14:30:35.135394', 3, '2020-05-15', '56-2020', '2020-01-18');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('51e0cc4987d59c988268777559646325', 158, '2019-02-28', '2019-08-28', '2020-05-15 14:37:41.816258', 3, '2020-05-15', '', '2019-02-28');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('f9c56b8241ab12cf09755de1e10517c4', 158, '2019-08-28', '2020-02-28', '2020-05-15 14:41:52.744303', 3, '2020-05-15', '', '2019-08-28');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('5cea72f2957162b80d80cb933204c950', 158, '2020-02-28', '2020-08-28', '2020-05-15 14:42:14.120694', 3, '2020-05-15', '57-2020', '2020-02-28');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('8d617240ab3df21722d787bf038c21a1', 159, '2018-12-27', '2019-06-27', '2020-05-15 14:43:59.095228', 3, '2020-05-15', '', '2018-12-27');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('de826be898d817c2c8624921e5d903c9', 159, '2019-06-27', '2019-12-27', '2020-05-15 14:47:33.124531', 3, '2020-05-15', '', '2019-06-27');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('f15a9316d2053f2d213d838f644fc265', 159, '2019-12-27', '2020-06-27', '2020-05-15 14:47:59.589073', 3, '2020-05-15', '', '2019-12-27');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('f6ef16a0959ecb53c6973be4616ae989', 163, '2018-11-02', '2019-02-02', '2020-05-15 14:53:33.257622', 3, '2020-05-15', '', '2018-11-02');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('e9980c0de202d60333c70af1210e6670', 163, '2019-02-02', '2019-05-02', '2020-05-15 14:53:55.43306', 3, '2020-05-15', '', '2019-02-02');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('5a62f1477b8f7a2c185e4707527e3e86', 163, '2019-05-02', '2019-08-02', '2020-05-15 15:00:40.364838', 3, '2020-05-15', '', '2019-05-02');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('581214c2a95edefcf14d9abf82019443', 163, '2019-08-02', '2019-11-02', '2020-05-15 15:00:57.384482', 3, '2020-05-15', '', '2019-08-02');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('96679dc406e6027961985d84c61944c8', 163, '2019-11-02', '2020-02-02', '2020-05-15 15:01:12.718725', 3, '2020-05-15', '', '2019-11-02');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('30bda7a82c78ff0376d52010f3704296', 163, '2020-02-02', '2020-05-02', '2020-05-15 15:01:31.708486', 3, '2020-05-15', '58-2020', '2020-02-02');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('84a479a0535bebef0bf5c021ccc3d874', 163, '2020-05-02', '2020-08-02', '2020-05-15 15:01:48.148861', 3, '2020-05-15', '59-2020', '2020-05-02');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('4ef93f3ca95e3c06b2db160759dff84f', 164, '2018-11-02', '2019-02-02', '2020-05-15 15:04:24.645605', 3, '2020-05-15', '', '2018-11-02');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('0b2390c559be242dcd8d15746022a6c2', 164, '2019-02-02', '2019-05-02', '2020-05-15 15:04:39.211333', 3, '2020-05-15', '', '2019-02-02');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('09d0b3bbae883138be0b85ab68d50c77', 164, '2019-05-02', '2019-08-02', '2020-05-15 15:14:16.900539', 3, '2020-05-15', '', '2019-05-02');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('c890b4b9e3c77c2ae020287281e731cf', 164, '2019-08-02', '2019-11-02', '2020-05-15 15:15:01.623669', 3, '2020-05-15', '', '2019-08-02');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('f52a2fc27058aac8e07fed31b4c8b15a', 164, '2019-11-02', '2020-02-02', '2020-05-15 15:15:16.202176', 3, '2020-05-15', '', '2019-11-02');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('3a25fc998e423a95b059c7909bea4404', 164, '2020-02-02', '2020-05-02', '2020-05-15 15:16:20.865691', 3, '2020-05-15', '60-2020', '2020-02-02');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('9116c13593435910b03f7eb2a6948cd2', 164, '2020-05-02', '2020-08-02', '2020-05-15 15:16:38.286192', 3, '2020-05-15', '61-2020', '2020-05-02');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('cd5159f5a8892c348f10469fc434e0c3', 170, '2019-04-25', '2019-10-25', '2020-05-15 15:29:15.032758', 3, '2020-05-15', '', '2019-04-25');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('a00dcca82fc1da48c4314c8a8cc61d5d', 170, '2019-10-25', '2020-04-25', '2020-05-15 15:29:29.954409', 3, '2020-05-15', '', '2019-10-25');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('7ab84098306748a119c6f90aa126f20c', 170, '2020-04-25', '2020-10-25', '2020-05-15 15:29:54.742418', 3, '2020-05-15', '62-2020', '2020-04-25');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('9153e0b57fca9d1d548e90e29f40ddbe', 178, '2019-02-23', '2020-02-23', '2020-05-15 15:31:43.39295', 3, '2020-05-15', '', '2019-02-23');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('a203286cbeea3bbe4416ba564c434b22', 178, '2020-02-23', '2021-02-23', '2020-05-15 15:38:03.755934', 3, '2020-05-15', '63-2020', '2020-02-23');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('67307c7455902621603fe1ace7f44892', 179, '2019-03-28', '2019-09-28', '2020-05-18 09:08:00.412051', 3, '2020-05-18', '', '2019-03-28');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('adcc34b3bb3113303e6e60ac1d8f54c3', 179, '2019-09-28', '2020-03-28', '2020-05-18 09:08:16.300123', 3, '2020-05-18', '', '2019-09-28');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('d503fc7b1ceb0a8e781ffd3416388cad', 179, '2020-03-28', '2020-09-28', '2020-05-18 09:08:43.420911', 3, '2020-05-18', '64-2020', '2020-03-28');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('87c8aabdc0ff0383a0404d998e0d3123', 180, '2019-05-01', '2019-11-01', '2020-05-18 09:35:00.303157', 3, '2020-05-18', '', '2019-05-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('ce2b224c21aa0dc4fa18885ea2d97ac2', 180, '2019-11-01', '2020-05-01', '2020-05-18 09:35:13.042213', 3, '2020-05-18', '', '2019-11-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('f7b993ba82ed8f45c393115922754c1e', 180, '2020-05-01', '2020-11-01', '2020-05-18 09:35:35.211185', 3, '2020-05-18', '65-2020', '2020-05-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('e70368ab72197557350693953f768d64', 181, '2020-04-01', '2021-04-01', '2020-05-18 09:45:15.400612', 3, '2020-05-18', '66-2020', '2020-04-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('03d1c2ee4e97ea97d899e6c399a2a810', 182, '2018-10-04', '2019-01-04', '2020-05-18 09:45:57.52181', 3, '2020-05-18', '', '2018-10-04');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('fd46fb669ecbe6bec03172f4e79f1ae6', 182, '2019-01-04', '2019-04-04', '2020-05-18 09:46:17.632168', 3, '2020-05-18', '', '2019-01-04');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('601797ce283f241c669ff21ed5d8cd5f', 182, '2019-04-04', '2019-07-04', '2020-05-18 09:46:31.920292', 3, '2020-05-18', '', '2019-04-04');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('858ea58611ef48a5c7393f593979afe0', 182, '2019-07-04', '2019-10-04', '2020-05-18 09:57:08.182102', 3, '2020-05-18', '', '2019-07-04');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('62c39d213168bf5f2b752332ddb8e295', 182, '2019-10-04', '2020-01-04', '2020-05-18 09:57:36.994076', 3, '2020-05-18', '', '2019-10-04');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('179672535901b6b5f2b2c80e588c6fb7', 182, '2020-01-04', '2020-04-04', '2020-05-18 09:57:59.257262', 3, '2020-05-18', '67-2020', '2020-01-04');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('8843a46a6c4a6350d67ed3019f70ccd3', 182, '2020-04-04', '2020-07-04', '2020-05-18 09:58:23.193612', 3, '2020-05-18', '68-2020', '2020-04-04');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('743fd9962561a6f6ffd0670d2b29a53b', 183, '2020-02-02', '2021-02-02', '2020-05-18 10:05:16.521907', 3, '2020-05-18', '69-2020', '2020-02-02');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('48f7dc60653c50ff69896e5b39a22964', 184, '2020-04-03', '2021-04-03', '2020-05-18 10:07:23.629671', 3, '2020-05-18', '70-2020', '2020-04-03');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('ae311d8163506d7d6f42415b39ec2981', 185, '2019-04-19', '2019-10-19', '2020-05-18 10:14:35.978701', 3, '2020-05-18', '', '2019-04-19');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('221a4f880bfc6f103772b76a6fd55de2', 185, '2019-10-19', '2020-04-19', '2020-05-18 10:14:53.044604', 3, '2020-05-18', '', '2019-10-19');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('021595ea46bf0bf70aba8ba65e66245b', 185, '2020-04-19', '2020-10-19', '2020-05-18 10:15:12.244858', 3, '2020-05-18', '71-2020', '2020-04-19');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('1085d35e5e77db0c00c07c6ac3b25056', 186, '2020-04-07', '2021-04-07', '2020-05-18 10:22:49.752641', 3, '2020-05-18', '72-2020', '2020-04-07');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('78c4b8f292fedbfdcc30ddb6759e5dfe', 189, '2019-04-04', '2019-10-04', '2020-05-18 10:25:37.045091', 3, '2020-05-18', '', '2019-04-04');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('f7b7097327b60a1d6062fba92f4f2ae8', 189, '2019-10-04', '2020-04-04', '2020-05-18 10:30:52.221075', 3, '2020-05-18', '', '2019-10-04');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('104f85f4491b79b9bb76ff5524f5d151', 189, '2020-04-04', '2020-10-04', '2020-05-18 10:31:24.629195', 3, '2020-05-18', '73-2020', '2020-04-04');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('32a1fd1cdefb2783d7fd007d1a1638b6', 191, '2020-04-18', '2021-04-18', '2020-05-18 10:35:46.918034', 3, '2020-05-18', '74-2020', '2020-04-18');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('dc448387892c75a7c7dd7132f130bfbb', 193, '2020-04-01', '2021-04-01', '2020-05-18 10:51:56.902162', 3, '2020-05-18', '75-2020', '2020-04-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('e354ebf6f5ba5679e4d87e66df291ca8', 194, '2019-11-01', '2021-02-01', '2020-05-18 10:52:16.66822', 3, '2020-05-18', '', '2019-11-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('a40c6d769c1d0d3bbc60e8b0a3764d26', 195, '2020-02-02', '2021-02-02', '2020-05-18 10:58:22.632146', 3, '2020-05-18', '76-2020', '2020-02-02');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('81becae931b197535f91c7fbc900164d', 196, '2020-02-02', '2021-02-02', '2020-05-18 11:07:30.867015', 3, '2020-05-18', '77-2020', '2020-02-02');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('6b7540873d8674927714a8ee7cf940b9', 234, '2020-01-14', '2020-07-14', '2020-05-18 11:36:36.361492', 3, '2020-05-18', '78-2020', '2020-01-14');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('ffcce685f2bd605a0e449a1431807e1c', 239, '2019-11-02', '2020-02-02', '2020-05-18 11:52:40.225598', 3, '2020-05-18', '', '2019-11-02');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('578973bf0f3c5a512f63415c31019028', 239, '2020-02-02', '2020-05-02', '2020-05-18 11:52:57.658178', 3, '2020-05-18', '79-2020', '2020-02-02');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('a0d654aa487cb6ae87d9cdcb021ed420', 239, '2020-05-02', '2020-08-02', '2020-05-18 11:53:24.145884', 3, '2020-05-18', '80-2020', '2020-05-02');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('8e0bcdd9fe4236030ecd6361564fa61c', 244, '2020-02-13', '2020-08-13', '2020-05-18 12:09:00.555257', 3, '2020-05-18', '81-2020', '2020-02-13');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('4c3ee48a06e9124c01351b87c2f7ad3e', 245, '2020-04-04', '2020-10-04', '2020-05-18 12:15:01.252833', 3, '2020-05-18', '82-2020', '2020-04-04');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('ccfe1c3630292d4b31efd1f9bc10e7b2', 246, '2020-05-02', '2020-11-02', '2020-05-18 12:20:26.848924', 3, '2020-05-18', '83-2020', '2020-05-02');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('bc034fb098f299dbfb24803cde635825', 248, '2020-03-28', '2020-09-28', '2020-05-18 12:28:05.522121', 3, '2020-05-18', '84-2020', '2020-03-28');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('a3bd4a54b843d1eafb3dfdabddaf9af9', 253, '2020-03-22', '2020-09-22', '2020-05-18 12:35:27.076645', 3, '2020-05-18', '85-2020', '2020-03-22');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('57ae8fd49ae4266f932ebc4dc02de22f', 260, '2019-12-25', '2020-06-25', '2020-05-18 12:58:21.853205', 3, '2020-05-18', '', '2019-12-25');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('ed13aac6a328fdb2a59a07f308b01830', 261, '2020-02-18', '2020-08-18', '2020-05-18 13:12:04.831407', 3, '2020-05-18', '86-2020', '2020-02-18');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('361a707c3e21cb33a222c133629ab3ea', 262, '2019-10-18', '2020-01-18', '2020-05-18 13:41:26.435874', 3, '2020-05-18', '', '2019-10-18');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('66bec46c99f7162bfd9beb5ec742521f', 262, '2020-01-18', '2020-04-18', '2020-05-18 13:41:56.17952', 3, '2020-05-18', '87-2020', '2020-01-18');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('151ed3062871513793becb3efefc8cc7', 262, '2020-04-18', '2020-07-18', '2020-05-18 13:42:12.295953', 3, '2020-05-18', '88-2020', '2020-04-18');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('7f1008dd7ec515387bd214df164a136e', 265, '2020-02-10', '2021-08-10', '2020-05-18 14:00:04.624429', 3, '2020-05-18', '89-2020', '2020-02-10');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('369cb45ab23e5d700e8856678350e3f1', 268, '2020-03-20', '2020-09-20', '2020-05-18 14:04:47.069961', 3, '2020-05-18', '90-2020', '2020-03-20');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('86798665d026f9d02f45dc257d709564', 276, '2020-04-05', '2020-10-05', '2020-05-18 14:12:03.40049', 3, '2020-05-18', '91-2020', '2020-04-05');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('e9bb4ce02d2f5d3aad65c252bf254bd0', 280, '2020-04-04', '2020-10-04', '2020-05-18 14:17:07.24667', 3, '2020-05-18', '92-2020', '2020-04-04');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('ee61935287cd52007360ee543f04cb31', 290, '2020-04-04', '2020-07-04', '2020-05-18 14:24:35.215378', 3, '2020-05-18', '93-2020', '2020-04-04');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('658a3887d540a0524f5f2b5f97800014', 135, '2020-06-01', '2020-12-01', '2020-06-12 08:49:16.7178', 3, '2020-06-12', '94-2020', '2020-06-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('48175c409c806d9d1fab2e4a2c4a359a', 73, '2020-06-01', '2020-12-01', '2020-06-12 09:06:27.857814', 3, '2020-06-12', '95-2020', '2020-06-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('ef128f084739059cd4da7fce691867fd', 50, '2020-06-01', '2020-12-01', '2020-06-12 09:14:33.050616', 3, '2020-06-12', '96-2020', '2020-06-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('cc87c0537dff722a952a0579b698dd48', 46, '2020-06-01', '2020-12-01', '2020-06-12 09:18:07.466416', 3, '2020-06-12', '97-2020', '2020-06-01');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('86c339e659480e2b72390092b73b9ff2', 236, '2020-06-08', '2021-06-08', '2020-06-12 09:29:48.443419', 3, '2020-06-12', '98-2020', '2020-06-08');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('243a55ea1e1e3b8ac312dbb47d2c1894', 116, '2020-06-10', '2020-12-10', '2020-06-12 10:29:40.588936', 3, '2020-06-12', '99-2020', '2020-06-10');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('083513441677cfdbc2248234f73e932a', 267, '2020-06-10', '2021-06-10', '2020-06-12 12:20:50.175936', 3, '2020-06-12', '100-2020', '2020-06-10');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('bc15acb5fc62a286b77272d3330edf0d', 237, '2020-06-13', '2021-06-13', '2020-06-12 12:33:12.688394', 3, '2020-06-12', '101-2020', '2020-06-12');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('e131396f816314f0ebcf34bb9a50decc', 391, '2020-06-15', '2020-12-15', '2020-06-16 08:56:56.506913', 3, '2020-06-16', '102-2020', '2020-06-15');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('dbf55f7c46dcd737718e23d22a3ae2dd', 260, '2020-06-25', '2020-12-25', '2020-07-01 12:19:26.321578', 3, '2020-07-01', '103-2020', '2020-06-25');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('40fd4789139957c56db051ce144e17d3', 159, '2020-06-27', '2020-12-27', '2020-07-01 12:30:50.867039', 3, '2020-07-01', '104-2020', '2020-06-27');
INSERT INTO "public"."prolongation" ("hash", "stock_id", "date_before_prolong", "date_after_prolong", "ts", "expert_id", "date_prolong", "act_number", "act_date") VALUES ('d513808e17ad2374c69e1ea55aa46e0d', 88, '2020-07-01', '2021-01-01', '2020-07-01 12:39:48.472298', 3, '2020-07-01', '105-2020', '2020-07-01');


--
-- Data for Name: purpose; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO "public"."purpose" ("id", "name", "ts", "attr") VALUES (0, '--', '2019-12-28 11:09:37.583434', '');
INSERT INTO "public"."purpose" ("id", "name", "ts", "attr") VALUES (1, 'Проведення дослідження (експертизи)', '2020-03-17 14:02:01.806052', 'expertise');
INSERT INTO "public"."purpose" ("id", "name", "ts", "attr") VALUES (2, 'Технічне обслуговування обладнання', '2020-03-17 14:06:40.671071', 'maintenance');
INSERT INTO "public"."purpose" ("id", "name", "ts", "attr") VALUES (3, 'Приготування робочого реактиву (розчину)', '2020-03-18 16:12:38.948107', 'reactiv');
INSERT INTO "public"."purpose" ("id", "name", "ts", "attr") VALUES (4, 'Інше', '2020-04-23 08:47:35.867644', 'other');
INSERT INTO "public"."purpose" ("id", "name", "ts", "attr") VALUES (5, 'Наукова діяльність', '2020-07-01 11:54:34.737934', 'science');
INSERT INTO "public"."purpose" ("id", "name", "ts", "attr") VALUES (6, 'Знищення (утилізація)', '2020-07-02 10:18:56.492213', 'utilisation');


--
-- Data for Name: reactiv; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO "public"."reactiv" ("hash", "reactiv_menu_id", "quantity_inc", "quantity_left", "inc_expert_id", "group_id", "inc_date", "dead_date", "safe_place", "safe_needs", "comment") VALUES ('', 0, 0, 0, 0, 0, '1970-01-01', '1970-01-01', '', '', '');


--
-- Data for Name: reactiv_consume; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO "public"."reactiv_consume" ("hash", "reactiv_hash", "quantity", "inc_expert_id", "consume_ts", "ts", "date") VALUES ('', '', 0, 0, '2020-06-15 13:39:55.968213', '2020-06-15 13:39:55.968213', '1970-01-01');


--
-- Data for Name: reactiv_consume_using; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: reactiv_ingr_reactiv; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: reactiv_ingr_reagent; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: reactiv_menu; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO "public"."reactiv_menu" ("id", "name", "position", "units_id", "comment", "group_id") VALUES (0, '--', 0, 0, '', 0);
INSERT INTO "public"."reactiv_menu" ("id", "name", "position", "units_id", "comment", "group_id") VALUES (9, 'Реагент 2. 5% розчин сульфата заліза (ІІІ)', 0, 1, 'PT13T3lGR2N5WnlPNU4yYTFsa0o3azNZclZYU21zVGVqdFdkSlp5T3lGR2NzWkNJN2szWWhaeU81Tm1lbXNUZWp0V2RwWnlPNU5HYm1zVGVqRm1KN2szWTZaQ0k3azNZMVp5TzVOR2Rtc1RlakZtSjdrM1ltWnlPNU5HZG05MmNtc1RlanhtSjdrM1kxWnlPNU4yY21BeU81TjJabUFTTmdzVGVqbG1KN2szWTBaeU81TldhbXNUZWo1bUo3azNZcFp5TzVOR2FqWnlPNU5tZW1zVGVqOW1KN2szWXlaQ0k3azNZcFp5TzVOR1ptc1RlajltSjdrM1kyWkNJN2szWXBsbko3azNZdlp5TzVObWJtc1RlakZtSjdrM1kyWnlPNU4yYm1zVGVqcG5KN2szWXJWWGFtc1RlajVtSjdrM1l2WnlPNU5tYW1zVGVqVldhbXNUZWpSbUpnc1RlanhtSjdrM1l0WkNJd0FUTWdzVGVqWmxKN2tXYmxObkp3RXpPdFZuYm1zVGF0VjJjbWd6TTcwV2R1WnlPdzFXWW1zamNoQm5jbXNUZWp0V2RKWnlPNU4yYTFsa0o3azNZclZYU21zamNoQkhibUF5TzVOV1ltc1RlanBuSjdrM1lyVlhhbXNUZWp4bUo3azNZaFp5TzVObWVtQXlPNU5XYm1zVGVqOW1KN2szWTBaeU81TldZbXNUZWpabUo3azNZMFoyYnpaeU81TkdibXNUZWpWbko3azNZelpDSTdrM1k2WkNJN2szWTBaeU81TjJjbXNUZWpWV2Ftc1RlalJsSg%3D%3D', 1);
INSERT INTO "public"."reactiv_menu" ("id", "name", "position", "units_id", "comment", "group_id") VALUES (20, 'Реагент 15А. Тест Цімермана', 0, 1, 'PT13T2s5V2F5VkdjbXNUZWpsbUo3azNZa1p5TzVOMmJtc1RlalpuSmdzVGVqbFdlbXNUZWo5bUo3azNZdVp5TzVOV1ltc1RlalpuSjdrM1l2WnlPNU5tZW1zVGVqdFdkcFp5TzVObWJtc1RlajltSjdrM1lxWnlPNU5XWnBaeU81TkdabUF5TzVOR2Jtc1RlajFtSmdBRE14QXlPNU5tZG1BeU81TldkbXNUZWpSbUo3azNZcFp5TzVOMmNtc1RlanRtSjdrM1l2WnlPNU5tY21zVGVqUm1KN2szWXJWWGFtc1RlamRtSmdzVGVqcG1KN2szWXJWWGFtc1RlanhtSjdrM1loWnlPNU4yYW1BeU81TjJabUFTTnhBeU81TldhbXNUZWpSbko3azNZcFp5TzVObWJtc1RlamxtSjdrM1lvTm1KN2szWTZaeU81TjJibXNUZWpKbEpnc2pidngyYmpaeU81Tm1WbVVUTWdzVGVqUm5KN2szWXVaeU81TldacFp5TzVOMlptc1RlakZtSjdrM1lsbG1KN2szWVNaeU9wMVdaelpDTXhzVGIxNW1KN2tXYmxObko0TXpPdFZuYm1zRGN0Rm1KN1EyYnBKWFp3WnlPNU5XZG1zVGVqeG1KN2szWXZaeU81Tm1ibXNUZWpGbUo3azNZMFp5TzVOV1pwWnlPNU5XYm1BeU81TkdibXNUZWoxbUpnQURNeEF5TzVObWRtQXlPNU5XZG1zVGVqeG1KN2szWXZaeU81Tm1lbXNUZWo1bUo3azNZbGxtSjdrM1lpWnlPNU4yYm1zVGVqSm5KN2szWTBaeU81TjJhMWxtSjdrM1l1WnlPNU5XYW1zVGVqUm1KZ016T2gxV2J2Tm1KeEF5TzVOMlptQVNNZ3NUZWpsbUo3azNZMFp5TzVOV2Ftc1RlajVtSjdrM1lwWnlPNU5HYWpaeU81Tm1lbXNUZWo5bUo3azNZU1pDSTc0MmJzOTJZbXNUZWpGa0oxRURJN2szWTBaeU81Tm1ibXNUZWpWV2Ftc1RlamRtSjdrM1loWnlPNU5XWnBaeU81Tm1VbXNUYXRWMmNtQVRNNzBXZHVaeU9wMVdaelpDT3pzVGIxNW1KN0FYYmhaeU9rOVdheVZHY21zVGVqRm1KN2szWXVaeU81TldZbXNUZWoxbUo3azNZeVp5TzVOV1pwWnlPNU5XYm1zVGVqdFdkcFp5TzVOMlVVWkNJN2szWTBaeU81TjJjbXNUZWpWV2Ftc1RlalJsSg%3D%3D', 1);
INSERT INTO "public"."reactiv_menu" ("id", "name", "position", "units_id", "comment", "group_id") VALUES (13, 'Реагент 7А 16% розчин хлоридної кислоти', 0, 1, 'N2szWTFaeU81TkdkbXNUZWpSblp2Tm5KN2szWXNaeU81TldZbXNUZWpKbUo3azNZdlp5TzVOMmFtQXlPNU5XYm1zVGVqOW1KN2szWTBaeU81TldZbXNUZWo1bUo3azNZdlp5TzVOMmExbG1KN2szWXpSbko3azNZdlp5TzVOMmExbG1KN2szWTBaQ0k3azNZNlpDSTdrM1kwWnlPNU4yY21zVGVqVldhbXNUZWpSbEo%3D', 1);
INSERT INTO "public"."reactiv_menu" ("id", "name", "position", "units_id", "comment", "group_id") VALUES (14, 'Реагент 9. Тест з метилбензоатом', 0, 1, 'N1EyYnBKWFp3WnlPNU5XZG1zVGVqeG1KN2szWXZaeU81Tm1ibXNUZWpGbUo3azNZMFp5TzVOV1pwWnlPNU5XYm1BeU81TjJibXNUZWpkbUo3azNZdlp5TzVObWJtc1RlalJuSjdrM1kxbG5KN2szWXNaeU81TjJibXNUZWpObko3azNZaVp5TzVOV1ltQXlPNU5HYm1zVGVqMW1KZ0FETXhBeU81Tm1kbUF5TzVOV2Rtc1RlalJtSjdrM1lwWnlPNU4yY21zVGVqdG1KN2szWXZaeU81Tm1jbXNUZWpSbUo3azNZclZYYW1zVGVqZG1KZ3NUZWpwbUo3azNZclZYYW1zVGVqeG1KN2szWWhaeU81TjJhbUF5TzVOMlptQVNOZ3NUZWpsbUo3azNZMFp5TzVOV2Ftc1RlajVtSjdrM1lwWnlPNU5HYWpaeU81Tm1lbXNUZWo5bUo3azNZU1p5T3AxV1p6WkNNeHNUYjE1bUo3a1dibE5uSjRNek90Vm5ibXNEY3RGbUo3UTJicEpYWndaeU81TldibXNUZWo5bUo3azNZMFp5TzVOV1ltc1RlajltSjdrM1k2WnlPNU5tYm1zVGVqVldhbXNUZWpKbUo3azNZc1p5TzVOV2Ftc1RlalJuSjdrM1lsbG1KN2szWXRaQ0k3azNZNlpDSTdrM1kwWnlPNU4yY21zVGVqVldhbXNUZWpSbEo%3D', 1);
INSERT INTO "public"."reactiv_menu" ("id", "name", "position", "units_id", "comment", "group_id") VALUES (17, 'Реагент 12В. 2% розчин натрій карбонату (Тест Саймона)', 0, 1, 'N1EyYnBKWFp3WnlPNU5XYW1zVGVqUm1KN2szWXZaeU81Tm1kbUF5TzVOR2Jtc1RlajFtSmdBRE14QXlPNU5tZG1BeU81TldkbXNUZWpSbko3azNZaFp5TzVObWJtc1RlajltSjdrM1lpWnlPNU5tY21zVGVqRm1KN2szWXJaQ0k3azNZcVp5TzVOMmExbG1KN2szWXlaeU81TkdkbXNUZWpGbUo3azNZdVpDSTdrM1luWkNJeUF5TzVOV2Ftc1RlalJuSjdrM1lwWnlPNU5tYm1zVGVqbG1KN2szWW9ObUo3azNZNlp5TzVOMmJtc1RlakpsSmdzamJ2eDJialp5TzVObVZtSVRNZ3NUZWpSbko3azNZdVp5TzVOV1pwWnlPNU4yWm1zVGVqRm1KN2szWWxsbUo3azNZU1p5T3AxV1p6WkNNeHNUYjE1bUo3a1dibE5uSjRNek90Vm5ibXNEY3RGbUpnc0RadmxtY2xCbko3azNZaFp5TzVObWJtc1RlajltSjdrM1l0WnlPNU5tYW1zVGVqRm1KN2szWVRaQ0k3azNZMFp5TzVOMmNtc1RlalZXYW1zVGVqUmxK', 1);
INSERT INTO "public"."reactiv_menu" ("id", "name", "position", "units_id", "comment", "group_id") VALUES (19, 'Реагент. 14. Тест з галовою кислотою.', 0, 1, 'PT13T2s5V2F5VkdjbXNUZWpsbUo3azNZMFp5TzVOMmJtc1RlanhtSjdrM1l6WnlPNU5XYW1zVGVqdG1KZ3NUZWpsV2Vtc1RlajltSjdrM1l1WnlPNU5HZG1zVGVqRm1KN2szWW1aeU81TkdkbTkyY21zVGVqeG1KN2szWTFaeU81TjJjbUF5TzVOV2E1WnlPNU4yYm1zVGVqNW1KN2szWWhaeU81Tm1kbXNUZWo5bUo3azNZeVp5TzVOR2Rtc1RlajVtSjdrM1lsbG1KN2szWXpSbko3azNZdVp5TzVOMmJtc1RlanRtSmdzVGVqZG1KZ0FETXhBeU81Tm1kbUF5TzVOV2Ftc1RlalJuSjdrM1l2WnlPNU5HYm1zVGVqTm5KN2szWXBaeU81TjJhbUF5TzVOV2E1WnlPNU4yYm1zVGVqWm5KN2szWXZaeU81TkdibXNUZWpGbUo3azNZblpDSTdrM1luWkNJMXNUWXQxMmJqWkNNZ3NUZWpsbUo3azNZMFp5TzVOV2Ftc1RlajVtSjdrM1lwWnlPNU5HYWpaeU81Tm1lbXNUZWo5bUo3azNZU1pDSTc0MmJzOTJZbVFUTWdzVGVqUm5KN2szWXVaeU81TldacFp5TzVOMlptc1RlakZtSjdrM1lsbG1KN2szWVNaeU9wMVdaelpDTXhzVGIxNW1KN2tXYmxObko0TXpPdFZuYm1zRGN0Rm1KN1EyYnBKWFp3WnlPNU5XZDVaeU81TjJibXNUZWpSbko3azNZdlp5TzVOR2Jtc1Rlak5uSjdrM1lwWnlPNU4yYW1BeU81TldkNVp5TzVOMmJtc1RlalpuSjdrM1l2WnlPNU5HYm1zVGVqRm1KN2szWW5aQ0k3azNZNlpDSTdrM1kwWnlPNU4yY21zVGVqVldhbXNUZWpSbEo%3D', 1);
INSERT INTO "public"."reactiv_menu" ("id", "name", "position", "units_id", "comment", "group_id") VALUES (18, 'Реагент 13А. Тест Саймона з ацетоном', 0, 1, 'PXNEWnZsbWNsQm5KN2szWXBaeU81TkdabXNUZWo5bUo3azNZMlpDSTdrM1lzWnlPNU5XYm1BQ013RURJN2szWTJaQ0k3azNZMVp5TzVOR2Rtc1RlakZtSjdrM1l1WnlPNU4yYm1zVGVqSm1KN2szWXlaeU81TldZbXNUZWp0bUpnc1RlanBtSjdrM1lyVlhhbXNUZWpKbko3azNZMFp5TzVOV1ltc1RlajVtSmdzVGVqZG1KZ0lESTdrM1lwWnlPNU5HZG1zVGVqbG1KN2szWXVaeU81TldhbXNUZWpoMlltc1RlanBuSjdrM1l2WnlPNU5tY21BeU95RkdjeVp5TzVObVZtSVRNZ3NUZWpSbko3azNZdVp5TzVOV1pwWnlPNU4yWm1zVGVqRm1KN2szWWxsbUo3azNZU1p5T3lGR2NzWkNJN2szWVdaeU14QXlPNU5HZG1zVGVqNW1KN2szWWxsbUo3azNZblp5TzVOV1ltc1RlalZXYW1zVGVqSmxKN2tXYmxObkp3RXpPdFZuYm1zVGF0VjJjbWd6TTcwV2R1WnlPdzFXWW1zRFp2bG1jbEJuSjdrM1kxWnlPNU5tYm1zVGVqOW1KN2szWTBaeU81TldacFp5TzVOMmMwWnlPNU5XWW1BeU81TldkbXNUZWo1bUo3azNZcFp5TzVOR2FqWnlPNU5tZW1zVGVqOW1KN2szWXlaQ0k3azNZdlp5TzVOMlptc1RlajltSjdrM1l1WnlPNU5HWm1zVGVqOW1KN2szWTJaQ0k3SVhZd0puSjdrM1l0WnlPNU4yYTFwbUo3azNZaVp5TzVOMmJtc0Ridk5uSjdrM1l0WnlPNU4yYTFwbUo3azNZaVp5TzVOMmJtQXlPNU4yYTFsbUo3azNZdVp5TzVObWJtc1RlalZXYW1zVGVqaDJjbXNUZWo5bUo3azNZdVp5TzVOR1ptc1RlanRXZHBaeU81Tm1kbUF5TzVOV2Rtc2pjaEJIYm1BeU8wNTJZeVZHY21VREk3azNZc1p5TzVOV2JtQUNNd0VESTdrM1kyWkNJN2szWTFsbko3azNZclZYYW1zVGVqSm5KN2szWTBaeU81TldZbXNUZWo1bUpnc1RlalZuSjdrM1lrWnlPNU5XYW1zVGVqTm5KN2szWTFaeU81Tm1jbXNUZWpCbko3azNZdlp5TzVObWNtc1RlalJuSjdrM1lyVlhhbXNUZWo1bUpnc1RlamRtSmdFREk3azNZcFp5TzVOR2Rtc1RlamxtSjdrM1l1WnlPNU5XYW1zVGVqaDJZbXNUZWpwbko3azNZdlp5TzVObVVtc2pidngyYmpaeU81TldRbU1UTWdzVGVqUm5KN2szWXVaeU81TldacFp5TzVOMlptc1RlakZtSjdrM1lsbG1KN2szWVNaeU9wMVdaelpDTXhzVGIxNW1KN2tXYmxObko0TXpPdFZuYm1zRGN0Rm1KN1EyYnBKWFp3WnlPNU5XYm1zVGVqOW1KN2szWXVaeU81TjJibXNUZWpSbko3azNZbGxtSjdrM1l6Um5KN2szWWhaQ0k3azNZNlpDSTdrM1loWnlPNU5tYm1zVGVqOW1KN2szWXRaeU81Tm1hbXNUZWpGbUo3azNZVFpDSTdrM1kwWnlPNU4yY21zVGVqVldhbXNUZWpSbEo%3D', 1);
INSERT INTO "public"."reactiv_menu" ("id", "name", "position", "units_id", "comment", "group_id") VALUES (104, 'Тестовий розчин 1', 0, 1, 'PXNUZWo5bUo3azNZdVp5TzVOR2FqWnlPNU5XYW1zVGVqUm5KN2szWWhaeU81TldibXNUZWo5bUo3azNZMFp5TzVObWRtc1RlakZtSmdzVGVqcG1KN2szWXBaeU81Tm1ibXNUZWpWV2Ftc1RlakpuSjdrM1l2WnlPNU5tZG1zVGVqUm5KN2szWXpaQ0k3UTNiMUZuSnhBeU81Tm1ibXNUZWpsbUo3azNZb05tSjdrM1k2WnlPNU4yYm1zVGVqSm5KZ3NUZWpwbUo3azNZcFp5TzVObWRtc1RlajltSjdrM1kwWnlPNU4yY21zVGVqVldhbXNUZWpSbEo3UTNiMUZuSg%3D%3D', 2);
INSERT INTO "public"."reactiv_menu" ("id", "name", "position", "units_id", "comment", "group_id") VALUES (105, 'Тестовий розчин 2', 0, 1, 'PXNUZWo5bUo3azNZdVp5TzVOR2FqWnlPNU5XYW1zVGVqUm5KN2szWWhaeU81TldibXNUZWo5bUo3azNZMFp5TzVObWRtc1RlakZtSmdzVGVqcG1KN2szWXBaeU81Tm1ibXNUZWpWV2Ftc1RlakpuSjdrM1l2WnlPNU5tZG1zVGVqUm5KN2szWXpaQ0k3UTNiMUZuSnlBeU81Tm1ibXNUZWpsbUo3azNZb05tSjdrM1k2WnlPNU4yYm1zVGVqSm5KZ3NUZWpwbUo3azNZcFp5TzVObWRtc1RlajltSjdrM1kwWnlPNU4yY21zVGVqVldhbXNUZWpSbEo3UTNiMUZuSg%3D%3D', 2);
INSERT INTO "public"."reactiv_menu" ("id", "name", "position", "units_id", "comment", "group_id") VALUES (106, 'Тестовий розчин 3', 0, 1, 'PXNUZWo5bUo3azNZdVp5TzVOR2FqWnlPNU5XYW1zVGVqUm5KN2szWWhaeU81TldibXNUZWo5bUo3azNZMFp5TzVObWRtc1RlakZtSmdzVGVqcG1KN2szWXBaeU81Tm1ibXNUZWpWV2Ftc1RlakpuSjdrM1l2WnlPNU5tZG1zVGVqUm5KN2szWXpaQ0k3UTNiMUZuSnpBeU81Tm1ibXNUZWpsbUo3azNZb05tSjdrM1k2WnlPNU4yYm1zVGVqSm5KZ3NUZWpwbUo3azNZcFp5TzVObWRtc1RlajltSjdrM1kwWnlPNU4yY21zVGVqVldhbXNUZWpSbEo3UTNiMUZuSg%3D%3D', 2);
INSERT INTO "public"."reactiv_menu" ("id", "name", "position", "units_id", "comment", "group_id") VALUES (107, 'Тестовий розчин 4', 0, 1, 'PXNUZWo5bUo3azNZdVp5TzVOR2FqWnlPNU5XYW1zVGVqUm5KN2szWWhaeU81TldibXNUZWo5bUo3azNZMFp5TzVObWRtc1RlakZtSmdzVGVqcG1KN2szWXBaeU81Tm1ibXNUZWpWV2Ftc1RlakpuSjdrM1l2WnlPNU5tZG1zVGVqUm5KN2szWXpaQ0k3UTNiMUZuSjBBeU81Tm1ibXNUZWpsbUo3azNZb05tSjdrM1k2WnlPNU4yYm1zVGVqSm5KZ3NUZWpwbUo3azNZcFp5TzVObWRtc1RlajltSjdrM1kwWnlPNU4yY21zVGVqVldhbXNUZWpSbEo3UTNiMUZuSg%3D%3D', 2);
INSERT INTO "public"."reactiv_menu" ("id", "name", "position", "units_id", "comment", "group_id") VALUES (108, 'Тестовий розчин 5', 0, 1, 'PXNUZWo5bUo3azNZdVp5TzVOR2FqWnlPNU5XYW1zVGVqUm5KN2szWWhaeU81TldibXNUZWo5bUo3azNZMFp5TzVObWRtc1RlakZtSmdzVGVqcG1KN2szWXBaeU81Tm1ibXNUZWpWV2Ftc1RlakpuSjdrM1l2WnlPNU5tZG1zVGVqUm5KN2szWXpaQ0k3UTNiMUZuSjFBeU81Tm1ibXNUZWpsbUo3azNZb05tSjdrM1k2WnlPNU4yYm1zVGVqSm5KZ3NUZWpwbUo3azNZcFp5TzVObWRtc1RlajltSjdrM1kwWnlPNU4yY21zVGVqVldhbXNUZWpSbEo3UTNiMUZuSg%3D%3D', 2);
INSERT INTO "public"."reactiv_menu" ("id", "name", "position", "units_id", "comment", "group_id") VALUES (109, 'Тестовий розчин 6', 0, 1, 'PXNUZWo5bUo3azNZdVp5TzVOR2FqWnlPNU5XYW1zVGVqUm5KN2szWWhaeU81TldibXNUZWo5bUo3azNZMFp5TzVObWRtc1RlakZtSmdzVGVqcG1KN2szWXBaeU81Tm1ibXNUZWpWV2Ftc1RlakpuSjdrM1l2WnlPNU5tZG1zVGVqUm5KN2szWXpaQ0k3UTNiMUZuSjJBeU81Tm1ibXNUZWpsbUo3azNZb05tSjdrM1k2WnlPNU4yYm1zVGVqSm5KZ3NUZWpwbUo3azNZcFp5TzVObWRtc1RlajltSjdrM1kwWnlPNU4yY21zVGVqVldhbXNUZWpSbEo3UTNiMUZuSg%3D%3D', 2);
INSERT INTO "public"."reactiv_menu" ("id", "name", "position", "units_id", "comment", "group_id") VALUES (110, 'Тестовий розчин 7', 0, 1, 'PXNUZWo5bUo3azNZdVp5TzVOR2FqWnlPNU5XYW1zVGVqUm5KN2szWWhaeU81TldibXNUZWo5bUo3azNZMFp5TzVObWRtc1RlakZtSmdzVGVqcG1KN2szWXBaeU81Tm1ibXNUZWpWV2Ftc1RlakpuSjdrM1l2WnlPNU5tZG1zVGVqUm5KN2szWXpaQ0k3UTNiMUZuSjNBeU81Tm1ibXNUZWpsbUo3azNZb05tSjdrM1k2WnlPNU4yYm1zVGVqSm5KZ3NUZWpwbUo3azNZcFp5TzVObWRtc1RlajltSjdrM1kwWnlPNU4yY21zVGVqVldhbXNUZWpSbEo3UTNiMUZuSg%3D%3D', 2);
INSERT INTO "public"."reactiv_menu" ("id", "name", "position", "units_id", "comment", "group_id") VALUES (111, 'Тестовий розчин 8', 0, 1, 'PXNUZWo5bUo3azNZdVp5TzVOR2FqWnlPNU5XYW1zVGVqUm5KN2szWWhaeU81TldibXNUZWo5bUo3azNZMFp5TzVObWRtc1RlakZtSmdzVGVqcG1KN2szWXBaeU81Tm1ibXNUZWpWV2Ftc1RlakpuSjdrM1l2WnlPNU5tZG1zVGVqUm5KN2szWXpaQ0k3UTNiMUZuSjRBeU81Tm1ibXNUZWpsbUo3azNZb05tSjdrM1k2WnlPNU4yYm1zVGVqSm5KZ3NUZWpwbUo3azNZcFp5TzVObWRtc1RlajltSjdrM1kwWnlPNU4yY21zVGVqVldhbXNUZWpSbEo3UTNiMUZuSg%3D%3D', 2);
INSERT INTO "public"."reactiv_menu" ("id", "name", "position", "units_id", "comment", "group_id") VALUES (112, 'Тестовий розчин 9', 0, 1, 'PXNUZWo5bUo3azNZdVp5TzVOR2FqWnlPNU5XYW1zVGVqUm5KN2szWWhaeU81TldibXNUZWo5bUo3azNZMFp5TzVObWRtc1RlakZtSmdzVGVqcG1KN2szWXBaeU81Tm1ibXNUZWpWV2Ftc1RlakpuSjdrM1l2WnlPNU5tZG1zVGVqUm5KN2szWXpaQ0k3UTNiMUZuSjVBeU81Tm1ibXNUZWpsbUo3azNZb05tSjdrM1k2WnlPNU4yYm1zVGVqSm5KZ3NUZWpwbUo3azNZcFp5TzVObWRtc1RlajltSjdrM1kwWnlPNU4yY21zVGVqVldhbXNUZWpSbEo3UTNiMUZuSg%3D%3D', 2);
INSERT INTO "public"."reactiv_menu" ("id", "name", "position", "units_id", "comment", "group_id") VALUES (113, 'Тестовий розчин 10', 0, 1, 'N2szWXZaeU81Tm1ibXNUZWpoMlltc1RlamxtSjdrM1kwWnlPNU5XWW1zVGVqMW1KN2szWXZaeU81TkdkbXNUZWpabko3azNZaFpDSTdrM1lxWnlPNU5XYW1zVGVqNW1KN2szWWxsbUo3azNZeVp5TzVOMmJtc1RlalpuSjdrM1kwWnlPNU4yY21BeU8wOVdkeFpDTXhBeU81Tm1ibXNUZWpsbUo3azNZb05tSjdrM1k2WnlPNU4yYm1zVGVqSm5KZ3NUZWpwbUo3azNZcFp5TzVObWRtc1RlajltSjdrM1kwWnlPNU4yY21zVGVqVldhbXNUZWpSbEo3UTNiMUZuSg%3D%3D', 2);
INSERT INTO "public"."reactiv_menu" ("id", "name", "position", "units_id", "comment", "group_id") VALUES (34, 'Розчин натрій гідроксиду (1.0 н)', 0, 1, '', 1);
INSERT INTO "public"."reactiv_menu" ("id", "name", "position", "units_id", "comment", "group_id") VALUES (33, 'Розчин натрій гідроксиду (1%) (для дослідженя канабісу)', 0, 1, 'PT13T2s5V2F5VkdjbXNUZWpsbUo3azNZa1p5TzVOMmJtc1RlalpuSmdzVGVqbFdlbXNUZWo5bUo3azNZdVp5TzVOV1ltc1RlalpuSjdrM1l2WnlPNU5tZW1zVGVqdFdkcFp5TzVObWJtc1RlajltSjdrM1lxWnlPNU5XWnBaeU81TkdabUF5TzVOR2Jtc1RlajFtSmdBRE13RURJN2szWWhaeU81Tm1ibUF5TzVOV2Rtc1RlalJtSjdrM1lwWnlPNU4yY21zVGVqdG1KN2szWXZaeU81Tm1jbXNUZWpSbUo3azNZclZYYW1zVGVqZG1KZ3NUZWpwbUo3azNZclZYYW1zVGVqSm5KN2szWTBaeU81TldZbXNUZWo1bUpnc1RlamRtSmdBVE03a1dibE5uSndFek90Vm5ibXNUYXRWMmNtZ3pNNzBXZHVaeU93MVdZbXNqYnZ4MmJqWnlPNU5XWTVaeU81Tm1ibXNUZWo1bUo3azNZaFp5TzVObWRtc1RlalZuSjdrM1kwWnlPNU4yYm1zVGVqZG1KN2szWXBaeU81Tm1jbXNUZWpCbEo%3D', 1);
INSERT INTO "public"."reactiv_menu" ("id", "name", "position", "units_id", "comment", "group_id") VALUES (36, 'розчин Тривкого синього Б (0,05%) для дослідження канабісу', 0, 1, 'PT13T3AxV1p6WkNNeHNUYjE1bUo3a1dibE5uSjRNek90Vm5ibXNEY3RGbUo3UTJicEpYWndaeU81TldkbXNUZWpSbUo3azNZcFp5TzVOMmNtc1RlanRtSjdrM1l2WnlPNU5tY21zVGVqUm1KN2szWXJWWGFtc1RlamRtSmdzVGVqcG1KN2szWXJWWGFtc1RlakpuSjdrM1kwWnlPNU5XWW1zVGVqNW1KZ3NUZWpWbko3azNZdVp5TzVOV2Ftc1RlamgyWW1zVGVqcG5KN2szWXZaeU81Tm1jbUF5TzA1Mll5VkdjbUVESTdrM1lzWnlPNU5XYm1BQ014QXlPNU5tZG1BeU81TldhbXNUZWpSbko3azNZcFp5TzVObWJtc1RlamxtSjdrM1lvTm1KN2szWTZaeU81TjJibXNUZWpKbkpnc1RlakprSmdzVGVqOW1KN2szWW5aeU81TjJibXNUZWpSblp2Tm5KN2szWXVaeU81TldhbXNUZWpObkpnc1RlajltSjdrM1luWnlPNU4yYm1zVGVqdG1KN2szWTJaeU81TldhbXNUZWpKbko3azNZMFpDSTdJWFl3Sm5KN2szWW5aeU81TldibUFTTjdJWFl3eG1KZ3NUZWpkbUpnVURNd3NEWnZsbWNsQm5Kd3NUYXRWMmNtQVRNNzBXZHVaeU9wMVdaelpDT3pzVGIxNW1KN0FYYmhaQ0k3UTJicEpYWndaeU81TldZNVp5TzVObWJtc1RlajVtSjdrM1loWnlPNU5tZG1zVGVqVm5KN2szWTBaeU81TjJibXNUZWpkbUo3azNZcFp5TzVObWNtc1RlakJsSg%3D%3D', 1);
INSERT INTO "public"."reactiv_menu" ("id", "name", "position", "units_id", "comment", "group_id") VALUES (24, 'Реагент 16D. Тест з динітробензолом', 0, 1, 'PXNqYnZ4MmJqWnlPNU5XZG1zVGVqUm5KN2szWXpaeU81TldacFp5TzVOR2RtQXlPNU5XWTVaeU81Tm1ibXNUZWo1bUo3azNZaFp5TzVObWJtc1RlajltSjdrM1lyWnlPNU5XYW1zVGVqWmxKN2tXYmxObkp3RXpPdFZuYm1zVGF0VjJjbWd6TTcwV2R1WnlPdzFXWW1zVGF0VjJjbUFUTTcwV2R1WnlPcDFXWnpaQ096c1RiMTVtSjdBWGJoWnlPazlXYXlWR2Ntc1RlakZXZW1zVGVqeG1KN2szWXZaeU81TjJhbXNUZWp0V2RwWnlPNU5HYm1zVGVqZG1KN2szWXVaeU81TldacFp5TzVOR2Jtc1RlamxtSjdrM1kwWnlPNU5XWnBaeU81TjJhMWxtSjdrM1lzWnlPNU4yYm1zVGVqQm5KZ3NUZWp4bUo3azNZdFpDSXdBVE1nc1RlalpuSmdzVGVqVm5KN2szWXNaeU81TjJibXNUZWpwbko3azNZdVp5TzVOV1pwWnlPNU5tWW1zVGVqOW1KN2szWXlaeU81TkdkbXNUZWp0V2RwWnlPNU5tYm1zVGVqbG1KN2szWWtaQ0kwQXlPaDFXYnZObUp4QXlPNU4yWm1BU01nc1RlamxtSjdrM1kwWnlPNU5XYW1zVGVqNW1KN2szWXBaeU81Tkdhalp5TzVObWVtc1RlajltSjdrM1lTWkNJRVpUTTdrV2JsTm5Kd0V6T3RWbmJtc1RhdFYyY21nek03MFdkdVp5T3cxV1ltc1RlakZXZW1zVGVqeG1KN2szWXZaeU81TjJhbXNUZWp0V2RwWnlPNU5HYm1zVGVqZG1KN2szWXVaeU81TldacFp5TzVOR2Jtc1RlamxtSjdrM1kwWnlPNU5XWnBaeU81TjJhMWxtSjdrM1lzWnlPNU4yYm1zVGVqQm5KZ3NUZWp4bUo3azNZdFpDSXdBVE1nc1RlalpuSmdzVGVqVm5KN2szWXNaeU81TjJibXNUZWpwbko3azNZdVp5TzVOV1pwWnlPNU5tWW1zVGVqOW1KN2szWXlaeU81TkdkbXNUZWp0V2RwWnlPNU5tYm1zVGVqbG1KN2szWWtaQ0l6c1RZdDEyYmpaU01nc1RlamRtSmdFREk3azNZcFp5TzVOR2Rtc1RlamxtSjdrM1l1WnlPNU5XYW1zVGVqaDJZbXNUZWpwbko3azNZdlp5TzVObVVtQXlPNU4yVW1ZVE1nc1RlalJuSjdrM1l1WnlPNU5XWnBaeU81TjJabXNUZWpGbUo3azNZbGxtSjdrM1lTWnlPcDFXWnpaQ014c1RiMTVtSjdrV2JsTm5KNE16T3RWbmJtc0RjdEZtSjdRMmJwSlhad1p5TzVOV2Ftc1RlalJtSjdrM1l2WnlPNU5tZG1BeU81TkdibXNUZWoxbUpnQURNeEF5TzVObWRtQXlPNU5XZG1zVGVqUm1KN2szWXBaeU81TjJjbXNUZWp0bUo3azNZdlp5TzVObWNtc1RlalJtSjdrM1lyVlhhbXNUZWpkbUpnc1RlanBtSjdrM1lwWnlPNU5HZG1zVGVqdFdkcFp5TzVOR2JtQUNNeEF5TzVOV2Ftc1RlalJuSjdrM1lwWnlPNU5tYm1zVGVqbG1KN2szWW9ObUo3azNZNlp5TzVOMmJtc1RlakpsSmdzRFp2bG1jbEJuSjdrM1lXWkNJMkVESTdrM1kwWnlPNU5tYm1zVGVqVldhbXNUZWpkbUo3azNZaFp5TzVOV1pwWnlPNU5tVW1zVGF0VjJjbUFUTTcwV2R1WnlPcDFXWnpaQ096c1RiMTVtSjdBWGJoWnlPazlXYXlWR2Ntc1RlakZXZW1zVGVqeG1KN2szWXZaeU81TjJhbXNUZWp0V2RwWnlPNU5HYm1zVGVqZG1KN2szWXVaeU81TldacFp5TzVOR2Jtc1RlamxtSjdrM1kwWnlPNU5XWnBaeU81TjJhMWxtSjdrM1lzWnlPNU4yYm1zVGVqQm5KZ3NUZWp4bUo3azNZdFpDSXdBVE1nc1RlalpuSmdzVGVqVm5KN2szWXNaeU81TjJibXNUZWpwbko3azNZdVp5TzVOV1pwWnlPNU5tWW1zVGVqOW1KN2szWXlaeU81TkdkbXNUZWp0V2RwWnlPNU5tYm1zVGVqbG1KN2szWWtaQ0l5c1RZdDEyYmpaU01nc1RlamRtSmdFREk3UTJicEpYWndaeU81TldRbVlUTWdzVGVqUm5KN2szWXVaeU81TldacFp5TzVOMlptc1RlakZtSjdrM1lsbG1KN2szWVNaeU9wMVdaelpDTXhzVGIxNW1KN2tXYmxObko0TXpPdFZuYm1zRGN0Rm1KN2szWTFaeU81Tm1ibXNUZWp0V2RwWnlPNU5HYm1zVGVqOW1KN2szWXRaeU81TldacFp5TzVOR2NtQXlPNU5HZG05MmNtc1RlalJuSjdrM1l6WnlPNU4yYTFsbUo3azNZdVp5TzVOR2Rtc1RlalZuSjdrM1l6WnlPNU5XYW1zVGVqSm5KN2szWXdaQ0k3azNZaFp5TzVObWJtQXlPNU5XYm1zVGVqOW1KN2szWXNaeU81TjJibXNUZWpwbko3azNZdVp5TzVOV1pwWnlPNU5tWW1zVGVqOW1KN2szWXlaeU81TkdkbXNUZWp0V2RwWnlPNU5tYm1zVGVqbG1KN2szWWtaQ0k3azNZNlpDSTdrM1kwWnlPNU4yY21zVGVqVldhbXNUZWpSbEo%3D', 1);
INSERT INTO "public"."reactiv_menu" ("id", "name", "position", "units_id", "comment", "group_id") VALUES (22, 'Реагент 16 В. Тест з динітробензолом', 0, 1, 'PXNqYnZ4MmJqWnlPNU5XZG1zVGVqUm5KN2szWXpaeU81TldacFp5TzVOR2RtQXlPNU5XWTVaeU81Tm1ibXNUZWo1bUo3azNZaFp5TzVObWJtc1RlajltSjdrM1lyWnlPNU5XYW1zVGVqWmxKN2tXYmxObkp3RXpPdFZuYm1zVGF0VjJjbWd6TTcwV2R1WnlPdzFXWW1zVGF0VjJjbUFUTTcwV2R1WnlPcDFXWnpaQ096c1RiMTVtSjdBWGJoWnlPazlXYXlWR2Ntc1RlakZXZW1zVGVqeG1KN2szWXZaeU81TjJhbXNUZWp0V2RwWnlPNU5HYm1zVGVqZG1KN2szWXVaeU81TldacFp5TzVOR2Jtc1RlamxtSjdrM1kwWnlPNU5XWnBaeU81TjJhMWxtSjdrM1lzWnlPNU4yYm1zVGVqQm5KZ3NUZWp4bUo3azNZdFpDSXdBVE1nc1RlalpuSmdzVGVqVm5KN2szWXNaeU81TjJibXNUZWpwbko3azNZdVp5TzVOV1pwWnlPNU5tWW1zVGVqOW1KN2szWXlaeU81TkdkbXNUZWp0V2RwWnlPNU5tYm1zVGVqbG1KN2szWWtaQ0kwQXlPaDFXYnZObUp4QXlPNU4yWm1BU01nc1RlamxtSjdrM1kwWnlPNU5XYW1zVGVqNW1KN2szWXBaeU81Tkdhalp5TzVObWVtc1RlajltSjdrM1lTWkNJRVpUTTdrV2JsTm5Kd0V6T3RWbmJtc1RhdFYyY21nek03MFdkdVp5T3cxV1ltc1RlakZXZW1zVGVqeG1KN2szWXZaeU81TjJhbXNUZWp0V2RwWnlPNU5HYm1zVGVqZG1KN2szWXVaeU81TldacFp5TzVOR2Jtc1RlamxtSjdrM1kwWnlPNU5XWnBaeU81TjJhMWxtSjdrM1lzWnlPNU4yYm1zVGVqQm5KZ3NUZWp4bUo3azNZdFpDSXdBVE1nc1RlalpuSmdzVGVqVm5KN2szWXNaeU81TjJibXNUZWpwbko3azNZdVp5TzVOV1pwWnlPNU5tWW1zVGVqOW1KN2szWXlaeU81TkdkbXNUZWp0V2RwWnlPNU5tYm1zVGVqbG1KN2szWWtaQ0l6c1RZdDEyYmpaU01nc1RlamRtSmdFREk3azNZcFp5TzVOR2Rtc1RlamxtSjdrM1l1WnlPNU5XYW1zVGVqaDJZbXNUZWpwbko3azNZdlp5TzVObVVtQXlPNU4yVW1ZVE1nc1RlalJuSjdrM1l1WnlPNU5XWnBaeU81TjJabXNUZWpGbUo3azNZbGxtSjdrM1lTWnlPcDFXWnpaQ014c1RiMTVtSjdrV2JsTm5KNE16T3RWbmJtc0RjdEZtSjdRMmJwSlhad1p5TzVOV2Ftc1RlalJtSjdrM1l2WnlPNU5tZG1BeU81TkdibXNUZWoxbUpnQURNeEF5TzVObWRtQXlPNU5XZG1zVGVqUm1KN2szWXBaeU81TjJjbXNUZWp0bUo3azNZdlp5TzVObWNtc1RlalJtSjdrM1lyVlhhbXNUZWpkbUpnc1RlanBtSjdrM1lwWnlPNU5HZG1zVGVqdFdkcFp5TzVOR2JtQUNNeEF5TzVOV2Ftc1RlalJuSjdrM1lwWnlPNU5tYm1zVGVqbG1KN2szWW9ObUo3azNZNlp5TzVOMmJtc1RlakpsSmdzRFp2bG1jbEJuSjdrM1lXWkNJMkVESTdrM1kwWnlPNU5tYm1zVGVqVldhbXNUZWpkbUo3azNZaFp5TzVOV1pwWnlPNU5tVW1zVGF0VjJjbUFUTTcwV2R1WnlPcDFXWnpaQ096c1RiMTVtSjdBWGJoWnlPazlXYXlWR2Ntc1RlakZXZW1zVGVqeG1KN2szWXZaeU81TjJhbXNUZWp0V2RwWnlPNU5HYm1zVGVqZG1KN2szWXVaeU81TldacFp5TzVOR2Jtc1RlamxtSjdrM1kwWnlPNU5XWnBaeU81TjJhMWxtSjdrM1lzWnlPNU4yYm1zVGVqQm5KZ3NUZWp4bUo3azNZdFpDSXdBVE1nc1RlalpuSmdzVGVqVm5KN2szWXNaeU81TjJibXNUZWpwbko3azNZdVp5TzVOV1pwWnlPNU5tWW1zVGVqOW1KN2szWXlaeU81TkdkbXNUZWp0V2RwWnlPNU5tYm1zVGVqbG1KN2szWWtaQ0l5c1RZdDEyYmpaU01nc1RlamRtSmdFREk3UTJicEpYWndaeU81TldRbVlUTWdzVGVqUm5KN2szWXVaeU81TldacFp5TzVOMlptc1RlakZtSjdrM1lsbG1KN2szWVNaeU9wMVdaelpDTXhzVGIxNW1KN2tXYmxObko0TXpPdFZuYm1zRGN0Rm1KN2szWTFaeU81Tm1ibXNUZWp0V2RwWnlPNU5HYm1zVGVqOW1KN2szWXRaeU81TldacFp5TzVOR2NtQXlPNU5HZG05MmNtc1RlalJuSjdrM1l6WnlPNU4yYTFsbUo3azNZdVp5TzVOR2Rtc1RlalZuSjdrM1l6WnlPNU5XYW1zVGVqSm5KN2szWXdaQ0k3azNZaFp5TzVObWJtQXlPNU5XYm1zVGVqOW1KN2szWXNaeU81TjJibXNUZWpwbko3azNZdVp5TzVOV1pwWnlPNU5tWW1zVGVqOW1KN2szWXlaeU81TkdkbXNUZWp0V2RwWnlPNU5tYm1zVGVqbG1KN2szWWtaQ0k3azNZNlpDSTdrM1kwWnlPNU4yY21zVGVqVldhbXNUZWpSbEo%3D', 1);
INSERT INTO "public"."reactiv_menu" ("id", "name", "position", "units_id", "comment", "group_id") VALUES (8, 'Реагент 3. Тест Мекке', 0, 1, 'PT13TzVOV2Ftc1RlalJuSjdrM1l2WnlPNU5HYm1zVGVqTm5KN2szWXBaeU81TjJhbUF5TzVOV2E1WnlPNU4yYm1zVGVqUm5KN2szWXpaeU81TldhbXNUZWo1bUo3azNZbGxtSjdrM1lzWnlPNU5XWnBaeU81TjJjbUF5TzVOMlptQVNNZ3NUZWpsbUo3azNZMFp5TzVOV2Ftc1RlajVtSjdrM1lwWnlPNU5HYWpaeU81Tm1lbXNUZWo5bUo3azNZeVpDSTdrM1lwWnlPNU5HZG1zVGVqOW1KN2szWXNaeU81TjJjbXNUZWpsbUo3azNZclpDSTdrM1lwbG5KN2szWXZaeU81Tm1ibXNUZWpSbko3azNZaFp5TzVObVptc1RlalJuWnZObko3azNZc1p5TzVOV2Rtc1Rlak5uSmdzVGVqbFdlbXNUZWo5bUo3azNZdVp5TzVOV1ltc1RlalpuSjdrM1l2WnlPNU5tY21zVGVqUm5KN2szWXVaeU81TldacFp5TzVOMmMwWnlPNU5tYm1zVGVqOW1KN2szWXJaQ0lnc1RlanhtSjdrM1l0WkNJd0FUTWdzVGVqWmxK', 1);
INSERT INTO "public"."reactiv_menu" ("id", "name", "position", "units_id", "comment", "group_id") VALUES (16, 'Реагент 12А. Тест Саймона', 0, 1, 'PXNqYnZ4MmJqWnlPNU5HZG1zVGVqTm5KN2szWWxsbUo3azNZVVp5T3AxV1p6WkNNeHNUYjE1bUo3a1dibE5uSjRNek90Vm5ibXNEY3RGbUo3UTJicEpYWndaeU81TldhbXNUZWpSbUo3azNZdlp5TzVObWRtQXlPNU5HYm1zVGVqMW1KZ0FETXhBeU81Tm1kbUF5TzVOV2Rtc1RlalJuSjdrM1loWnlPNU5tYm1zVGVqOW1KN2szWWlaeU81Tm1jbXNUZWpGbUo3azNZclpDSTdrM1lxWnlPNU4yYTFsbUo3azNZeVp5TzVOR2Rtc1RlakZtSjdrM1l1WkNJN2szWW5aQ0l5QXlPNU5XYW1zVGVqUm5KN2szWXBaeU81Tm1ibXNUZWpsbUo3azNZb05tSjdrM1k2WnlPNU4yYm1zVGVqSmxKZ3NqYnZ4MmJqWnlPNU5tVm1JVE1nc1RlalJuSjdrM1l1WnlPNU5XWnBaeU81TjJabXNUZWpGbUo3azNZbGxtSjdrM1lTWnlPcDFXWnpaQ014c1RiMTVtSjdrV2JsTm5KNE16T3RWbmJtc0RjdEZtSjdRMmJwSlhad1p5TzVOV2Rtc1RlalJtSjdrM1lyVlhhbXNUZWpkbUo3azNZbGxtSjdrM1lrWnlPNU5HZG05MmNtc1RlanhtSjdrM1loWnlPNU5HZG1zVGVqVldhbXNUZWpOSGRtc1RlakZtSmdzVGVqeG1KN2szWXRaQ0l3RURJN2szWXBaeU81TkdkbXNUZWpGbUo3azNZa1p5TzVOMmJtc1RlalJtSmdzVGVqMW1KN2szWXJWWGFtc1RlalJuSjdrM1l2WnlPNU5HY21BeU9oMVdidk5tSjdrM1lwWnlPNU5HWm1zVGVqOW1KN2szWTJaQ0k3azNZcGxuSjdrM1l2WnlPNU5tYm1zVGVqRm1KN2szWTJaeU81TjJibXNUZWpwbko3azNZclZYYW1zVGVqNW1KN2szWXZaeU81Tm1hbXNUZWpWV2Ftc1RlalJtSmdzVGVqeG1KN2szWXRaQ0l3a0RJN2szWTJaQ0k3azNZaGxuSjdrM1lyVlhhbXNUZWpKbko3azNZMFp5TzVOV1ltc1RlajVtSmdzVGVqVm5KN2szWWtaeU81TldhbXNUZWpObko3azNZMVp5TzVObWNtc1RlakJuSjdrM1l2WnlPNU5tY21zVGVqUm5KN2szWXJWWGFtc1RlajVtSmdzVGVqZG1KZ2t6T2gxV2J2Tm1Kd0F5TzVOV2Ftc1RlalJuSjdrM1lwWnlPNU5tYm1zVGVqbG1KN2szWW9ObUo3azNZNlp5TzVOMmJtc1RlakpsSmdzamJ2eDJialp5TzVOV1FtSVRNZ3NUZWpSbko3azNZdVp5TzVOV1pwWnlPNU4yWm1zVGVqRm1KN2szWWxsbUo3azNZU1p5T3AxV1p6WkNNeHNUYjE1bUo3a1dibE5uSjRNek90Vm5ibXNEY3RGbUo3azNZaFp5TzVObWJtc1RlajltSjdrM1l0WnlPNU5tYW1zVGVqRm1KN2szWVRaQ0k3azNZMFp5TzVOMmNtc1RlalZXYW1zVGVqUmxK', 1);
INSERT INTO "public"."reactiv_menu" ("id", "name", "position", "units_id", "comment", "group_id") VALUES (7, 'Реактив Маркі', 0, 1, 'PXNUZWpWbko3azNZdVp5TzVOMmExbG1KN2szWXNaeU81TldZbXNUZWoxbUo3azNZeVp5TzVOMmJtc1RlalptSmdzVGVqVm5KN2szWXVaeU81TldhbXNUZWpoMlltc1RlajltSjdrM1l5WkNJN1FuYmpKWFp3WnlOekF5TzVOR2Jtc1RlajFtSmdFREk3azNZcFp5TzVOR2Rtc1RlakZtSjdrM1lrWnlPNU4yYm1zVGVqUm1KZ3NUZWpsbUo3azNZMFp5TzVOMmJtc1RlanhtSjdrM1l6WnlPNU5XYW1zVGVqdG1KZ3NUZWpsV2Vtc1RlajltSjdrM1l1WnlPNU5HZG1zVGVqRm1KN2szWW1aeU81TkdkbTkyY21zVGVqeG1KN2szWTFaeU81TjJjbUF5TzVOV2E1WnlPNU4yYm1zVGVqNW1KN2szWWhaeU81Tm1kbXNUZWo5bUo3azNZeVp5TzVOR2Rtc1RlajVtSjdrM1lsbG1KN2szWXpSbko3azNZdVp5TzVOMmJtc1RlanRtSmdzVGVqeG1KN2szWXRaQ0k1QXlPNU4yYm1zVGVqUmtK', 1);
INSERT INTO "public"."reactiv_menu" ("id", "name", "position", "units_id", "comment", "group_id") VALUES (15, 'Реагент 10. Тест Вагнера', 0, 1, 'PXNEWnZsbWNsQm5KN2szWXBaeU81TkdabXNUZWo5bUo3azNZMlpDSTdrM1lzWnlPNU5XYm1BQ013RURJN2szWTJaQ0k3azNZcFp5TzVOR2Rtc1RlamxtSjdrM1l1WnlPNU5XYW1zVGVqaDJZbXNUZWpwbko3azNZdlp5TzVObWNtQXlPNU5HYXpaeU81TjJhMWxtSjdrM1l0WnlPNU5XZG1zVGVqTm5KZ3NUZWoxbUo3azNZclZYYW1zVGVqUm5KN2szWXZaeU81TkdjbUF5T2gxV2J2Tm1KN2szWTFaeU81TkdabXNUZWpsbUo3azNZa1p5TzVOMmJtc1RlanBtSmdzVGVqcG1KN2szWXJWWGFtc1RlanhtSjdrM1loWnlPNU4yYW1BeU81TjJabUFpTWdzVGVqRm1KN2szWTBaQ0k3azNZMVp5TzVOR1ptc1RlajltSjdrM1lxWkNJN2szWW5aQ0kzSXpPaDFXYnZObUp4QXlPNU5XYW1zVGVqUm5KN2szWWhaeU81Tkdhelp5TzVOMmExbG1KN2szWXRaeU81Tm1XbXNUYXRWMmNtQVRNNzBXZHVaeU9wMVdaelpDT3pzVGIxNW1KN0FYYmhaeU81TldZbXNUZWpKbko3azNZbGxtSjdrM1l1WnlPNU4yWm1zVGVqRm1KN2szWVdaQ0k3azNZMFp5TzVOMmNtc1RlalZXYW1zVGVqUmxK', 1);
INSERT INTO "public"."reactiv_menu" ("id", "name", "position", "units_id", "comment", "group_id") VALUES (21, 'Реагент 16А. Тест з динітробензолом', 0, 1, 'N2tXYmxObkp3RXpPdFZuYm1zVGF0VjJjbWd6TTcwV2R1WnlPdzFXWW1zamJ2eDJialp5TzVOV2Rtc1RlalJuSjdrM1l6WnlPNU5XWnBaeU81TkdkbUF5TzVOV1k1WnlPNU5tYm1zVGVqNW1KN2szWWhaeU81Tm1ibXNUZWo5bUo3azNZclp5TzVOV2Ftc1RlalpsSjdrV2JsTm5Kd0V6T3RWbmJtc1RhdFYyY21nek03MFdkdVp5T3cxV1ltc1RhdFYyY21BVE03MFdkdVp5T3AxV1p6WkNPenNUYjE1bUo3QVhiaFp5T2s5V2F5VkdjbXNUZWpGV2Vtc1RlanhtSjdrM1l2WnlPNU4yYW1zVGVqdFdkcFp5TzVOR2Jtc1RlamRtSjdrM1l1WnlPNU5XWnBaeU81TkdibXNUZWpsbUo3azNZMFp5TzVOV1pwWnlPNU4yYTFsbUo3azNZc1p5TzVOMmJtc1RlakJuSmdzVGVqeG1KN2szWXRaQ0l3QVRNZ3NUZWpabkpnc1RlalZuSjdrM1lzWnlPNU4yYm1zVGVqcG5KN2szWXVaeU81TldacFp5TzVObVltc1RlajltSjdrM1l5WnlPNU5HZG1zVGVqdFdkcFp5TzVObWJtc1RlamxtSjdrM1lrWkNJMEF5T2gxV2J2Tm1KeEF5TzVOMlptQVNNZ3NUZWpsbUo3azNZMFp5TzVOV2Ftc1RlajVtSjdrM1lwWnlPNU5HYWpaeU81Tm1lbXNUZWo5bUo3azNZU1pDSUVaVE03a1dibE5uSndFek90Vm5ibXNUYXRWMmNtZ3pNNzBXZHVaeU93MVdZbXNUZWpGV2Vtc1RlanhtSjdrM1l2WnlPNU4yYW1zVGVqdFdkcFp5TzVOR2Jtc1RlamRtSjdrM1l1WnlPNU5XWnBaeU81TkdibXNUZWpsbUo3azNZMFp5TzVOV1pwWnlPNU4yYTFsbUo3azNZc1p5TzVOMmJtc1RlakJuSmdzVGVqeG1KN2szWXRaQ0l3QVRNZ3NUZWpabkpnc1RlalZuSjdrM1lzWnlPNU4yYm1zVGVqcG5KN2szWXVaeU81TldacFp5TzVObVltc1RlajltSjdrM1l5WnlPNU5HZG1zVGVqdFdkcFp5TzVObWJtc1RlamxtSjdrM1lrWkNJenNUWXQxMmJqWlNNZ3NUZWpkbUpnRURJN2szWXBaeU81TkdkbXNUZWpsbUo3azNZdVp5TzVOV2Ftc1RlamgyWW1zVGVqcG5KN2szWXZaeU81Tm1VbUF5TzVOMlVtWVRNZ3NUZWpSbko3azNZdVp5TzVOV1pwWnlPNU4yWm1zVGVqRm1KN2szWWxsbUo3azNZU1p5T3AxV1p6WkNNeHNUYjE1bUo3a1dibE5uSjRNek90Vm5ibXNEY3RGbUo3UTJicEpYWndaeU81TldhbXNUZWpSbUo3azNZdlp5TzVObWRtQXlPNU5HYm1zVGVqMW1KZ0FETXhBeU81Tm1kbUF5TzVOV2Rtc1RlalJtSjdrM1lwWnlPNU4yY21zVGVqdG1KN2szWXZaeU81Tm1jbXNUZWpSbUo3azNZclZYYW1zVGVqZG1KZ3NUZWpwbUo3azNZcFp5TzVOR2Rtc1RlanRXZHBaeU81TkdibUFDTXhBeU81TldhbXNUZWpSbko3azNZcFp5TzVObWJtc1RlamxtSjdrM1lvTm1KN2szWTZaeU81TjJibXNUZWpKbEpnc0RadmxtY2xCbko3azNZV1pDSTJFREk3azNZMFp5TzVObWJtc1RlalZXYW1zVGVqZG1KN2szWWhaeU81TldacFp5TzVObVVtc1RhdFYyY21BVE03MFdkdVp5T3AxV1p6WkNPenNUYjE1bUo3QVhiaFp5T2s5V2F5VkdjbXNUZWpGV2Vtc1RlanhtSjdrM1l2WnlPNU4yYW1zVGVqdFdkcFp5TzVOR2Jtc1RlamRtSjdrM1l1WnlPNU5XWnBaeU81TkdibXNUZWpsbUo3azNZMFp5TzVOV1pwWnlPNU4yYTFsbUo3azNZc1p5TzVOMmJtc1RlakJuSmdzVGVqeG1KN2szWXRaQ0l3QVRNZ3NUZWpabkpnc1RlalZuSjdrM1lzWnlPNU4yYm1zVGVqcG5KN2szWXVaeU81TldacFp5TzVObVltc1RlajltSjdrM1l5WnlPNU5HZG1zVGVqdFdkcFp5TzVObWJtc1RlamxtSjdrM1lrWkNJeXNUWXQxMmJqWlNNZ3NUZWpkbUpnRURJN1EyYnBKWFp3WnlPNU5XUW1ZVE1nc1RlalJuSjdrM1l1WnlPNU5XWnBaeU81TjJabXNUZWpGbUo3azNZbGxtSjdrM1lTWnlPcDFXWnpaQ014c1RiMTVtSjdrV2JsTm5KNE16T3RWbmJtc0RjdEZtSjdrM1kxWnlPNU5tYm1zVGVqdFdkcFp5TzVOR2Jtc1RlajltSjdrM1l0WnlPNU5XWnBaeU81TkdjbUF5TzVOR2RtOTJjbXNUZWpSbko3azNZelp5TzVOMmExbG1KN2szWXVaeU81TkdkbXNUZWpWbko3azNZelp5TzVOV2Ftc1RlakpuSjdrM1l3WkNJN2szWWhaeU81Tm1ibUF5TzVOV2Jtc1RlajltSjdrM1lzWnlPNU4yYm1zVGVqcG5KN2szWXVaeU81TldacFp5TzVObVltc1RlajltSjdrM1l5WnlPNU5HZG1zVGVqdFdkcFp5TzVObWJtc1RlamxtSjdrM1lrWkNJN2szWTZaQ0k3azNZMFp5TzVOMmNtc1RlalZXYW1zVGVqUmxK', 1);
INSERT INTO "public"."reactiv_menu" ("id", "name", "position", "units_id", "comment", "group_id") VALUES (23, 'Реагент 16с. Тест з динітробензолом', 0, 1, 'PXNqYnZ4MmJqWnlPNU5XZG1zVGVqUm5KN2szWXpaeU81TldacFp5TzVOR2RtQXlPNU5XWTVaeU81Tm1ibXNUZWo1bUo3azNZaFp5TzVObWJtc1RlajltSjdrM1lyWnlPNU5XYW1zVGVqWmxKN2tXYmxObkp3RXpPdFZuYm1zVGF0VjJjbWd6TTcwV2R1WnlPdzFXWW1zVGF0VjJjbUFUTTcwV2R1WnlPcDFXWnpaQ096c1RiMTVtSjdBWGJoWnlPazlXYXlWR2Ntc1RlakZXZW1zVGVqeG1KN2szWXZaeU81TjJhbXNUZWp0V2RwWnlPNU5HYm1zVGVqZG1KN2szWXVaeU81TldacFp5TzVOR2Jtc1RlamxtSjdrM1kwWnlPNU5XWnBaeU81TjJhMWxtSjdrM1lzWnlPNU4yYm1zVGVqQm5KZ3NUZWp4bUo3azNZdFpDSXdBVE1nc1RlalpuSmdzVGVqVm5KN2szWXNaeU81TjJibXNUZWpwbko3azNZdVp5TzVOV1pwWnlPNU5tWW1zVGVqOW1KN2szWXlaeU81TkdkbXNUZWp0V2RwWnlPNU5tYm1zVGVqbG1KN2szWWtaQ0kwQXlPaDFXYnZObUp4QXlPNU4yWm1BU01nc1RlamxtSjdrM1kwWnlPNU5XYW1zVGVqNW1KN2szWXBaeU81Tkdhalp5TzVObWVtc1RlajltSjdrM1lTWkNJRVpUTTdrV2JsTm5Kd0V6T3RWbmJtc1RhdFYyY21nek03MFdkdVp5T3cxV1ltc1RlakZXZW1zVGVqeG1KN2szWXZaeU81TjJhbXNUZWp0V2RwWnlPNU5HYm1zVGVqZG1KN2szWXVaeU81TldacFp5TzVOR2Jtc1RlamxtSjdrM1kwWnlPNU5XWnBaeU81TjJhMWxtSjdrM1lzWnlPNU4yYm1zVGVqQm5KZ3NUZWp4bUo3azNZdFpDSXdBVE1nc1RlalpuSmdzVGVqVm5KN2szWXNaeU81TjJibXNUZWpwbko3azNZdVp5TzVOV1pwWnlPNU5tWW1zVGVqOW1KN2szWXlaeU81TkdkbXNUZWp0V2RwWnlPNU5tYm1zVGVqbG1KN2szWWtaQ0l6c1RZdDEyYmpaU01nc1RlamRtSmdFREk3azNZcFp5TzVOR2Rtc1RlamxtSjdrM1l1WnlPNU5XYW1zVGVqaDJZbXNUZWpwbko3azNZdlp5TzVObVVtQXlPNU4yVW1ZVE1nc1RlalJuSjdrM1l1WnlPNU5XWnBaeU81TjJabXNUZWpGbUo3azNZbGxtSjdrM1lTWnlPcDFXWnpaQ014c1RiMTVtSjdrV2JsTm5KNE16T3RWbmJtc0RjdEZtSjdRMmJwSlhad1p5TzVOV2Ftc1RlalJtSjdrM1l2WnlPNU5tZG1BeU81TkdibXNUZWoxbUpnQURNeEF5TzVObWRtQXlPNU5XZG1zVGVqUm1KN2szWXBaeU81TjJjbXNUZWp0bUo3azNZdlp5TzVObWNtc1RlalJtSjdrM1lyVlhhbXNUZWpkbUpnc1RlanBtSjdrM1lwWnlPNU5HZG1zVGVqdFdkcFp5TzVOR2JtQUNNeEF5TzVOV2Ftc1RlalJuSjdrM1lwWnlPNU5tYm1zVGVqbG1KN2szWW9ObUo3azNZNlp5TzVOMmJtc1RlakpsSmdzRFp2bG1jbEJuSjdrM1lXWkNJMkVESTdrM1kwWnlPNU5tYm1zVGVqVldhbXNUZWpkbUo3azNZaFp5TzVOV1pwWnlPNU5tVW1zVGF0VjJjbUFUTTcwV2R1WnlPcDFXWnpaQ096c1RiMTVtSjdBWGJoWnlPazlXYXlWR2Ntc1RlakZXZW1zVGVqeG1KN2szWXZaeU81TjJhbXNUZWp0V2RwWnlPNU5HYm1zVGVqZG1KN2szWXVaeU81TldacFp5TzVOR2Jtc1RlamxtSjdrM1kwWnlPNU5XWnBaeU81TjJhMWxtSjdrM1lzWnlPNU4yYm1zVGVqQm5KZ3NUZWp4bUo3azNZdFpDSXdBVE1nc1RlalpuSmdzVGVqVm5KN2szWXNaeU81TjJibXNUZWpwbko3azNZdVp5TzVOV1pwWnlPNU5tWW1zVGVqOW1KN2szWXlaeU81TkdkbXNUZWp0V2RwWnlPNU5tYm1zVGVqbG1KN2szWWtaQ0l5c1RZdDEyYmpaU01nc1RlamRtSmdFREk3UTJicEpYWndaeU81TldRbVlUTWdzVGVqUm5KN2szWXVaeU81TldacFp5TzVOMlptc1RlakZtSjdrM1lsbG1KN2szWVNaeU9wMVdaelpDTXhzVGIxNW1KN2tXYmxObko0TXpPdFZuYm1zRGN0Rm1KN2szWTFaeU81Tm1ibXNUZWp0V2RwWnlPNU5HYm1zVGVqOW1KN2szWXRaeU81TldacFp5TzVOR2NtQXlPNU5HZG05MmNtc1RlalJuSjdrM1l6WnlPNU4yYTFsbUo3azNZdVp5TzVOR2Rtc1RlalZuSjdrM1l6WnlPNU5XYW1zVGVqSm5KN2szWXdaQ0k3azNZaFp5TzVObWJtQXlPNU5XYm1zVGVqOW1KN2szWXNaeU81TjJibXNUZWpwbko3azNZdVp5TzVOV1pwWnlPNU5tWW1zVGVqOW1KN2szWXlaeU81TkdkbXNUZWp0V2RwWnlPNU5tYm1zVGVqbG1KN2szWWtaQ0k3azNZNlpDSTdrM1kwWnlPNU4yY21zVGVqVldhbXNUZWpSbEo%3D', 1);
INSERT INTO "public"."reactiv_menu" ("id", "name", "position", "units_id", "comment", "group_id") VALUES (11, 'Реагент 6А. Тест Дюкенуа-Левіна', 0, 1, 'PT13T2s5V2F5VkdjbXNUZWpabko3azNZclZYYW1zVGVqUm1KN2szWXBsbko3azNZdlp5TzVObWJtc1RlanRXZHBaeU81Tm1ZbXNUZWpGbUo3azNZdVp5TzVObWJtc1RlakZtSjdrM1lyWkNJN2szWTBaMmJ6WnlPNU5HZG1zVGVqTm5KN2szWXJWWGFtc1RlajVtSjdrM1kwWnlPNU5XZG1zVGVqTm5KN2szWXBaeU81Tm1jbXNUZWpCbkpnc1RlalZuSjdrM1kyWnlPNU5XYW1zVGVqeG1KN2szWW9wbko3azNZdlp5TzVOV2JtQXlPNU5XWW1zVGVqNW1KZ3NUZWp0V2RxWnlPNU5XZG1zVGVqcG5KN2szWWhaeU81TjJhbXNUZWpabkpnc1RlalZuSjdrM1l5WnlPNU5XWW1zVGVqaDJjbUF5TzVOMmJtc1RlamRtSjdrM1l2WnlPNU5tYm1zVGVqMW1KN2szWXlaeU81TjJibXNUZWpabUo3azNZdlp5TzVObWNtc1RlajltSjdrM1lzWnlPNU5HYXJaQ0k3azNZdlp5TzVOMlptc1RlajltSjdrM1kwWjJielp5TzVObWJtc1RlamhtZW1zVGVqbG1KN2szWXVaQ0k3azNZaGxuSjdrM1l1WnlPNU5tYm1zVGVqVldhbXNUZWp4bUo3azNZMlp5TzVObWNtc1RlakZtSjdrM1lpWnlPNU5XWW1zVGVqcG5KZ3NUZWpWV2Ftc1RlalpuSjdrM1l2WnlPNU5HZG1zVGVqVldhbXNUZWp4bUo3azNZdlp5TzVOMmExbG1KN2szWUdaQ0k3UTJicEpYWndaeU81TkdkbXNUZWpGbUo3azNZMFp5TzVOR2RtOTJjbXNUZWp4bUo3azNZMVp5TzVObWVtc1RlalZXYW1zVGVqSmxKN2tXYmxObkp3RXpPdFZuYm1zVGF0VjJjbWd6TTcwV2R1WnlPdzFXWW1zVGF0VjJjbUFUTTcwV2R1WnlPcDFXWnpaQ096c1RiMTVtSjdBWGJoWnlPMDlXZHhaeU81TldRbVlESTdrM1kwWnlPNU5tYm1zVGVqVldhbXNUZWpkbUo3azNZaFp5TzVOV1pwWnlPNU5tY21BeU81TldacFp5TzVOR2F6WnlPNU5XYW1zVGVqeG1KZ3NUZWpGV2Vtc1Rlak5uSjdrM1kwWjJielp5TzVOR2Rtc1RlanRXZHFaeU81TldZbXNUZWpSbUo3azNZaGxuSjdrM1lzWnlPNU4yWm1zVGVqcG5KN2szWXZaeU81Tm1VbXNEZHZWWGNtc1RhdFYyY21BVE03MFdkdVp5T3AxV1p6WkNPenNUYjE1bUo3QVhiaFp5T3AxV1p6WkNNeHNUYjE1bUo3a1dibE5uSjRNek90Vm5ibXNEY3RGbUo3UTJicEpYWndaeU81TldkbXNUZWp0bUo3azNZeVp5TzVOMmExbG1KN2szWWlaeU81TjJibXNUZWpKbko3azNZd1pDSTdrM1lwWnlPNU5HZG1zVGVqbG1KN2szWXpaeU81TldkbXNUZWpKbko3azNZMFp5TzVObWVtQXlPNU4yYm1zVGVqNW1KN2szWW9wbko3azNZbGxtSjdrM1l5WnlPNU5XWnBaeU81Tm1ZbXNUZWo5bUpnc1RlakZtSjdrM1kwWkNJN2szWXpaaU5nc1RlalZuSjdrM1kwWnlPNU5tYm1zVGVqVldhbXNUZWpkbUo3azNZaFp5TzVOV1pwWnlPNU5tY21BeU81TkdibXNUZWoxbUpnSURJN2szWXBaeU81TkdkbXNUZWpGbUo3azNZa1p5TzVOMmJtc1RlalJtSmdzVFl0MTJialp5TzVOV1k1WnlPNU5tYm1zVGVqNW1KN2szWWxsbUo3azNZc1p5TzVObWRtc1RlakpuSjdrM1loWnlPNU5tWW1zVGVqRm1KN2szWTZaQ0k3azNZaGxuSjdrM1l6WnlPNU5HZG05MmNtc1RlalJuSjdrM1lwWnlPNU5tY21zVGVqOW1KN2szWTJaeU81TkdkbXNUZWpWbkpnc1RlamxtSjdrM1l1WnlPNU5XYW1zVGVqeG1KN2szWXBaeU81Tm1kbXNUZWpoMmFtQXlNdElESTdrM1loWnlPNU5tZW1BeU81TjJibXNUZWpoMllvTm5KN2szWXJaeU81TldRWlpDSTdRMmJwSlhad1pDTjdrV2JsTm5Kd0V6T3RWbmJtc1RhdFYyY21nek03MFdkdVp5T3cxV1ltc0RadmxtY2xCbko3azNZdVp5TzVOV2Ftc1RlanhtSjdrM1lwWnlPNU5tZG1zVGVqaDJhbUF5TzVOR2FyWnlPNU4yYm1zVGVqdG1KN2szWTBaMmJ6WnlPNU5HYm1zVGVqdFdkcFp5TzVOMmFtc1RlalZXYW1zVGVqUm1KZ3NUZWoxbUo3azNZdlp5TzVOMlptc1RlakZXZW1zVGVqUm5KN2szWXZaeU81Tm1jbXNUZWpCbkpnc1RlamxtSjdrM1kwWnlPNU5XYW1zVGVqTm5KN2szWTFaeU81Tm1jbXNUZWpSbko3azNZNlpDSTdrM1loWnlPNU5HZG1BeU81Tm1WbVlESTdrM1kxWnlPNU5HZG1zVGVqNW1KN2szWWxsbUo3azNZblp5TzVOV1ltc1RlalZXYW1zVGVqSm5KZ3NUZWp4bUo3azNZdFpDSXlBeU81TldhbXNUZWpSbko3azNZaFp5TzVOR1ptc1RlajltSjdrM1lFWkNJN1EyYnBKWFp3WnlNN2tXYmxObkp3RXpPdFZuYm1zVGF0VjJjbWd6TTcwV2R1WnlPdzFXWW1zRFp2bG1jbEJuSjdrM1lwWnlPNU5tYm1zVGVqbG1KN2szWXNaeU81TldhbXNUZWpabko3azNZb3RtSmdFREk3azNZdFp5TzVOMmJtc1RlamRtSjdrM1lobG5KN2szWTBaeU81TjJibXNUZWpKbko3azNZd1pDSTdrM1kxWnlPNU4yYW1zVGVqSm5KN2szWXJWWGFtc1RlakptSjdrM1l2WnlPNU5tY21zVGVqQm5KZ3NUZWpsbUo3azNZMFp5TzVOV2Ftc1Rlak5uSjdrM1kxWnlPNU5tY21zVGVqUm5KN2szWTZaQ0k3azNZaFp5TzVOR2RtQXlPNU5XUW1ZREk3azNZMVp5TzVOR2Rtc1RlajVtSjdrM1lsbG1KN2szWW5aeU81TldZbXNUZWpWV2Ftc1RlakpuSmdzVGVqeG1KN2szWXRaQ0l5QXlPNU5XYW1zVGVqUm5KN2szWWhaeU81TkdabXNUZWo5bUo3azNZRVpDSTdRMmJwSlhad1ppTTdrV2JsTm5Kd0V6T3RWbmJtc1RhdFYyY21nek03MFdkdVp5T3cxV1ltc0RadmxtY2xCbko3azNZcFp5TzVOMmFtc1RlakpuSjdrM1lyVlhhbXNUZWpKbUo3azNZdlp5TzVObWNtc1RlakJuSmdzVGVqOW1KN2szWWtaQ0k3azNZcFp5TzVOR2Rtc1RlamxtSjdrM1kwWnlPNU4yY21zVGVqdFdkcFp5TzVOV2Jtc1RlajltSjdrM1l3WkNJN2szWXBaeU81Tm1ibXNUZWpsbUo3azNZMlp5TzVOMmJtc1RlamgyWW1zVGVqVldhbXNUZWpKbkpnc1RlalJuWnZObko3azNZMFp5TzVOMmNtc1RlanRXZHBaeU81TjJhbXNUZWpSblp2Tm5KN2szWXNaeU81TjJhMWxtSjdrM1lyWkNJN2szWTFaeU81TjJhbXNUZWpsbUo3azNZc1p5TzVOV1pwWnlPNU5tZG1zVGVqVldhbXNUZWo1a0pnc0RadmxtY2xCbkp4c1RhdFYyY21BVE03MFdkdVp5T3AxV1p6WkNPenNUYjE1bUo3QVhiaFp5T3U5R2J2Tm1KN2szWTFaeU81TkdkbXNUZWpObko3azNZbGxtSjdrM1kwWkNJN2szWWhsbko3azNZdVp5TzVObWJtc1RlakZtSjdrM1l1WnlPNU4yYm1zVGVqdG1KN2szWXBaeU81Tm1WbXNUYXRWMmNtQVRNNzBXZHVaeU9wMVdaelpDT3pzVGIxNW1KN0FYYmhaeU9wMVdaelpDTXhzVGIxNW1KN2tXYmxObko0TXpPdFZuYm1zRGN0Rm1KN1EyYnBKWFp3WnlPNU5XYm1zVGVqSm5KN2szWXZaeU81Tm1abXNUZWo5bUo3azNZeVp5TzVOMmJtc1RlanhtSjdrM1lJdGtKZ3NUZWpObkoyQXlPNU5HZG1zVGVqNW1KN2szWWxsbUo3azNZblp5TzVOV1ltc1RlalZXYW1zVGVqSmxKN2tXYmxObkp3RXpPdFZuYm1zVGF0VjJjbWd6TTcwV2R1WnlPdzFXWW1zVGVqRm1KN2szWTBaeU81TjJibXNUZWp4bUo3azNZelp5TzVOV2Ftc1RlanRtSmdzVGVqRm1KN2szWXVaeU81TkdabXNUZWpsbUo3azNZeVp5TzVOMmJtc1RlanhtSjdrM1lvdG1KZ3NUZWpGbUo3azNZdVp5TzVOV1ltc1RlalpuSjdrM1l2WnlPNU5tY21zVGVqUm5KN2szWXVaeU81TldacFp5TzVOMmMwWnlPNU5tYm1zVGVqOW1KN2szWXJaQ0k3azNZV1ppTmdzVGVqUm5KN2szWXVaeU81TldacFp5TzVOMlptc1RlakZtSjdrM1lsbG1KN2szWVNaeU9wMVdaelpDTXhzVGIxNW1KN2tXYmxObko0TXpPdFZuYm1zRGN0Rm1KN2tXYmxObkp3RXpPdFZuYm1zVGF0VjJjbWd6TTcwV2R1WnlPdzFXWW1zRFp2bG1jbEJuSjdrM1kxWnlPNU5HWm1zVGVqdFdkcFp5TzVOMlptc1RlalZXYW1zVGVqUm1KN2szWTBaMmJ6WnlPNU5HYm1zVGVqRm1KN2szWTBaeU81TldacFp5TzVOMmMwWnlPNU5XWW1BeU81TkdibXNUZWoxbUpnVXpPaDFXYnZObUp5QXlPNU5XYW1zVGVqUm5KN2szWWhaeU81TkdabXNUZWo5bUo3azNZa1pDSTdrM1l0WnlPNU4yYTFsbUo3azNZMFp5TzVOMmJtc1RlakJuSmdzVFl0MTJialp5TzVOV2Rtc1RlanhtSjdrM1l2WnlPNU5tYm1zVGVqRm1KN2szWTBaeU81TldacFpDSTdRbmJqSlhad1pTTjVBeU81TkdibXNUZWoxbUpnQURNeEF5TzVObWRtQXlPNU5XZG1zVGVqNW1KN2szWXJWWGFtc1RlanhtSjdrM1lyVlhhbXNUZWo1bUo3azNZaFp5TzVObWRtQXlPNU4yWm1BaU1nc1RlamxtSjdrM1kwWnlPNU5XYW1zVGVqNW1KN2szWXBaeU81Tkdhalp5TzVObWVtc1RlajltSjdrM1lTWkNJNzQyYnM5Mlltc1RlakZrSjJBeU81TkdkbXNUZWo1bUo3azNZbGxtSjdrM1luWnlPNU5XWW1zVGVqVldhbXNUZWpKbEo%3D', 1);
INSERT INTO "public"."reactiv_menu" ("id", "name", "position", "units_id", "comment", "group_id") VALUES (26, 'Реагент 17В. Ділл- Копаній тест.', 0, 1, 'PT13T3AxV1p6WkNNeHNUYjE1bUo3a1dibE5uSjRNek90Vm5ibXNEY3RGbUo3UTJicEpYWndaeU81Tm1kbXNUZWp0V2RwWnlPNU5HZG1zVGVqRm1KN2szWXlaeU81TldkbXNUZWpSbko3azNZclZYYW1zVGVqSm1KN2szWXlaeU81TldZbXNUZWpKbUpnc1RlalJuWnZObko3azNZMFp5TzVOMmNtc1RlanRXZHBaeU81Tm1ibXNUZWpSbko3azNZMVp5TzVOMmNtc1RlamxtSjdrM1l5WnlPNU5HY21BeU81TldkbXNUZWpabko3azNZcFp5TzVOR2Jtc1RlamhtZW1zVGVqOW1KN2szWXRaQ0k3azNZaFp5TzVObWJtQXlPNU4yYTFwbUo3azNZMVp5TzVObWVtc1RlakZtSjdrM1lyWnlPNU5tZG1BeU81Tm1jbXNUZWp0V2RwWnlPNU5HYm1zVGVqOW1KN2szWXJaQ0k3azNZcVp5TzVOV2Ftc1RlalpuSjdrM1l2WnlPNU5tY21zVGVqVm5KN2szWXdaeU81Tm1jbXNUZWpWbko3azNZd1pTTDdrM1l2WnlPNU5tYm1zVGVqOW1KN2szWTJaeU81Tm1jbXNUZWpWV2Ftc1RlamgwUW1zVGF0VjJjbUFUTTcwV2R1WnlPcDFXWnpaQ096c1RiMTVtSjdBWGJoWnlPazlXYXlWR2Ntc1RlalpsSjNFRElnc1RlalZuSjdrM1kwWnlPNU5tYm1zVGVqVldhbXNUZWpkbUo3azNZaFp5TzVOV1pwWnlPNU5tY21BeU81TjJhMWxtSjdrM1lzWnlPNU5HY21zVGVqRm1KN2szWXlaeU81TjJhbUF5TWdzVFl0MTJialp5TzVOV1FtY1RNZ0F5TzVOV2Rtc1RlalJuSjdrM1l1WnlPNU5XWnBaeU81TjJabXNUZWpGbUo3azNZbGxtSjdrM1l5WkNJN2szWXJWWGFtc1RlanhtSjdrM1l3WnlPNU5XWW1zVGVqSm5KN2szWXJaQ0l6QUNJZ3NUZWpsbUo3azNZMFp5TzVOV1ltc1RlalJtSjdrM1l2WnlPNU5HWm1BeU81TldZbXNUZWp0bUo3azNZNlp5TzVOV1ltc1RlakpuSjdrM1k2WkNJN2szWXZaeU81TjJabXNUZWo5bUo3azNZdVp5TzVOV1ltc1RlalpuSjdrM1kxWnlPNU5HYTZaeU81TkdabXNUZWp0V2RwWnlPNU5HYm1zVGVqTm5KN2szWXZaeU81TkdabUF5TzVOMmJtc1RlalJrSjdrV2JsTm5Kd0V6T3RWbmJtc1RhdFYyY21nek03MFdkdVp5T3cxV1ltc2pidngyYmpaeU81TldkbXNUZWpSbko3azNZelp5TzVOV1pwWnlPNU5HZG1BeU81TldZNVp5TzVObWJtc1RlajVtSjdrM1loWnlPNU5tYm1zVGVqOW1KN2szWXJaeU81TldhbXNUZWpabEo3a1dibE5uSndFek90Vm5ibXNUYXRWMmNtZ3pNNzBXZHVaeU93MVdZbXNUYXRWMmNtQVRNNzBXZHVaeU9wMVdaelpDT3pzVGIxNW1KN0FYYmhaeU9rOVdheVZHY21zVGVqVm5KN2szWXNaeU81TjJibXNUZWo1bUo3azNZaFp5TzVOR2Rtc1RlalZXYW1zVGVqMW1KZ3NEWnZsbWNsQm5KN2szWXpaeU81Tm1ZbXNUZWpGbUpnc1RlanhtSjdrM1l0WlNONUF5TzVObWVtQXlPNU5XZG1zVGVqNW1KN2szWXJWWGFtc1RlajFtSjdrM1loWnlPNU5HYm1zVGVqdFdkcFp5TzVOR2Ntc1RlajltSjdrM1l5WnlPNU5HY21zVGVqOW1KN2szWTZaeU81TjJhMWxtSmdzVGVqeG1KN2szWXRaU05nc1RlamxtSjdrM1kwWnlPNU5XWW1zVGVqaDJjbXNUZWp0V2RwWnlPNU5XYm1zVGVqcGxKZ3NEWnZsbWNsQm5KN2szWVdaeU54QXlPNU5HZG1zVGVqNW1KN2szWWxsbUo3azNZblp5TzVOV1ltc1RlalZXYW1zVGVqSmxKN2tXYmxObkp3RXpPdFZuYm1zVGF0VjJjbWd6TTcwV2R1WnlPdzFXWW1zRFp2bG1jbEJuSjdrM1lwWnlPNU5HZG1zVGVqOW1KN2szWXNaeU81TjJjbXNUZWpsbUo3azNZclpDSTdrM1lwbG5KN2szWXZaeU81Tm1kbXNUZWo5bUo3azNZMFp5TzVOMmMwWnlPNU4yYm1BeU81TldhNVp5TzVOMmJtc1RlajVtSjdrM1lobG5KN2szWWtaeU81TjJibXNUZWpSblp2Tm5KN2szWXNaQ0k3azNZc1p5TzVOV2JtSXpPaDFXYnZObUp3QXlPNU5XYW1zVGVqUm5KN2szWWhaeU81TkdabXNUZWo5bUo3azNZa1pDSTdFV2J0OTJZbXNUZWpWbko3azNZc1p5TzVOMmJtc1RlajVtSjdrM1loWnlPNU5HZG1zVGVqVldhbXNUZWoxbUpnc0RadmxtY2xCbko3azNZelp5TzVObVltc1RlakZtSmdzVGVqeG1KN2szWXRaQ013RURJN2szWTJaQ0k3SVhZd0puSjdrM1kxWnlPNU5HZG1zVGVqRm1KN2szWXlaeU81TkdabXNUZWp0V2RwWnlPNU4yWm1zVGVqRm1KN2szWXlaeU81TkdkbXNUZWpWV2Ftc1RlalJuSjdJWFl3eG1KZ3NUZWpWbko3azNZMFp5TzVOR2RtOTJjbXNUZWp4bUo3azNZaFp5TzVObVltc1RlajltSjdrM1lyWkNJN2szWTFaeU81TkdkbXNUZWpGbUo3azNZMFp5TzVOV1pwWnlPNU4yYzBaeU81TldZbUF5TzVOMlptQVNNN0VXYnQ5MlltQURJN2szWXBaeU81TkdkbXNUZWpsbUo3azNZdVp5TzVOV2Ftc1RlamgyWW1zVGVqcG5KN2szWXZaeU81Tm1VbUF5T2s5V2F5VkdjbXNUZWpGa0ozRURJN2szWTBaeU81Tm1ibXNUZWpWV2Ftc1RlamRtSjdrM1loWnlPNU5XWnBaeU81Tm1VbXNUYXRWMmNtQVRNNzBXZHVaeU9wMVdaelpDT3pzVGIxNW1KN0FYYmhaeU9rOVdheVZHY21zVGVqUm5KN2szWXpaeU81TldacFp5TzVOR2RtQXlPNU5tYW1zVGVqdFdkcFp5TzVObWJtc1RlakZtSjdrM1l3WnlPNU4yYm1zVGVqdGtKZzB5TzVOR2Jtc1RlanhtSjdrM1lyVlhhbXNUZWpSa0o%3D', 1);
INSERT INTO "public"."reactiv_menu" ("id", "name", "position", "units_id", "comment", "group_id") VALUES (27, 'Реагент 19с. Тест Віталі-Моріна.', 0, 1, 'PXNUYXRWMmNtQVRNNzBXZHVaeU9wMVdaelpDT3pzVGIxNW1KN0FYYmhaeU81Tkdhclp5TzVOV2Ftc1RlajVtSjdrM1lrWnlPNU4yYTFsbUo3azNZb3RtSjdrM1l2WnlPNU5HY21BeU81Tkdhclp5TzVOV2Ftc1RlalpuSjdrM1l2WnlPNU5tYm1zVGVqdFdkcFp5TzVOR2Ntc1RlalZXYW1zVGVqcG5KN2szWWhaeU81TjJhMWxtSjdrM1lrWnlPNU4yYm1zVGVqcG5KN2szWXVaeU81TldacFp5TzVObVltQXlPNU5HYXJaeU81TldhbXNUZWpoMmNtc1RlajVtSjdrM1lyVlhhbUF5TzVOV1ltc1RlalJuSmdzVGVqVm5KN2szWXRaeU81TldZbXNUZWpCbko3azNZbGxtSjdrM1k2WnlPNU5XWW1zVGVqdFdkcFp5TzVOR1ptQXlPNU5HZG05MmNtc1RlalJuSjdrM1l6WnlPNU4yYTFsbUo3azNZdVp5TzVOR2Rtc1RlalZuSjdrM1l6WnlPNU5XYW1zVGVqSm5KN2szWXdaQ0k3azNZMVp5TzVObWRtc1RlamxtSjdrM1lzWnlPNU5HYTZaeU81TjJibXNUZWoxbUpnc1RlakZtSjdrM1l1WkNJN2szWXJWbmFtc1RlalZuSjdrM1k2WnlPNU5XWW1zVGVqdG1KN2szWTJaQ0k3azNZeVp5TzVOMmExbG1KN2szWXNaeU81TjJibXNUZWp0bUpnc1RlanBtSjdrM1lwWnlPNU5HZG1zVGVqWm5KN2szWXZaeU81TkdTYVp5T3AxV1p6WkNNeHNUYjE1bUo3a1dibE5uSjRNek90Vm5ibXNEY3RGbUo3UTJicEpYWndaeU81TjJjbWtUTWdBeU81TldkbXNUZWpSbko3azNZdVp5TzVOV1pwWnlPNU4yWm1zVGVqRm1KN2szWWxsbUo3azNZeVpDSTdrM1lzWnlPNU5XYm1FREk3RVdidDkyWW1zVGVqWmxKNUVESWdzVGVqVm5KN2szWTBaeU81Tm1ibXNUZWpWV2Ftc1RlamRtSjdrM1loWnlPNU5XWnBaeU81Tm1jbUF5TzVOR2Jtc1RlajFtSjFBeU81TldhbXNUZWpSbko3azNZaFp5TzVOR1ptc1RlajltSjdrM1lrWkNJN2tXYmxObko3azNZMVp5TzVOMmFtc1RlamgyY21zVGVqbG1KN2szWXNaeU81TldZbXNUZWpwbkpnc1RlajltSjdrM1luWnlPNU4yYm1zVGVqaDJhbXNUZWpWbko3azNZelpDSTdrM1l2WnlPNU5HWm1BeU81TjJhMWxtSjdrM1l1WnlPNU5XWW1zVGVqSm1KZ3NUZWpwbUo3azNZclZYYW1zVGVqNW1KN2szWWhsbko3azNZa1p5TzVOMmJtc1RlalpuSmdzVGVqRm1KN2szWXVaQ0k3azNZcFp5TzVOR2Rtc1RlanRXZHBaeU81Tm1jbXNUZWpkbUo3azNZaFp5TzVObWJtQXlPNU4yYTFsbUpnc1RlakZrSjVFRElnc1RlalZuSjdrM1kwWnlPNU5tYm1zVGVqVldhbXNUZWpkbUo3azNZaFp5TzVOV1pwWnlPNU5tY21BeU81TkdibXNUZWoxbUoxc1RZdDEyYmpaQ01nc1RlamxtSjdrM1kwWnlPNU5XWW1zVGVqUm1KN2szWXZaeU81TkdabUF5TzVOMmExbG1KN2szWXpSbko3azNZeVp5TzVOMmExbG1KN2szWWlaeU81TjJibXNUZWpKbko3azNZd1pDSTdrM1kyWkNJN2szWWhaeU81TjJhbXNUZWpwbko3azNZaFp5TzVObWNtc1RlanBuSmdzVGVqOW1KN2szWW5aeU81TjJibXNUZWo1bUo3azNZaFp5TzVObWRtc1RlalZuSjdrM1lvcG5KN2szWWtaeU81TjJhMWxtSjdrM1lzWnlPNU4yY21zVGVqOW1KN2szWWtaQ0k3azNZdlp5TzVOR1Jtc1RhdFYyY21BVE03MFdkdVp5T3AxV1p6WkNPenNUYjE1bUo3QVhiaFp5T3U5R2J2Tm1KN2szWTFaeU81TkdkbXNUZWpObko3azNZbGxtSjdrM1kwWkNJN2szWWhsbko3azNZdVp5TzVObWJtc1RlakZtSjdrM1l1WnlPNU4yYm1zVGVqdG1KN2szWXBaeU81Tm1WbXNUYXRWMmNtQVRNNzBXZHVaeU9wMVdaelpDT3pzVGIxNW1KN0FYYmhaeU9rOVdheVZHY21zVGVqRm1KN2szWXNaeU81TjJibXNUZWo1bUo3azNZaFp5TzVOR2Rtc1RlalZXYW1BeU81TkdibXNUZWoxbUpnQURNeEF5TzVObWRtQXlPNU5XZG1zVGVqUm1KN2szWXBaeU81TjJjbXNUZWp0bUo3azNZdlp5TzVObWNtc1RlalJtSjdrM1lyVlhhbXNUZWpkbUpnc1RlanBtSjdrM1lyVlhhbXNUZWp4bUo3azNZaFp5TzVOMmFtQXlPNU4yWm1BaU4xc1RZdDEyYmpaQ01nc0RadmxtY2xCbko3azNZelpTT3hBeU81TkdkbXNUZWo1bUo3azNZbGxtSjdrM1luWnlPNU5XWW1zVGVqVldhbXNUZWpKbEo3a1dibE5uSndFek90Vm5ibXNUYXRWMmNtZ3pNNzBXZHVaeU93MVdZbXNEWnZsbWNsQm5KN2szWXVaeU81TjJibXNUZWpSbko3azNZbGxtSjdrM1l6Um5KN2szWUJaQ0k3UTJicEpYWndaeU81Tm1WbWtUTWdzVGVqUm5KN2szWXVaeU81TldacFp5TzVOMlptc1RlakZtSjdrM1lsbG1KN2szWVNaeU9wMVdaelpDTXhzVGIxNW1KN2tXYmxObko0TXpPdFZuYm1zRGN0Rm1KN1EyYnBKWFp3WnlPNU5XWW1zVGVqUm5KN2szWXZaeU81TkdibXNUZWpObko3azNZcFp5TzVOMmFtQXlPNU5XWW1zVGVqNW1KN2szWTBaeU81TjJibXNUZWpwbko3azNZaFpDSTdrM1loWnlPNU5tYm1zVGVqRm1KN2szWTJaeU81TjJibXNUZWpKbko3azNZMFp5TzVObWJtc1RlalZXYW1zVGVqTkhkbXNUZWo1bUo3azNZdlp5TzVOMlNtQXlPazlXYXlWR2Ntc1RlakZrSjVFREk3azNZMFp5TzVObWJtc1RlalZXYW1zVGVqZG1KN2szWWhaeU81TldacFp5TzVObVVtc1RhdFYyY21BVE03MFdkdVp5T3AxV1p6WkNPenNUYjE1bUo3QVhiaFp5T2s5V2F5VkdjbXNUZWpGbUo3azNZdVp5TzVOMmExbG1KN2szWXlaeU81TjJibXNUZWoxa0p0c1RlanRXZHBaeU81TkdibXNUZWpGbUo3azNZMFp5TzVOMmExbG1KN2szWVdaQ0k3azNZMFp5TzVOMmNtc1RlalZXYW1zVGVqUmxK', 1);
INSERT INTO "public"."reactiv_menu" ("id", "name", "position", "units_id", "comment", "group_id") VALUES (28, 'Реагент 20. Тест Ерліха', 0, 1, 'PT13T3AxV1p6WkNNeHNUYjE1bUo3a1dibE5uSjRNek90Vm5ibXNEY3RGbUo3UTJicEpYWndaeU95RkdjeVpDUlR4ME95Rkdjc1pDSTdrM1kxWnlPNU5HWm1zVGVqdFdkcFp5TzVOMlptc1RlakpuSjdrM1lsbG1KN2szWTZaeU81TjJhMWxtSjdrM1lzWkNJN2szWTBaMmJ6WnlPNU5HZG1zVGVqTm5KN2szWXJWWGFtc1RlajVtSjdrM1kwWnlPNU5XZG1zVGVqTm5KN2szWXBaeU81Tm1jbXNUZWpCbkpnc1RlalZuSjdrM1kyWnlPNU5XYW1zVGVqeG1KN2szWW9wbko3azNZdlp5TzVOV2JtQXlPNU5XWW1zVGVqNW1KZ3NUZWp0V2RxWnlPNU5XZG1zVGVqcG5KN2szWWhaeU81TjJhbXNUZWpabkpnc1RlajVtSjdrM1lwWnlPNU5HYm1zVGVqbG1KN2szWTJaeU81TkdhclpDSTdrM1loWnlPNU4yYW1zVGVqUm5adk5uSjdrM1lzWnlPNU4yYTFsbUo3azNZclp5TzVOV1pwWnlPNU5HWm1BeU81TldZbXNUZWpwbkpnc1RlakZXZW1zVGVqTm5KN2szWTBaMmJ6WnlPNU5HZG1zVGVqdFdkcVp5TzVOV1k1WnlPNU5HYm1zVGVqWm5KN2szWWhsbko3OFdkeE5uY21zVGVqcG5KZ3NUZWo5bUo3azNZb05HYXpaQ0k3RVdidDkyWW1zVGVqRldlbXNUZWo1bUo3azNZdVp5TzVOV1pwWnlPNU5HYm1zVGVqWm5KN2szWXlaeU81TldZbXNUZWpKbUo3azNZaFp5TzVObWVtQXlPNU5XWnBaeU81Tm1kbXNUZWo5bUo3azNZMFp5TzVOV1pwWnlPNU5HYm1zVGVqOW1KN2szWXJWWGFtc1RlalprSjdrV2JsTm5Kd0V6T3RWbmJtc1RhdFYyY21nek03MFdkdVp5T3cxV1ltc0RadmxtY2xCbkp3SURJN2szWTFaeU81TkdkbXNUZWo1bUo3azNZbGxtSjdrM1luWnlPNU5XWW1zVGVqVldhbXNUZWpKbkpnc1RlanRXZHBaeU81TkdibXNUZWpCbko3azNZaFp5TzVObWNtc1RlanRtSmdJREk3azNZcFp5TzVOR2Rtc1RlakZtSjdrM1lrWnlPNU4yYm1zVGVqUm1KZ3NUZWpGbUo3azNZclp5TzVObWVtc1RlakZtSjdrM1l5WnlPNU5tZW1BeU81TjJibXNUZWpkbUo3azNZdlp5TzVObWJtc1RlakZtSjdrM1kyWnlPNU5XZG1zVGVqaG1lbXNUZWpSbUo3azNZclZYYW1zVGVqeG1KN2szWXpaeU81TjJibXNUZWpSbUpnc1RlajltSjdrM1lFWkNJNzQyYnM5Mlltc1RlalZuSjdrM1kwWnlPNU4yY21zVGVqVldhbXNUZWpSbkpnc1RlakZXZW1zVGVqNW1KN2szWXVaeU81TldZbXNUZWo1bUo3azNZdlp5TzVOMmFtc1RlamxtSjdrM1lXWnlPcDFXWnpaQ014c1RiMTVtSjdrV2JsTm5KNE16T3RWbmJtc0RjdEZtSjdrV2JsTm5Kd0V6T3RWbmJtc1RhdFYyY21nek03MFdkdVp5T3cxV1ltc0RadmxtY2xCbko3azNZcFp5TzVOR2Rtc1RlajltSjdrM1lzWnlPNU4yY21zVGVqbG1KN2szWXJaQ0k3azNZcGxuSjdrM1l2WnlPNU5tYm1zVGVqSm5KN2szWXZaeU81Tm1abXNUZWpObko3azNZdlp5TzVObVptc1RlajltSjdrM1kwWnlPNU5tY21zVGVqOW1KZ3NUZWp4bUo3azNZdFpDSXdFREk3azNZcFp5TzVOR2Rtc1RlakZtSjdrM1lrWnlPNU4yYm1zVGVqUm1KZ3NUZWo5bUo3azNZdVp5TzVOR2E2WnlPNU5XWnBaeU81Tm1jbXNUZWpWV2Ftc1RlakptSjdrM1l2WkNJN2szWXRaeU81TjJhMWxtSjdrM1kwWnlPNU4yYm1zVGVqQm5KZ3NUWXQxMmJqWnlPNU5XZG1zVGVqeG1KN2szWXZaeU81Tm1ibXNUZWpGbUo3azNZMFp5TzVOV1pwWnlPNU5XYm1BeU81TkdibXNUZWoxbUpnQVRNZ3NUZWpabkpnc1RlalZuSjdrM1lrWnlPNU4yYTFsbUo3azNZblp5TzVOV1pwWnlPNU5HWm1zVGVqUm5adk5uSjdrM1lzWnlPNU5XWW1zVGVqcG5KN2szWXVaeU81TldacFp5TzVObVltc1RlajltSjdrM1l1WnlPNU4yYTFsbUo3azNZdFp5TzVOV1ltc1RlanhtSjdrM1lwWnlPNU5HZG1zVGVqVldhbXNUZWoxbUo3azNZcFp5TzVOR1ptMENOZ3NUZWpkbUpnRURJN2szWXBaeU81TkdkbXNUZWpsbUo3azNZdVp5TzVOV2Ftc1RlamgyWW1zVGVqcG5KN2szWXZaeU81Tm1VbUF5T2s5V2F5VkdjbUFqTWdzVGVqUm5KN2szWXVaeU81TldacFp5TzVOMlptc1RlakZtSjdrM1lsbG1KN2szWVNaeU9wMVdaelpDTXhzVGIxNW1KN2tXYmxObko0TXpPdFZuYm1zRGN0Rm1KZ3NUZWpGbUo3azNZb3RtSjdrM1lyVlhhbXNUZWp4bUo3azNZeVp5TzVOV1JKWkNJN2szWTBaeU81TjJjbXNUZWpWV2Ftc1RlalJsSg%3D%3D', 1);
INSERT INTO "public"."reactiv_menu" ("id", "name", "position", "units_id", "comment", "group_id") VALUES (25, 'Реагент 17А. Ділл- Копаній тест', 0, 1, 'PT13T3AxV1p6WkNNeHNUYjE1bUo3a1dibE5uSjRNek90Vm5ibXNEY3RGbUo3UTJicEpYWndaeU81Tm1kbXNUZWp0V2RwWnlPNU5HZG1zVGVqRm1KN2szWXlaeU81TldkbXNUZWpSbko3azNZclZYYW1zVGVqSm1KN2szWXlaeU81TldZbXNUZWpKbUpnc1RlalJuWnZObko3azNZMFp5TzVOMmNtc1RlanRXZHBaeU81Tm1ibXNUZWpSbko3azNZMVp5TzVOMmNtc1RlamxtSjdrM1l5WnlPNU5HY21BeU81TldkbXNUZWpabko3azNZcFp5TzVOR2Jtc1RlamhtZW1zVGVqOW1KN2szWXRaQ0k3azNZaFp5TzVObWJtQXlPNU4yYTFwbUo3azNZMVp5TzVObWVtc1RlakZtSjdrM1lyWnlPNU5tZG1BeU81Tm1jbXNUZWp0V2RwWnlPNU5HYm1zVGVqOW1KN2szWXJaQ0k3azNZcVp5TzVOV2Ftc1RlalpuSjdrM1l2WnlPNU5tY21zVGVqVm5KN2szWXdaeU81Tm1jbXNUZWpWbko3azNZd1pTTDdrM1l2WnlPNU5tYm1zVGVqOW1KN2szWTJaeU81Tm1jbXNUZWpWV2Ftc1RlamgwUW1zVGF0VjJjbUFUTTcwV2R1WnlPcDFXWnpaQ096c1RiMTVtSjdBWGJoWnlPazlXYXlWR2Ntc1RlalpsSjNFRElnc1RlalZuSjdrM1kwWnlPNU5tYm1zVGVqVldhbXNUZWpkbUo3azNZaFp5TzVOV1pwWnlPNU5tY21BeU81TjJhMWxtSjdrM1lzWnlPNU5HY21zVGVqRm1KN2szWXlaeU81TjJhbUF5TWdzVFl0MTJialp5TzVOV1FtY1RNZ0F5TzVOV2Rtc1RlalJuSjdrM1l1WnlPNU5XWnBaeU81TjJabXNUZWpGbUo3azNZbGxtSjdrM1l5WkNJN2szWXJWWGFtc1RlanhtSjdrM1l3WnlPNU5XWW1zVGVqSm5KN2szWXJaQ0l6QUNJZ3NUZWpsbUo3azNZMFp5TzVOV1ltc1RlalJtSjdrM1l2WnlPNU5HWm1BeU81TldZbXNUZWp0bUo3azNZNlp5TzVOV1ltc1RlakpuSjdrM1k2WkNJN2szWXZaeU81TjJabXNUZWo5bUo3azNZdVp5TzVOV1ltc1RlalpuSjdrM1kxWnlPNU5HYTZaeU81TkdabXNUZWp0V2RwWnlPNU5HYm1zVGVqTm5KN2szWXZaeU81TkdabUF5TzVOMmJtc1RlalJrSjdrV2JsTm5Kd0V6T3RWbmJtc1RhdFYyY21nek03MFdkdVp5T3cxV1ltc2pidngyYmpaeU81TldkbXNUZWpSbko3azNZelp5TzVOV1pwWnlPNU5HZG1BeU81TldZNVp5TzVObWJtc1RlajVtSjdrM1loWnlPNU5tYm1zVGVqOW1KN2szWXJaeU81TldhbXNUZWpabEo3a1dibE5uSndFek90Vm5ibXNUYXRWMmNtZ3pNNzBXZHVaeU93MVdZbXNUYXRWMmNtQVRNNzBXZHVaeU9wMVdaelpDT3pzVGIxNW1KN0FYYmhaeU9rOVdheVZHY21zVGVqVm5KN2szWXNaeU81TjJibXNUZWo1bUo3azNZaFp5TzVOR2Rtc1RlalZXYW1zVGVqMW1KZ3NEWnZsbWNsQm5KN2szWXpaeU81Tm1ZbXNUZWpGbUpnc1RlanhtSjdrM1l0WlNONUF5TzVObWVtQXlPNU5XZG1zVGVqNW1KN2szWXJWWGFtc1RlajFtSjdrM1loWnlPNU5HYm1zVGVqdFdkcFp5TzVOR2Ntc1RlajltSjdrM1l5WnlPNU5HY21zVGVqOW1KN2szWTZaeU81TjJhMWxtSmdzVGVqeG1KN2szWXRaU05nc1RlamxtSjdrM1kwWnlPNU5XWW1zVGVqaDJjbXNUZWp0V2RwWnlPNU5XYm1zVGVqcGxKZ3NEWnZsbWNsQm5KN2szWVdaeU54QXlPNU5HZG1zVGVqNW1KN2szWWxsbUo3azNZblp5TzVOV1ltc1RlalZXYW1zVGVqSmxKN2tXYmxObkp3RXpPdFZuYm1zVGF0VjJjbWd6TTcwV2R1WnlPdzFXWW1zRFp2bG1jbEJuSjdrM1lwWnlPNU5HZG1zVGVqOW1KN2szWXNaeU81TjJjbXNUZWpsbUo3azNZclpDSTdrM1lwbG5KN2szWXZaeU81Tm1kbXNUZWo5bUo3azNZMFp5TzVOMmMwWnlPNU4yYm1BeU81TldhNVp5TzVOMmJtc1RlajVtSjdrM1lobG5KN2szWWtaeU81TjJibXNUZWpSblp2Tm5KN2szWXNaQ0k3azNZc1p5TzVOV2JtSXpPaDFXYnZObUp3QXlPNU5XYW1zVGVqUm5KN2szWWhaeU81TkdabXNUZWo5bUo3azNZa1pDSTdFV2J0OTJZbXNUZWpWbko3azNZc1p5TzVOMmJtc1RlajVtSjdrM1loWnlPNU5HZG1zVGVqVldhbXNUZWoxbUpnc0RadmxtY2xCbko3azNZelp5TzVObVltc1RlakZtSmdzVGVqeG1KN2szWXRaQ013RURJN2szWTJaQ0k3SVhZd0puSjdrM1kxWnlPNU5HZG1zVGVqRm1KN2szWXlaeU81TkdabXNUZWp0V2RwWnlPNU4yWm1zVGVqRm1KN2szWXlaeU81TkdkbXNUZWpWV2Ftc1RlalJuSjdJWFl3eG1KZ3NUZWpWbko3azNZMFp5TzVOR2RtOTJjbXNUZWp4bUo3azNZaFp5TzVObVltc1RlajltSjdrM1lyWkNJN2szWTFaeU81TkdkbXNUZWpGbUo3azNZMFp5TzVOV1pwWnlPNU4yYzBaeU81TldZbUF5TzVOMlptQVNNN0VXYnQ5MlltQURJN2szWXBaeU81TkdkbXNUZWpsbUo3azNZdVp5TzVOV2Ftc1RlamgyWW1zVGVqcG5KN2szWXZaeU81Tm1VbUF5T2s5V2F5VkdjbXNUZWpGa0ozRURJN2szWTBaeU81Tm1ibXNUZWpWV2Ftc1RlamRtSjdrM1loWnlPNU5XWnBaeU81Tm1VbXNUYXRWMmNtQVRNNzBXZHVaeU9wMVdaelpDT3pzVGIxNW1KN0FYYmhaeU9rOVdheVZHY21zVGVqUm5KN2szWXpaeU81TldacFp5TzVOR2RtQXlPNU5tYW1zVGVqdFdkcFp5TzVObWJtc1RlakZtSjdrM1l3WnlPNU4yYm1zVGVqdGtKZzB5TzVOR2Jtc1RlanhtSjdrM1lyVlhhbXNUZWpSa0o%3D', 1);
INSERT INTO "public"."reactiv_menu" ("id", "name", "position", "units_id", "comment", "group_id") VALUES (10, 'Реагент 8А. Модифікований тест з тіоціонатом кобальту (ІІ)', 0, 1, 'PXNUZWoxbUo3azNZeVp5TzVOMmJtc1RlalptSjdrM1l2WnlPNU5tY21zVGVqOW1KN2szWXNaeU81TkdTTFpDSTdrM1l6WkNPZ3NUZWpSbko3azNZdVp5TzVOV1pwWnlPNU4yWm1zVGVqRm1KN2szWWxsbUo3azNZU1p5T3AxV1p6WkNNeHNUYjE1bUo3a1dibE5uSjRNek90Vm5ibXNEY3RGbUo3azNZaFp5TzVOR2Rtc1RlajltSjdrM1lzWnlPNU4yY21zVGVqbG1KN2szWXJaQ0k3azNZaFp5TzVObWJtc1RlalJtSjdrM1lwWnlPNU5tY21zVGVqOW1KN2szWXNaeU81TkdhclpDSTdrM1loWnlPNU5tYm1zVGVqRm1KN2szWTJaeU81TjJibXNUZWpKbko3azNZMFp5TzVObWJtc1RlalZXYW1zVGVqTkhkbXNUZWo1bUo3azNZdlp5TzVOMmFtQXlPNU5tVm1nREk3azNZMFp5TzVObWJtc1RlalZXYW1zVGVqZG1KN2szWWhaeU81TldacFp5TzVObVVtc1RhdFYyY21BVE03MFdkdVp5T3AxV1p6WkNPenNUYjE1bUo3QVhiaFp5T2s5V2F5VkdjbXNUZWpWbko3azNZdVp5TzVOV2Ftc1RlakpuSjdrM1lsbG1KN2szWXpSbko3azNZclZYYW1zVGVqeG1KN2szWW5aQ0k3azNZc1p5TzVOV2JtQUNNMUF5TzVOV2Ftc1RlalJuSjdrM1loWnlPNU5HWm1zVGVqOW1KN2szWWtaQ0k3azNZdFp5TzVOMmExbG1KN2szWTBaeU81TjJibXNUZWpCbkpnc1RZdDEyYmpaeU81TldhbXNUZWpSbko3azNZdlp5TzVOR2Jtc1Rlak5uSjdrM1lwWnlPNU4yYW1BeU81TldhNVp5TzVOMmJtc1RlalpuSjdrM1l2WnlPNU5HZG1zVGVqTkhkbXNUZWo5bUo3SVhZd0puSjdrM1l0WnlPNU4yYTFwbUo3azNZaVp5TzVOMmJtc0Ridk5uSjdrM1l0WnlPNU4yYTFwbUo3azNZaVp5TzVOMmJtQXlPNU4yYTFsbUo3azNZdVp5TzVOV1pwWnlPNU5HYXpaeU81TjJibXNUZWo1bUo3azNZa1p5TzVOMmExbG1KN2szWTJaQ0k3azNZMVp5T3lGR2NzWkNJN1FuYmpKWFp3WkNNeEFDSTdrM1lzWnlPNU5XYm1BQ00xQXlPNU5tZG1BeU95RkdjeVp5TzVOMmExbGtKN2szWXJWWFNtc2pjaEJIYm1BeU81TldZbXNUZWpSbko3azNZMFoyYnpaeU81TkdibXNUZWpGbUo3azNZaVp5TzVOMmJtc1RlanRtSmdzVGVqVm5KN2szWTBaeU81TldZbXNUZWo1bUo3azNZdlp5TzVOMmExbG1KN2szWXpSbko3azNZdlp5TzVOMmExbG1KN2szWTBaQ0k3azNZblpDSXhBeU81TldhbXNUZWpSbko3azNZcFp5TzVObWJtc1RlamxtSjdrM1lvTm1KN2szWTZaeU81TjJibXNUZWpKbEpnc0RadmxtY2xCbko3azNZQlpDT2dzVGVqUm5KN2szWXVaeU81TldacFp5TzVOMlptc1RlakZtSjdrM1lsbG1KN2szWVNaeU9wMVdaelpDTXhzVGIxNW1KN2tXYmxObko0TXpPdFZuYm1zRGN0Rm1KN1EyYnBKWFp3WnlPNU5XWW1zVGVqUm5KN2szWTBaeU81TjJibXNUZWp0bUo3azNZVFpDSTdrM1kwWnlPNU4yY21zVGVqVldhbXNUZWpSbEo%3D', 1);
INSERT INTO "public"."reactiv_menu" ("id", "name", "position", "units_id", "comment", "group_id") VALUES (12, 'Реагент 7В 2,5% розчин тіоціонату кобальту', 0, 1, 'PT13T3AxV1p6WkNNeHNUYjE1bUo3a1dibE5uSjRNek90Vm5ibXNEY3RGbUo3a1dibE5uSndFek90Vm5ibXNUYXRWMmNtZ3pNNzBXZHVaeU93MVdZbXNUYXRWMmNtQVRNNzBXZHVaeU9wMVdaelpDT3pzVGIxNW1KN0FYYmhaeU9rOVdheVZHY21zVGVqVm5KN2szWXVaeU81TldhNVp5TzVOV1ltc1RlanRtSjdrM1l2WnlPNU4yYW1BeU81TkdkbTkyY21zVGVqUm5KN2szWXpaeU81TjJhMWxtSjdrM1l1WnlPNU5HZG1zVGVqVm5KN2szWXpaeU81TldhbXNUZWpKbko3azNZd1pDSTdrM1kxWnlPNU5tZG1zVGVqbG1KN2szWXNaeU81TkdhNlp5TzVOMmJtc1RlajFtSmdzVGVqRm1KN2szWXVaQ0k3azNZclZuYW1zVGVqVm5KN2szWTZaeU81TldZbXNUZWp0bUo3azNZMlpDSTdrM1lobG5KN2szWXVaeU81Tm1ibXNUZWpWV2Ftc1RlanhtSjdrM1kyWnlPNU5tY21zVGVqRm1KN2szWWlaeU81TldZbXNUZWpwbkpnc1RlanRXZHFaeU81Tm1ibXNUZWpsbUo3azNZVFp5T2s5V2F5VkdjbXNUZWpSbko3azNZaFp5TzVOR2Rtc1RlalJuWnZObko3azNZc1p5TzVOV2Rtc1RlanBuSjdrM1lsbG1KN2szWVNaeU9wMVdaelpDTXhzVGIxNW1KN2tXYmxObko0TXpPdFZuYm1zRGN0Rm1KN2tXYmxObkp3RXpPdFZuYm1zVGF0VjJjbWd6TTcwV2R1WnlPdzFXWW1zRFp2bG1jbEJuSjdrM1kxWnlPNU4yYW1zVGVqSm5KN2szWXJWWGFtc1RlakptSjdrM1l2WnlPNU5tY21zVGVqQm5KZ3NUZWpsbUo3azNZMFp5TzVOV2Ftc1Rlak5uSjdrM1kxWnlPNU5tY21zVGVqUm5KN2szWTZaQ0k3azNZaFp5TzVOR2RtQXlPNU5tVm1jREk3azNZaFp5TzVOR2Rtc1RlajVtSjdrM1lsbG1KN2szWW5aeU81TldZbXNUZWpWV2Ftc1RlakpuSmdzVGVqVlhlbXNUZWp4bUo3azNZd1p5TzVOV1ltc1RlakpuSjdrM1lyWkNJeEF5TzVOV2Ftc1RlalJuSjdrM1loWnlPNU5HWm1zVGVqOW1KN2szWUVaQ0k3UTJicEpYWndaeU03a1dibE5uSndFek90Vm5ibXNUYXRWMmNtZ3pNNzBXZHVaeU93MVdZbXNEWnZsbWNsQm5KN2szWWtaeU81Tm1ibXNUZWpWbko3azNZclp5TzVOV1pwWnlPNU4yY21BeU81Tkdhclp5TzVOMmJtc1RlanRtSjdrM1kwWjJielp5TzVOR2Jtc1RlanRXZHBaeU81TjJhbXNUZWpWV2Ftc1RlalJtSmdzVGVqMW1KN2szWXZaeU81TjJabXNUZWpGV2Vtc1RlalJuSjdrM1l2WnlPNU5tY21zVGVqQm5KZ3NUZWpWbko3azNZclp5TzVObWNtc1RlanRXZHBaeU81Tm1ZbXNUZWo5bUo3azNZeVp5TzVOR2NtQXlPNU5XYW1zVGVqUm5KN2szWXBaeU81TjJjbXNUZWpWbko3azNZeVp5TzVOR2Rtc1RlanBuSmdzVGVqRm1KN2szWTBaQ0k3azNZQlp5TmdzVGVqVm5KN2szWTBaeU81Tm1ibXNUZWpWV2Ftc1RlamRtSjdrM1loWnlPNU5XWnBaeU81Tm1jbUF5TzVOV2Q1WnlPNU5HYm1zVGVqQm5KN2szWWhaeU81Tm1jbXNUZWp0bUpnRURJN2szWXBaeU81TkdkbXNUZWpGbUo3azNZa1p5TzVOMmJtc1RlalJrSmdzRFp2bG1jbEJuSnlzVGF0VjJjbUFUTTcwV2R1WnlPcDFXWnpaQ096c1RiMTVtSjdBWGJoWnlPazlXYXlWR2Ntc1RlamxtSjdrM1lyWnlPNU5tY21zVGVqdFdkcFp5TzVObVltc1RlajltSjdrM1l5WnlPNU5HY21BeU81TjJibXNUZWpSbUpnc1RlamxtSjdrM1kwWnlPNU5XYW1zVGVqUm5KN2szWXpaeU81TjJhMWxtSjdrM1l0WnlPNU4yYm1zVGVqQm5KZ3NUZWpWbko3azNZc1p5TzVOV1ltc1RlanRXZHBaeU81Tm1jbXNUZWpWV2Ftc1RlalJuSjdrM1loWnlPNU5XYm1BeU81TkdkbTkyY21zVGVqUm5KN2szWXpaeU81TjJhMWxtSjdrM1lyWnlPNU5HZG05MmNtc1RlanhtSjdrM1lyVlhhbXNUZWp0bUpnc1RlalZuSjdrM1lyWnlPNU5XYW1zVGVqeG1KN2szWWxsbUo3azNZMlp5TzVOV1pwWnlPNU5tVG1BeU9rOVdheVZHY21Fek9wMVdaelpDTXhzVGIxNW1KN2tXYmxObko0TXpPdFZuYm1zRGN0Rm1KNzQyYnM5Mlltc1RlalJuSjdrM1l6WnlPNU5XWnBaeU81TkdWbXNUYXRWMmNtQVRNNzBXZHVaeU9wMVdaelpDT3pzVGIxNW1KN0FYYmhaeU9wMVdaelpDTXhzVGIxNW1KN2tXYmxObko0TXpPdFZuYm1zRGN0Rm1KN1EyYnBKWFp3WnlPNU5XYW1zVGVqUm1KN2szWXZaeU81Tm1kbUF5TzVOV2E1WnlPNU4yYm1zVGVqNW1KN2szWWhaeU81Tm1kbXNUZWo5bUo3azNZNlp5TzVOMmExbG1KN2szWXVaeU81TjJibXNUZWpwbUo3azNZbGxtSjdrM1lrWkNJN2szWXNaeU81TldibUFDTXdFREk3azNZMlpDSTdJWFl3Sm5KN2szWXJWWFNtc1RlanRXZEpaeU95Rkdjc1pDSTdrM1loWnlPNU5HZG1zVGVqeG1KN2szWWhaeU81Tm1ZbXNUZWo5bUo3azNZclpDSTdrM1kxWnlPNU5HZG1zVGVqRm1KN2szWXVaeU81TjJibXNUZWp0V2RwWnlPNU4yYzBaeU81TjJibXNUZWp0V2RwWnlPNU5HZG1BeU81TjJabUFTTjdFV2J0OTJZbUlESTdrM1lwWnlPNU5HZG1zVGVqbG1KN2szWXVaeU81TldhbXNUZWpoMlltc1RlanBuSjdrM1l2WnlPNU5tVW1BeU91OUdidk5tSjdrM1lXWnlOZ3NUZWpSbko3azNZdVp5TzVOV1pwWnlPNU4yWm1zVGVqRm1KN2szWWxsbUo3azNZU1p5T3AxV1p6WkNNeHNUYjE1bUo3a1dibE5uSjRNek90Vm5ibXNEY3RGbUo3azNZcFp5TzVOR2Rtc1RlajltSjdrM1lzWnlPNU4yY21zVGVqbG1KN2szWXJaQ0k3azNZcGxuSjdrM1l2WnlPNU5tYm1zVGVqUm1KN2szWXBaeU81Tm1jbXNUZWo5bUo3azNZc1p5TzVOR2FyWkNJN2szWXVaeU81TldhbXNUZWpoMlltc1RlanBuSjdrM1l2WnlPNU5tY21BeU81Tm1hbXNUZWpsbUo3azNZdVp5TzVOR1ptc1RlajltSjdrM1kyWkNJN1FuYmpKWFp3WmlOeEF5T3U5R2J2Tm1KN2szWWhaeU5nc1RlalJuSjdrM1l1WnlPNU5XWnBaeU81TjJabXNUZWpGbUo3azNZbGxtSjdrM1lTWnlPcDFXWnpaQ014c1RiMTVtSjdrV2JsTm5KNE16T3RWbmJtc0RjdEZtSjdrM1kxWnlPNU5HZG1zVGVqUm5adk5uSjdrM1lzWnlPNU5XWW1zVGVqSm1KN2szWXZaeU81TjJhbUF5TzVOV2Jtc1RlajltSjdrM1kwWnlPNU5XWW1zVGVqNW1KN2szWXZaeU81TjJhMWxtSjdrM1l6Um5KN2szWXZaeU81TjJhMWxtSjdrM1kwWkNJN2szWTZaQ0k3azNZMFp5TzVOMmNtc1RlalZXYW1zVGVqUmxK', 1);


--
-- Data for Name: reactiv_menu_ingredients; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO "public"."reactiv_menu_ingredients" ("reagent_id", "reactiv_menu_id", "unique_index") VALUES (59, 36, 'f1eefe5894813fbe42e0040826932b73');
INSERT INTO "public"."reactiv_menu_ingredients" ("reagent_id", "reactiv_menu_id", "unique_index") VALUES (57, 8, '97dcd152ceb2613a6f02c4e12cc45591');
INSERT INTO "public"."reactiv_menu_ingredients" ("reagent_id", "reactiv_menu_id", "unique_index") VALUES (82, 8, '3af85f32db0dcd0caf0c2ddff843ad4b');
INSERT INTO "public"."reactiv_menu_ingredients" ("reagent_id", "reactiv_menu_id", "unique_index") VALUES (6, 11, '49805866fb4f23211d88a193f2e57f5a');
INSERT INTO "public"."reactiv_menu_ingredients" ("reagent_id", "reactiv_menu_id", "unique_index") VALUES (16, 11, '69b3906739cc2855b347066eb6dd8bc5');
INSERT INTO "public"."reactiv_menu_ingredients" ("reagent_id", "reactiv_menu_id", "unique_index") VALUES (22, 11, '96311d4f17c594b0a810f5066090ab5d');
INSERT INTO "public"."reactiv_menu_ingredients" ("reagent_id", "reactiv_menu_id", "unique_index") VALUES (63, 13, '91b8452d01765acf65983f1d973365f0');
INSERT INTO "public"."reactiv_menu_ingredients" ("reagent_id", "reactiv_menu_id", "unique_index") VALUES (18, 10, '92394cbc0df84c9be44e88480281491e');
INSERT INTO "public"."reactiv_menu_ingredients" ("reagent_id", "reactiv_menu_id", "unique_index") VALUES (29, 10, '78274efadf61e0edf96a5cee8d138ade');
INSERT INTO "public"."reactiv_menu_ingredients" ("reagent_id", "reactiv_menu_id", "unique_index") VALUES (51, 10, 'a0dbb792aae8f065286520f861a438af');
INSERT INTO "public"."reactiv_menu_ingredients" ("reagent_id", "reactiv_menu_id", "unique_index") VALUES (26, 14, 'a4968457938d3db4d37fd9930d1934f9');
INSERT INTO "public"."reactiv_menu_ingredients" ("reagent_id", "reactiv_menu_id", "unique_index") VALUES (32, 14, '8c64922e116896605a72b0bf03198a04');
INSERT INTO "public"."reactiv_menu_ingredients" ("reagent_id", "reactiv_menu_id", "unique_index") VALUES (57, 7, 'e16c066a7fff0b028ee67ddda7ebb310');
INSERT INTO "public"."reactiv_menu_ingredients" ("reagent_id", "reactiv_menu_id", "unique_index") VALUES (62, 7, 'f227dda84f830026f4d6eb57d5c1a615');
INSERT INTO "public"."reactiv_menu_ingredients" ("reagent_id", "reactiv_menu_id", "unique_index") VALUES (40, 17, 'd05130f3c4d5381ad95b6f3bfb4a3f4c');
INSERT INTO "public"."reactiv_menu_ingredients" ("reagent_id", "reactiv_menu_id", "unique_index") VALUES (86, 15, '37ae67b74ff7331f09a3a9e2fb5ae191');
INSERT INTO "public"."reactiv_menu_ingredients" ("reagent_id", "reactiv_menu_id", "unique_index") VALUES (27, 15, '63c60fb2d19a9f36c33ee0de1d5a36d2');
INSERT INTO "public"."reactiv_menu_ingredients" ("reagent_id", "reactiv_menu_id", "unique_index") VALUES (43, 16, '131badea4b0981702ddf6e9ea071aed3');
INSERT INTO "public"."reactiv_menu_ingredients" ("reagent_id", "reactiv_menu_id", "unique_index") VALUES (84, 9, '0d18f7cbd46f131ac70a11a9c818b035');
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
INSERT INTO "public"."reactiv_menu_ingredients" ("reagent_id", "reactiv_menu_id", "unique_index") VALUES (39, 34, 'b630d460d25007987a5b2e3ad8f4c0ab');
INSERT INTO "public"."reactiv_menu_ingredients" ("reagent_id", "reactiv_menu_id", "unique_index") VALUES (39, 33, '27989fbce7d6d34b809176429b1f1d44');
INSERT INTO "public"."reactiv_menu_ingredients" ("reagent_id", "reactiv_menu_id", "unique_index") VALUES (29, 12, 'ed11e899101a24808324f52aef550826');
INSERT INTO "public"."reactiv_menu_ingredients" ("reagent_id", "reactiv_menu_id", "unique_index") VALUES (6, 16, '36b00917068fdd42776ed4715c547cab');
INSERT INTO "public"."reactiv_menu_ingredients" ("reagent_id", "reactiv_menu_id", "unique_index") VALUES (960, 104, '631ba26f330b0942117816428cb71764');
INSERT INTO "public"."reactiv_menu_ingredients" ("reagent_id", "reactiv_menu_id", "unique_index") VALUES (963, 104, '2540ba56daeef805fc79f8221cf9d2e6');
INSERT INTO "public"."reactiv_menu_ingredients" ("reagent_id", "reactiv_menu_id", "unique_index") VALUES (982, 105, '2eceec98657bf095cfdd83eced840474');
INSERT INTO "public"."reactiv_menu_ingredients" ("reagent_id", "reactiv_menu_id", "unique_index") VALUES (979, 105, 'a7708cdb4958b1b14bc63ce3ce52cb50');
INSERT INTO "public"."reactiv_menu_ingredients" ("reagent_id", "reactiv_menu_id", "unique_index") VALUES (969, 105, '0ca659ae2219994ed9a0918557071b0d');
INSERT INTO "public"."reactiv_menu_ingredients" ("reagent_id", "reactiv_menu_id", "unique_index") VALUES (961, 105, '01c29d16bd06681c8506f9f9eb1b8042');
INSERT INTO "public"."reactiv_menu_ingredients" ("reagent_id", "reactiv_menu_id", "unique_index") VALUES (981, 105, '550d930434eef949d0d364872073d070');
INSERT INTO "public"."reactiv_menu_ingredients" ("reagent_id", "reactiv_menu_id", "unique_index") VALUES (986, 106, 'bb35c05c921106405989710b198f0362');
INSERT INTO "public"."reactiv_menu_ingredients" ("reagent_id", "reactiv_menu_id", "unique_index") VALUES (979, 106, 'e2362b7ef55ff18e43f53cc2e932e451');
INSERT INTO "public"."reactiv_menu_ingredients" ("reagent_id", "reactiv_menu_id", "unique_index") VALUES (983, 106, 'd7f2897097a5f61c2c2fea3a207c6ef3');
INSERT INTO "public"."reactiv_menu_ingredients" ("reagent_id", "reactiv_menu_id", "unique_index") VALUES (975, 106, '8030ef4a54a1a8a6a9471c7fe476411f');
INSERT INTO "public"."reactiv_menu_ingredients" ("reagent_id", "reactiv_menu_id", "unique_index") VALUES (988, 107, '2533ea14cde87b0f75d94224f9c9c322');
INSERT INTO "public"."reactiv_menu_ingredients" ("reagent_id", "reactiv_menu_id", "unique_index") VALUES (983, 107, '7ca1d9f4aa8b52f28ad4e3ced6e070b9');
INSERT INTO "public"."reactiv_menu_ingredients" ("reagent_id", "reactiv_menu_id", "unique_index") VALUES (978, 107, '07c596813076a4dd388a9bb9bcd38b04');
INSERT INTO "public"."reactiv_menu_ingredients" ("reagent_id", "reactiv_menu_id", "unique_index") VALUES (987, 107, 'b7db1d5cd1d4ecdc0a938db7d348c51f');
INSERT INTO "public"."reactiv_menu_ingredients" ("reagent_id", "reactiv_menu_id", "unique_index") VALUES (984, 107, '4bc970384514afb9871af1abd95e2974');
INSERT INTO "public"."reactiv_menu_ingredients" ("reagent_id", "reactiv_menu_id", "unique_index") VALUES (963, 108, '3ec25c07c7342176e87a2d4676cee38d');
INSERT INTO "public"."reactiv_menu_ingredients" ("reagent_id", "reactiv_menu_id", "unique_index") VALUES (960, 108, 'a0b410d88eaae3bd78df05ee41031903');
INSERT INTO "public"."reactiv_menu_ingredients" ("reagent_id", "reactiv_menu_id", "unique_index") VALUES (971, 109, '43b21749b4912c7d17e1077ad9a0afb8');
INSERT INTO "public"."reactiv_menu_ingredients" ("reagent_id", "reactiv_menu_id", "unique_index") VALUES (970, 109, 'fc06752596d596f88a537830fe1cfbf1');
INSERT INTO "public"."reactiv_menu_ingredients" ("reagent_id", "reactiv_menu_id", "unique_index") VALUES (967, 109, 'ecdea36c3f9a9e40033119d2ff195d2d');
INSERT INTO "public"."reactiv_menu_ingredients" ("reagent_id", "reactiv_menu_id", "unique_index") VALUES (978, 110, '413efcafd873ff7cddadbe54336463e8');
INSERT INTO "public"."reactiv_menu_ingredients" ("reagent_id", "reactiv_menu_id", "unique_index") VALUES (988, 110, '3b710ee8c3f53019050c478e667b7603');
INSERT INTO "public"."reactiv_menu_ingredients" ("reagent_id", "reactiv_menu_id", "unique_index") VALUES (974, 111, '10bf861cc68fb4927d13efd072cdb475');
INSERT INTO "public"."reactiv_menu_ingredients" ("reagent_id", "reactiv_menu_id", "unique_index") VALUES (966, 111, 'e62b7beb8b08d6d82ca65426492ba144');
INSERT INTO "public"."reactiv_menu_ingredients" ("reagent_id", "reactiv_menu_id", "unique_index") VALUES (979, 112, '31111383a15772dad87bb47d2f6191f5');
INSERT INTO "public"."reactiv_menu_ingredients" ("reagent_id", "reactiv_menu_id", "unique_index") VALUES (966, 112, 'd43e62cf429d225af6073f318c9b7f9d');
INSERT INTO "public"."reactiv_menu_ingredients" ("reagent_id", "reactiv_menu_id", "unique_index") VALUES (973, 112, 'cf20dca3e4a0b8ad70014c5270b7dfb8');
INSERT INTO "public"."reactiv_menu_ingredients" ("reagent_id", "reactiv_menu_id", "unique_index") VALUES (963, 112, 'e9470cf63b6a805dfe9a7145e119785a');
INSERT INTO "public"."reactiv_menu_ingredients" ("reagent_id", "reactiv_menu_id", "unique_index") VALUES (979, 113, 'ee1118cb9d141cf4158139323adeac15');
INSERT INTO "public"."reactiv_menu_ingredients" ("reagent_id", "reactiv_menu_id", "unique_index") VALUES (984, 113, 'e3f28d2d73b4d07477c0f06406dc3233');


--
-- Data for Name: reactiv_menu_reactives; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO "public"."reactiv_menu_reactives" ("reactiv_menu_id", "reactiv_id", "unique_index") VALUES (36, 33, 'f03c445214de84bf84fd480e033975b8');
INSERT INTO "public"."reactiv_menu_reactives" ("reactiv_menu_id", "reactiv_id", "unique_index") VALUES (109, 104, 'aee1069f15639e5322ea40302c73fb7d');
INSERT INTO "public"."reactiv_menu_reactives" ("reactiv_menu_id", "reactiv_id", "unique_index") VALUES (109, 106, '6212332014ff399a04fe3994c7812da2');


--
-- Data for Name: reagent; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (960, '2020-07-08 00:47:48.840972', 'Тестова речовина (liquid) 1', 1, 1, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (961, '2020-07-08 00:47:48.89654', 'Тестова речовина (liquid) 2', 1, 1, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (962, '2020-07-08 00:47:48.940548', 'Тестова речовина (liquid) 3', 1, 1, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (963, '2020-07-08 00:47:48.985103', 'Тестова речовина (liquid) 4', 1, 1, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (964, '2020-07-08 00:47:49.029153', 'Тестова речовина (liquid) 5', 1, 1, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (965, '2020-07-08 00:47:49.065205', 'Тестова речовина (liquid) 6', 1, 1, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (966, '2020-07-08 00:47:49.096103', 'Тестова речовина (liquid) 7', 1, 1, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (967, '2020-07-08 00:47:49.128007', 'Тестова речовина (liquid) 8', 1, 1, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (968, '2020-07-08 00:47:49.162672', 'Тестова речовина (liquid) 9', 1, 1, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (969, '2020-07-08 00:47:49.207211', 'Тестова речовина (liquid) 10', 1, 1, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (970, '2020-07-08 00:47:49.240454', 'Тестова речовина (solid) 1', 1, 2, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (971, '2020-07-08 00:47:49.266563', 'Тестова речовина (solid) 2', 1, 2, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (972, '2020-07-08 00:47:49.296143', 'Тестова речовина (solid) 3', 1, 2, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (973, '2020-07-08 00:47:49.329235', 'Тестова речовина (solid) 4', 1, 2, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (974, '2020-07-08 00:47:49.365159', 'Тестова речовина (solid) 5', 1, 2, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (975, '2020-07-08 00:47:49.395927', 'Тестова речовина (solid) 6', 1, 2, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (976, '2020-07-08 00:47:49.440456', 'Тестова речовина (solid) 7', 1, 2, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (977, '2020-07-08 00:47:49.466597', 'Тестова речовина (solid) 8', 1, 2, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (978, '2020-07-08 00:47:49.495957', 'Тестова речовина (solid) 9', 1, 2, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (979, '2020-07-08 00:47:49.540298', 'Тестова речовина (solid) 10', 1, 2, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (980, '2020-07-08 00:47:49.56673', 'Тестова речовина (powder) 1', 1, 2, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (981, '2020-07-08 00:47:49.595955', 'Тестова речовина (powder) 2', 1, 2, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (982, '2020-07-08 00:47:49.628352', 'Тестова речовина (powder) 3', 1, 2, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (983, '2020-07-08 00:47:49.662658', 'Тестова речовина (powder) 4', 1, 2, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (984, '2020-07-08 00:47:49.696005', 'Тестова речовина (powder) 5', 1, 2, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (985, '2020-07-08 00:47:49.740389', 'Тестова речовина (powder) 6', 1, 2, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (986, '2020-07-08 00:47:49.776329', 'Тестова речовина (powder) 7', 1, 2, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (987, '2020-07-08 00:47:49.807416', 'Тестова речовина (powder) 8', 1, 2, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (988, '2020-07-08 00:47:49.851628', 'Тестова речовина (powder) 9', 1, 2, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (989, '2020-07-08 00:47:49.896193', 'Тестова речовина (powder) 10', 1, 2, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (990, '2020-07-08 00:47:49.92893', 'Тестовий матеріал (other) 1', 1, 9, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (991, '2020-07-08 00:47:49.951589', 'Тестовий матеріал (other) 2', 1, 9, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (992, '2020-07-08 00:47:49.989024', 'Тестовий матеріал (other) 3', 1, 9, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (993, '2020-07-08 00:47:50.018206', 'Тестовий матеріал (other) 4', 1, 9, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (994, '2020-07-08 00:47:50.062779', 'Тестовий матеріал (other) 5', 1, 9, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (995, '2020-07-08 00:47:50.107217', 'Тестовий матеріал (other) 6', 1, 9, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (996, '2020-07-08 00:47:50.151529', 'Тестовий матеріал (other) 7', 1, 9, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (997, '2020-07-08 00:47:50.196083', 'Тестовий матеріал (other) 8', 1, 9, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (998, '2020-07-08 00:47:50.228839', 'Тестовий матеріал (other) 9', 1, 9, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (999, '2020-07-08 00:47:50.262813', 'Тестовий матеріал (other) 10', 1, 9, 2);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (0, '2019-12-28 11:10:26.287818', '--', 0, 0, 0);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (113, '2020-04-07 14:18:43.640017', 'Циліндр мірний 3-50-2', 3, 9, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (2, '2020-01-02 15:39:01.529732', '1,3-динітробензол', 3, 1, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (65, '2020-01-02 15:39:01.529732', 'Циклогексан', 1, 1, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (59, '2020-01-02 15:39:01.529732', 'Тривкий синій Б', 2, 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (167, '2020-04-09 12:05:00.822686', 'Кювета кварцева, 10 мм', 3, 9, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (238, '2020-04-10 11:00:34.110825', 'КалійНатрій виннокислий', 3, 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (239, '2020-04-10 11:01:07.710927', 'Малахітовий зелений', 3, 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (240, '2020-04-10 11:01:18.976689', 'Калій роданистий', 3, 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (241, '2020-04-10 11:01:33.632249', 'Алюмінію окис (б/в)', 3, 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (242, '2020-04-10 11:01:43.776577', 'Глюкоза', 3, 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (243, '2020-04-10 11:02:02.709261', 'Метилетилкетон', 3, 1, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (244, '2020-04-10 11:02:10.998929', 'Хромотропової кислоти динатрієва сіль', 3, 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (245, '2020-04-10 11:02:18.854128', 'Каплевловлювач КО-14/23-100 ТС', 3, 9, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (246, '2020-04-10 11:04:07.538708', 'Папір фільтрувальний', 3, 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (247, '2020-04-10 11:28:47.328486', 'Фільтри лабораторні знезолені стрічка синя діаметром 110 мм', 3, 9, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (248, '2020-04-10 12:05:29.164264', 'Циліндр мірний 1-100-2', 3, 9, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (249, '2020-04-10 12:12:15.415278', 'Колба мірна КМ-1-25-2 ХС', 3, 9, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (250, '2020-04-10 12:20:45.695631', 'Піпетка мірна з градуювавнням 2-2-2-1 мл (повний злив)', 3, 9, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (251, '2020-04-10 12:28:13.800152', 'Циліндр мірний 1-250-2', 3, 9, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (21, '2020-01-02 15:39:01.529732', 'Діетиловий ефір', 2, 1, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (24, '2020-01-02 15:39:01.529732', 'Ефір диізопропіловий', 2, 1, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (25, '2020-01-02 15:39:01.529732', 'Ізопропанол', 2, 1, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (115, '2020-04-07 14:19:17.871653', 'Колба круглодонна К-1-1000-29/32 ТС', 3, 9, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (23, '2020-01-02 15:39:01.529732', 'Етилацетат', 2, 1, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (20, '2020-01-02 15:39:01.529732', 'Діетиламін', 2, 1, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (145, '2020-04-07 16:37:25.612425', 'Фіксанал рН-метрія', 3, 9, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (82, '2020-03-17 12:38:38.461639', 'Селениста кислота', 2, 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (10, '2020-01-02 15:39:01.529732', 'Ацетон', 1, 1, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (22, '2020-01-02 15:39:01.529732', 'Етанол', 1, 1, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (84, '2020-03-18 12:58:32.313461', 'Сульфат заліза (ІІІ)', 1, 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (85, '2020-03-18 15:48:39.161596', 'Хлоридна кислота розбавлена (Реагент)', 2, 1, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (86, '2020-03-18 17:58:42.08735', 'Йод кристалічний', 2, 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (138, '2020-04-07 15:55:39.189422', '1-Нафтиламін', 3, 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (87, '2020-03-18 18:20:35.233556', 'Галова кислота', 2, 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (88, '2020-03-19 10:33:04.64491', 'Поліетиленгліколь', 2, 1, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (90, '2020-03-19 10:39:52.749282', 'ізопропіламін', 2, 1, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (93, '2020-03-19 11:41:30.12809', '4-диметиламінобензальдегід', 2, 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (109, '2020-04-07 14:17:33.276378', 'Піпетка мірна з градуювавнням (клас А) 50 мл (повний злив)', 3, 9, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (11, '2020-01-02 15:39:01.529732', 'Ацетонітрил', 2, 1, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (252, '2020-04-10 14:15:01.262026', 'Цинк хлорид', 3, 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (253, '2020-04-10 14:18:39.291098', 'Анілін', 3, 1, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (12, '2020-01-02 15:39:01.529732', 'Барій сульфат', 2, 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (3, '2020-01-02 15:39:01.529732', '1,4-Диоксан', 2, 1, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (4, '2020-01-02 15:39:01.529732', 'N, N - диметилформамід', 2, 1, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (116, '2020-04-07 14:40:35.767479', 'Циліндр мірний 1-2000-2', 3, 9, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (6, '2020-01-02 15:39:01.529732', 'Альдегід оцтовий', 2, 1, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (7, '2020-01-02 15:39:01.529732', 'Аміак 25%', 2, 1, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (8, '2020-01-02 15:39:01.529732', 'Амоній молібденовокислий', 2, 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (9, '2020-01-02 15:39:01.529732', 'Аргентум нітрат', 2, 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (13, '2020-01-02 15:39:01.529732', 'Барію хлорид', 2, 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (14, '2020-01-02 15:39:01.529732', 'Бензол', 2, 1, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (118, '2020-04-07 14:41:11.678451', 'Колба мірна КМ-1-1000-2 ХС', 3, 9, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (15, '2020-01-02 15:39:01.529732', 'Бутанол', 2, 1, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (119, '2020-04-07 14:41:25.455194', 'Колба мірна КМ-1-500-2 ХС', 3, 9, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (120, '2020-04-07 14:41:45.689113', 'Колба мірна КМ-1-100-2 ТС', 3, 9, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (122, '2020-04-07 14:42:06.665785', 'Колба мірна КМ-1-50-2 ТС', 3, 9, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (124, '2020-04-07 14:42:57.619121', 'Стакан високий з носиком і градуюванням В-1-250 ТС', 3, 9, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (16, '2020-01-02 15:39:01.529732', 'Ванілін', 2, 1, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (126, '2020-04-07 14:44:53.634798', 'Воронка лабораторна В-25-38 ТС', 3, 9, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (17, '2020-01-02 15:39:01.529732', 'Вісмут нітрат', 2, 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (128, '2020-04-07 15:16:36.487966', 'Алізарин', 3, 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (91, '2020-03-19 10:43:04.659486', '1,4-динітробензол', 3, 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (99, '2020-04-07 11:20:24.436048', 'Гексан', 3, 1, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (100, '2020-04-07 12:03:13.452631', 'Плавікова (фтороводнева) кислота', 3, 1, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (5, '2020-01-02 15:39:01.529732', 'Азотна (нітратна) кислота', 3, 1, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (101, '2020-04-07 13:56:07.159233', 'Воронка лабораторна B-150-230 ТС', 3, 9, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (129, '2020-04-07 15:26:10.841277', 'Гідроксиламін солянокислий', 3, 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (131, '2020-04-07 15:38:10.815295', 'Калій двохромовокислий', 3, 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (102, '2020-04-07 14:08:22.95967', 'Колба конічна КН-1-250-29/32 ТС з градуюванням', 3, 9, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (133, '2020-04-07 15:43:18.99065', 'Метиленовий синій', 3, 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (103, '2020-04-07 14:09:18.312054', 'Піпетка мірна (Мора) з однією міткою 2-2-2 мл', 3, 9, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (135, '2020-04-07 15:43:52.221984', 'Натрій гексанітрокобальтат, 0,5-водн.', 3, 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (105, '2020-04-07 14:10:19.676107', 'Піпетка мірна з градуювавнням 2-2-2-2 мл (повний злив)', 3, 9, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (107, '2020-04-07 14:11:08.117704', 'Піпетка мірна з градуювавнням 2-2-2-10 мл (повний злив)', 3, 9, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (18, '2020-01-02 15:39:01.529732', 'Гліцерин', 2, 1, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (136, '2020-04-07 15:52:59.34017', 'Натрій сірчистокислий', 3, 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (83, '2020-03-17 12:43:19.841877', 'Дистильована вода', 2, 1, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (19, '2020-01-02 15:39:01.529732', 'Дифенілкарбазон', 2, 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (92, '2020-03-19 11:06:13.688529', 'ацетат кобальту (ІІ)', 1, 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (111, '2020-04-07 14:18:07.574614', 'Пробірка з притертою пробкою 25 мл', 3, 9, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (139, '2020-04-07 16:06:14.901219', '8-Оксихінолін', 3, 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (141, '2020-04-07 16:08:44.760134', 'Пероксид водню 35%', 3, 1, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (143, '2020-04-07 16:09:47.31349', 'Ртуть (ІІ) сірчанокисла', 3, 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (81, '2020-03-16 22:23:10.617711', '1,2-динітробензол', 3, 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (147, '2020-04-07 16:37:53.933174', 'Фіксанал натрій гідроксид ПЕ, 0,1 Н', 3, 9, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (149, '2020-04-07 16:38:25.763858', 'Фіксанал соляної (хлоридної) кислоти 0,1 Н', 3, 9, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (150, '2020-04-07 16:46:42.807242', 'Цинк сірчанокислий, 7-водн.', 3, 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (151, '2020-04-07 16:51:42.502585', 'Амоній оцтовокислий (ацетат)', 3, 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (153, '2020-04-07 17:08:10.789344', 'Метиловий оранжевий', 3, 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (155, '2020-04-07 17:20:53.028185', 'Вазелінова олія', 3, 1, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (156, '2020-04-07 17:24:38.219001', 'Парафін нафтовий', 3, 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (89, '2020-03-19 10:39:07.096009', 'Літій гідроксид', 2, 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (26, '2020-01-02 15:39:01.529732', 'Калій гідроксид', 2, 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (27, '2020-01-02 15:39:01.529732', 'Калію йодид', 2, 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (28, '2020-01-02 15:39:01.529732', 'Кальцію хлорид б/в', 2, 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (29, '2020-01-02 15:39:01.529732', 'Кобальт тіоціонат', 2, 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (30, '2020-01-02 15:39:01.529732', 'Магній сульфат', 2, 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (31, '2020-01-02 15:39:01.529732', 'Меркурій (ІІ) хлорид', 2, 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (32, '2020-01-02 15:39:01.529732', 'Метанол', 2, 1, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (33, '2020-01-02 15:39:01.529732', 'Метилен хлористий', 2, 1, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (34, '2020-01-02 15:39:01.529732', 'Метилстеарат для ГХ', 2, 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (36, '2020-01-02 15:39:01.529732', 'Мурашина кислота', 2, 1, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (158, '2020-04-07 17:29:34.885205', 'Тимол', 3, 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (37, '2020-01-02 15:39:01.529732', 'Натрій ванадат', 2, 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (38, '2020-01-02 15:39:01.529732', 'Натрій гідрокарбонат', 2, 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (39, '2020-01-02 15:39:01.529732', 'Натрій гідроксид', 2, 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (40, '2020-01-02 15:39:01.529732', 'Натрій карбонат', 2, 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (41, '2020-01-02 15:39:01.529732', 'Натрій молібдат', 2, 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (42, '2020-01-02 15:39:01.529732', 'Натрій нітрит', 2, 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (43, '2020-01-02 15:39:01.529732', 'Натрій нітропрусид', 2, 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (44, '2020-01-02 15:39:01.529732', 'Натрій сульфат б/в', 2, 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (45, '2020-01-02 15:39:01.529732', 'Натрію хлорид', 2, 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (46, '2020-01-02 15:39:01.529732', 'Нафтол альфа', 2, 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (47, '2020-01-02 15:39:01.529732', 'н-Гексан', 2, 1, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (48, '2020-01-02 15:39:01.529732', 'Нінгідрин', 2, 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (49, '2020-01-02 15:39:01.529732', 'о-Ксилол', 2, 1, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (50, '2020-01-02 15:39:01.529732', 'Ортофосфорна кислота', 2, 1, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (51, '2020-01-02 15:39:01.529732', 'Оцтова кислота, льодяна', 2, 1, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (52, '2020-01-02 15:39:01.529732', 'п-Диметиламінобензальдегід', 2, 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (56, '2020-01-02 15:39:01.529732', 'Сульфанілова кислота', 3, 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (54, '2020-01-02 15:39:01.529732', 'Піридин', 2, 1, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (55, '2020-01-02 15:39:01.529732', 'Платина VI хлорид', 2, 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (57, '2020-01-02 15:39:01.529732', 'Сульфатна кислота концентрована', 2, 1, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (58, '2020-01-02 15:39:01.529732', 'Толуол', 2, 1, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (60, '2020-01-02 15:39:01.529732', 'Фенолфталеїн', 2, 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (61, '2020-01-02 15:39:01.529732', 'Ферум (ІІІ) хлорид', 2, 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (62, '2020-01-02 15:39:01.529732', 'Формальдегід', 2, 1, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (63, '2020-01-02 15:39:01.529732', 'Хлоридна кислота концентрована', 2, 1, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (64, '2020-01-02 15:39:01.529732', 'Хлороформ', 2, 1, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (104, '2020-04-07 14:09:36.33392', 'Піпетка мірна (Мора) з однією міткою 2-2-5 мл', 3, 9, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (106, '2020-04-07 14:10:33.319837', 'Піпетка мірна з градуювавнням 2-2-2-5 мл (повний злив)', 3, 9, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (108, '2020-04-07 14:16:54.367161', 'Піпетка мірна з градуювавнням 2-2-2-25 мл (повний злив)', 3, 9, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (110, '2020-04-07 14:17:54.142579', 'Колба конічна КН-1-50-14/23 ТС з градуюванням', 3, 9, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (112, '2020-04-07 14:18:26.685373', 'Циліндр мірний 1-10-2', 3, 9, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (114, '2020-04-07 14:18:58.561129', 'Колба круглодонна К-1-500-29/32 ТС', 3, 9, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (117, '2020-04-07 14:40:56.633385', 'Циліндр мірний 3-500-2', 3, 9, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (121, '2020-04-07 14:41:55.932974', 'Колба мірна КМ-1-250-2 ТС', 3, 9, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (123, '2020-04-07 14:42:42.185927', 'Пробка гумова до флакону пеніцилінового', 3, 9, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (125, '2020-04-07 14:44:22.970071', 'Стакан високий з носиком і градуюванням В-1-100 ТС', 3, 9, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (127, '2020-04-07 14:45:04.690687', 'Воронка лабораторна В-36-50 ТС', 3, 9, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (130, '2020-04-07 15:26:32.541169', 'Гідроксиламін сірчанокислий', 3, 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (132, '2020-04-07 15:38:30.369715', 'Калій хромовокислий', 3, 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (137, '2020-04-07 15:53:16.728547', 'Натрій сірчанокислий', 3, 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (140, '2020-04-07 16:08:17.594711', 'Пероксид водню 60%', 3, 1, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (142, '2020-04-07 16:08:52.472055', 'Пероксид водню 50%', 3, 1, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (144, '2020-04-07 16:13:05.193681', 'Срібло азотнокисле', 3, 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (146, '2020-04-07 16:37:43.50034', 'Фіксанал калій гідроксид ПЕ, 0,1 Н', 3, 9, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (148, '2020-04-07 16:38:12.998664', 'Фіксанал сірчаної (сульфатної) кислоти 0,1 Н', 3, 9, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (152, '2020-04-07 16:52:58.665474', 'Вазелін білий', 3, 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (134, '2020-04-07 15:43:34.98952', 'Мідь (ІІ) сульфат', 3, 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (154, '2020-04-07 17:16:58.382986', 'Метиловий червоний', 3, 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (157, '2020-04-07 17:29:20.373593', 'Пікринова кислота', 3, 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (159, '2020-04-07 17:29:39.806902', 'Тимолфталеїн', 3, 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (160, '2020-04-07 17:41:49.552188', 'Флакон пеніциліновий 10 мл', 3, 9, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (161, '2020-04-07 17:42:18.761341', 'Циліндр мірний 1-1000-2', 3, 9, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (162, '2020-04-07 17:42:31.182155', 'Воронка лабораторна B-100-150 ТС', 3, 9, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (163, '2020-04-07 17:42:45.426515', 'Воронка лабораторна B-75-110 ТС', 3, 9, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (164, '2020-04-07 17:42:55.315041', 'Воронка лабораторна B-56-80 ТС', 3, 9, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (165, '2020-04-09 09:19:52.7962', 'Калій марганцевокислий (перманганат)', 3, 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (166, '2020-04-09 09:26:56.684775', 'Пульверизатор скляний для ТШХ з грушею', 3, 9, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (169, '2020-04-09 12:05:58.964821', 'Кришки, що загвинчуються, 9 мм, септа PTFE/red silicone', 3, 9, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (170, '2020-04-09 12:06:11.908371', 'Маркер для надпису на склі', 3, 9, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (171, '2020-04-09 12:06:47.117751', 'Накінечник для дозаторів на 10 мкл', 3, 9, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (172, '2020-04-09 12:06:54.994581', 'Накінечник для дозаторів на 1000 мкл', 3, 9, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (173, '2020-04-09 12:07:37.903984', 'Пластини фірми "Сорбфіл" ПТСХ АФ-А 100*100', 3, 9, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (175, '2020-04-09 12:10:01.207508', 'Хлороформ для хроматографії', 3, 1, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (176, '2020-04-09 12:10:14.717966', 'Метанол для хроматографії', 3, 1, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (168, '2020-04-09 12:05:37.199314', 'Віали на 1,5 мл, під кришку, що загвинчується, прозоре скло', 3, 9, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (177, '2020-04-09 12:11:24.436478', 'Гексан для хроматографії', 3, 1, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (178, '2020-04-09 12:17:16.817598', 'ЕДТА (Етилендиамін-N,N,N;N;-тетраоцтова кислота) (Трилон БС)', 3, 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (179, '2020-04-09 13:20:56.330109', 'Циліндр Генера на 160 мл з краником', 3, 9, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (180, '2020-04-09 13:30:48.499437', 'Корок гумовий 19 мм', 3, 9, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (181, '2020-04-09 13:30:57.988016', 'Корок гумовий 24 мм', 3, 9, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (182, '2020-04-09 13:31:07.909363', 'Корок гумовий 29 мм', 3, 9, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (183, '2020-04-09 13:31:22.208571', 'Корок гумовий 34,5 мм', 3, 9, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (184, '2020-04-09 13:31:29.486679', 'Корок гумовий 40 мм', 3, 9, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (185, '2020-04-09 13:31:36.96349', 'Корок гумовий 45 мм', 3, 9, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (186, '2020-04-09 13:32:00.662133', 'Банка 250 світле скло, закрутка, мітки ТС', 3, 9, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (187, '2020-04-09 13:32:15.638934', 'Банка 500 світле скло, закрутка, мітки ТС', 3, 9, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (188, '2020-04-09 13:43:54.771545', 'Гептан', 3, 1, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (189, '2020-04-09 14:05:50.071627', 'Лакмус', 3, 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (190, '2020-04-09 14:09:15.993379', 'Папір індикаторний універсальний', 3, 9, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (191, '2020-04-09 14:11:38.820383', 'Віала на 1,5 мл з кришкою та септою', 3, 9, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (192, '2020-04-09 14:12:27.483558', 'Гелій підвищеної чистоти (99,999%)', 3, 1, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (193, '2020-04-09 14:12:51.672115', 'Мікровіала на 0,250 мл', 3, 9, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (194, '2020-04-09 14:13:03.64907', 'Піпетка Пастера 1 мл стерильна (поліетилен)', 3, 9, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (195, '2020-04-09 14:13:14.392996', 'Азур-Еозин по Романовському (розчин, чда)', 3, 1, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (196, '2020-04-09 14:46:46.857086', 'Скляний бюкс 35*70 мм', 3, 9, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (197, '2020-04-09 14:52:22.816605', 'Свинець оцтовокислий', 3, 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (198, '2020-04-09 14:53:30.079908', 'Калій залізосинєродистий (червона кровяна сіль)', 3, 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (199, '2020-04-09 14:57:51.610883', 'Барбітурова кислота', 3, 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (200, '2020-04-09 15:12:52.664766', 'Скляний бюкс ТС 25*40 мм', 3, 9, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (201, '2020-04-09 15:13:07.552699', 'Скляний бюкс ТС 30*50 мм', 3, 9, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (202, '2020-04-09 15:17:50.23803', 'Сахароза', 3, 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (203, '2020-04-09 15:18:10.646736', 'Крохмаль водорозчинний', 3, 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (204, '2020-04-09 15:18:39.790954', 'L-пролін', 3, 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (205, '2020-04-09 15:18:52.189436', 'р-Толуїдин', 3, 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (206, '2020-04-09 15:19:06.945606', 'Камера хроматографіна 10*10 см', 3, 9, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (207, '2020-04-09 15:20:02.463922', 'Калію хлорид', 3, 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (208, '2020-04-09 15:21:10.661681', 'Накінечник для дозаторів на 200 мкл з фільтром', 3, 9, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (209, '2020-04-09 15:35:59.784094', 'Етиленгліколь', 3, 1, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (210, '2020-04-09 15:44:22.280739', 'Натрій оцтовокислий 3-водн.', 3, 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (211, '2020-04-09 15:47:53.458324', '2,4-динітрофенол', 3, 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (212, '2020-04-09 15:59:12.201136', 'Етилацетат для хроматографії', 3, 1, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (213, '2020-04-09 16:28:26.836657', 'Бутилацетат (марка А)', 3, 1, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (214, '2020-04-09 16:28:38.19252', 'Бутилацетат', 3, 1, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (53, '2020-01-02 15:39:01.529732', 'Петролейний ефір (40-65)', 3, 1, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (215, '2020-04-09 17:04:02.905419', 'Петролейний ефір (80-110)', 3, 1, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (216, '2020-04-10 09:26:05.328257', 'Сульфатна кислота концентрована МЕРК', 3, 1, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (217, '2020-04-10 09:27:05.769414', 'Дифеніламін Мерк', 3, 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (218, '2020-04-10 09:27:21.080255', 'Балон для піпеток з трьома клапанами та перехідником', 3, 9, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (219, '2020-04-10 09:27:34.389864', 'Буферний розчин рН-4,01', 3, 9, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (221, '2020-04-10 09:28:07.900171', 'Йоршик для пробірок 20-25 мм', 3, 9, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (222, '2020-04-10 09:28:15.966537', 'Йоршик для пробірок 15 мм', 3, 9, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (224, '2020-04-10 09:33:58.051931', 'Октан', 3, 1, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (225, '2020-04-10 09:35:58.547571', 'Калій бромистий', 3, 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (226, '2020-04-10 10:09:10.230599', 'Накінечник для дозаторів на 200 мкл жовтий', 3, 9, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (227, '2020-04-10 10:57:34.195357', 'Мікропробірка Еппендорфа 1,5 мл', 3, 9, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (220, '2020-04-10 09:27:50.112313', 'Мікропробірка Епендорфа 0,5 мл', 3, 9, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (228, '2020-04-10 10:58:17.860513', 'Мікропробірка Амед 2,0 мл', 3, 9, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (229, '2020-04-10 10:58:36.326367', 'Скло покривне 18*18 мм', 3, 9, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (230, '2020-04-10 10:58:46.536301', 'Стакан високий з носиком і градуюванням В-1-50 ТС', 3, 9, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (231, '2020-04-10 10:58:57.092576', 'Ексикатор скляний без крану діаметром 240 мм', 3, 9, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (232, '2020-04-10 10:59:09.74763', 'Стакан високий з носиком і градуюванням В-1-500 ТС', 3, 9, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (233, '2020-04-10 10:59:18.279786', 'Затискач Мора 50 мм (металевий)', 3, 9, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (234, '2020-04-10 10:59:45.790335', 'Чашка випарювальна порцелянова 100 мл', 3, 9, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (235, '2020-04-10 10:59:52.179173', 'Чашка випарювальна порцелянова 50 мл', 3, 9, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (236, '2020-04-10 11:00:08.800507', 'Чашка випарювальна порцелянова 35 мл', 3, 9, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (237, '2020-04-10 11:00:17.100233', 'Чашка випарювальна порцелянова 25 мл', 3, 9, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (254, '2020-04-10 14:26:08.116848', 'Ацетонітрил для хроматографії', 3, 1, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (255, '2020-04-10 14:27:20.415585', 'Дихлорметан для хроматографії', 3, 1, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (256, '2020-04-10 14:35:38.301785', 'Амоній роданистий', 3, 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (257, '2020-04-10 14:36:03.610512', 'Бензидин гідрохлорид', 3, 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (258, '2020-04-10 14:54:12.110034', 'Бромтимоловий синій (водорозчинний)', 3, 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (259, '2020-04-10 14:54:37.196764', 'Калій вуглекислий (б/в)', 3, 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (260, '2020-04-10 15:10:36.096905', 'Гідразин солянокислий', 3, 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (261, '2020-04-10 15:18:53.049626', 'Винна кислота', 3, 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (262, '2020-04-10 15:20:47.256281', 'Фільтри лабораторні знезолені стрічка синя діаметром 150 мм', 3, 9, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (263, '2020-04-10 15:36:09.198999', 'Бензидин', 3, 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (264, '2020-04-10 15:50:40.141042', 'Калій хлорат (бертолетова сіль)', 3, 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (265, '2020-04-10 16:07:34.189621', 'Скляний бюкс ТС 50*30 мм', 3, 9, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (266, '2020-04-10 16:10:29.549645', 'Септа для 9 мм кришок, що загвинчуються', 3, 9, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (267, '2020-04-14 15:29:54.289746', 'Піпетка мірна з градуювавнням 2-2-2-0,2 мл (повний злив)', 3, 9, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (268, '2020-04-14 15:31:46.97469', 'Піпетка мірна (Мора) з однією міткою 2-2-1 мл', 3, 9, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (269, '2020-04-14 15:31:57.185954', 'Піпетка мірна (Мора) з однією міткою 2-2-10 мл', 3, 9, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (270, '2020-04-14 16:31:53.504347', 'Тигель порцеляновий низький з кришкою на 50 мл', 3, 9, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (271, '2020-04-17 10:16:40.737389', 'Натрій вуглекислий', 3, 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (272, '2020-04-17 11:16:18.63825', 'Амоній сірчанокислий', 3, 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (273, '2020-04-17 11:53:38.792595', 'Амоній вуглекислий', 3, 2, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (274, '2020-04-17 14:14:50.334598', 'Вуглець чотирихлористий', 3, 1, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (174, '2020-04-09 12:08:58.877455', 'Пластини фірми "Merck" Silica gel 60 F254 20*20 (aluminium)', 3, 9, 1);
INSERT INTO "public"."reagent" ("id", "ts", "name", "created_by_expert_id", "units_id", "group_id") VALUES (276, '2020-06-09 16:21:41.316593', 'Пластини фірми "Merck" Silica gel 60 F254 20*20 (plastic)', 3, 9, 1);


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
INSERT INTO "public"."region" ("id", "ts", "name", "position") VALUES (2, '2020-07-02 16:35:12.8155', 'Харківська область', 0);


--
-- Data for Name: spr_access_actions; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO "public"."spr_access_actions" ("id", "label", "name") VALUES (0, '', '--');
INSERT INTO "public"."spr_access_actions" ("id", "label", "name") VALUES (1, 'stock:view', 'Склад реактивів: перегляд');
INSERT INTO "public"."spr_access_actions" ("id", "label", "name") VALUES (2, 'stock:edit', 'Склад реактивів: редагування');
INSERT INTO "public"."spr_access_actions" ("id", "label", "name") VALUES (3, 'dispersion:view', 'Лабораторія: перегляд');
INSERT INTO "public"."spr_access_actions" ("id", "label", "name") VALUES (4, 'dispersion:edit', 'Лабораторія: редагування');
INSERT INTO "public"."spr_access_actions" ("id", "label", "name") VALUES (5, 'cooked:view', 'Приготування реактивів: перегляд');
INSERT INTO "public"."spr_access_actions" ("id", "label", "name") VALUES (6, 'cooked:edit', 'Приготування реактивів: редагування');
INSERT INTO "public"."spr_access_actions" ("id", "label", "name") VALUES (7, 'using:view', 'Використання реактивів: перегляд');
INSERT INTO "public"."spr_access_actions" ("id", "label", "name") VALUES (8, 'using:edit', 'Використання реактивів: редагування');
INSERT INTO "public"."spr_access_actions" ("id", "label", "name") VALUES (9, 'spr:edit', 'Довідники: редагування');
INSERT INTO "public"."spr_access_actions" ("id", "label", "name") VALUES (10, 'users:edit', 'Користувачі: редагування');
INSERT INTO "public"."spr_access_actions" ("id", "label", "name") VALUES (11, 'users:access', 'Користувачі: редагування доступу');
INSERT INTO "public"."spr_access_actions" ("id", "label", "name") VALUES (12, 'stats:view', 'Статистика: перегляд');
INSERT INTO "public"."spr_access_actions" ("id", "label", "name") VALUES (13, 'admin:change_ndekc', 'Адміністрування: зміна центру');
INSERT INTO "public"."spr_access_actions" ("id", "label", "name") VALUES (14, 'admin:change_lab', 'Адміністрування: зміна лабораторії');
INSERT INTO "public"."spr_access_actions" ("id", "label", "name") VALUES (15, 'admin:access', 'Адміністрування: зміна режимів доступу');
INSERT INTO "public"."spr_access_actions" ("id", "label", "name") VALUES (16, 'users:lab', 'Користувачі: редагування лабораторії');


--
-- Data for Name: stock; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (27, '2020-04-07 14:07:20.605885', 101, 2, '2016-04-01', 3, 1, 2, 1, '2015-01-20', '2025-01-20', 1, '', 4, 6, 1, '', 'лабораторія 317', 'В сухому захищеному від пошкодження місці', '2020-04-07 14:07:20.605885', '8-2016', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0011571', '2016-04-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (31, '2020-04-07 14:33:38.395216', 106, 2, '2016-04-01', 3, 1, 2, 1, '2015-01-20', '2025-01-20', 0, '', 4, 6, 1, '', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-07 14:33:38.395216', '12-2016', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0011571', '2016-04-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (26, '2020-04-07 12:26:10.400873', 57, 2500, '2016-03-31', 3, 1, 0, 9, '2016-02-15', '2021-03-30', 0, '', 1, 5, 1, '(МЕРК) 95-97%', 'лабораторія 317', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-07 12:26:10.400873', '7-2016', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0012078', '2016-03-31');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (21, '2020-04-07 11:28:26.356087', 99, 4000, '2016-03-14', 3, 1, 3000, 8, '2016-03-01', '2021-03-01', 1, '', 1, 5, 1, 'розчин (4 пляшок)', 'Лабораторія 317, Шафа для реактивів в к.318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-07 11:28:26.356087', '2-2016', 'Сфера СІМ', 'РН-01884', '2016-03-14');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (28, '2020-04-07 14:23:56.09256', 103, 12, '2016-04-01', 3, 1, 12, 1, '2015-01-20', '2025-01-20', 0, '', 4, 6, 1, '', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-07 14:23:56.09256', '9-2016', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0011571', '2016-04-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (23, '2020-04-07 12:04:39.369609', 100, 9000, '2016-03-28', 3, 1, 9000, 8, '2015-04-01', '2021-04-01', 1, '', 1, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-07 12:04:39.369609', '4-2016', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№ 495', '2016-03-28');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (0, '2020-01-02 15:37:14.580544', 0, 0, '2020-01-01', 0, 0, 0, 0, '1970-01-01', '1970-01-01', 0, '', 0, 0, 0, '', '', '', '2020-03-12 09:48:19.879959', '0-0', '', '', '1970-01-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (22, '2020-04-07 11:59:02.539443', 50, 2000, '2016-03-28', 3, 1, 2000, 1, '2015-09-01', '2021-03-01', 1, '', 1, 5, 1, 'Прозора рідина в 4 пляшках (по 1.0 л)', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-07 11:59:02.539443', '3-2016', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№495', '2016-03-28');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (30, '2020-04-07 14:31:42.401235', 105, 2, '2016-04-01', 3, 1, 2, 1, '2015-01-20', '2025-01-20', 0, '', 4, 6, 1, '', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-07 14:31:42.401235', '11-2016', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0011571', '2016-04-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (32, '2020-04-07 14:35:13.246786', 109, 4, '2016-04-01', 3, 1, 4, 1, '2015-01-20', '2025-01-20', 0, '', 4, 6, 1, '', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-07 14:35:13.246786', '13-2016', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0011571', '2016-04-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (24, '2020-04-07 12:09:34.710777', 5, 2000, '2016-03-28', 3, 1, 2000, 9, '2016-02-01', '2020-10-31', 0, '', 1, 5, 1, '(МЕРК) 65%', 'лабораторія 317', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-07 12:09:34.710777', '5-2016', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№ 495', '2016-03-28');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (33, '2020-04-07 14:36:49.84224', 112, 2, '2016-04-01', 3, 1, 2, 1, '2015-01-20', '2025-01-20', 0, '', 4, 6, 1, '', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-07 14:36:49.84224', '14-2016', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0011571', '2016-04-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (34, '2020-04-07 14:38:30.448822', 114, 3, '2016-04-01', 3, 1, 3, 1, '2015-01-20', '2025-01-20', 0, '', 4, 6, 1, '', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-07 14:38:30.448822', '15-2016', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0011571', '2016-04-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (35, '2020-04-07 14:46:40.87389', 117, 1, '2016-04-01', 3, 1, 1, 1, '2015-01-20', '2025-01-20', 0, '', 4, 6, 1, '', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-07 14:46:40.87389', '16-2016', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0011571', '2016-04-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (36, '2020-04-07 14:48:21.145929', 118, 2, '2016-04-01', 3, 1, 2, 1, '2015-01-20', '2025-01-20', 0, '', 4, 6, 1, '', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-07 14:48:21.145929', '17-2016', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0011571', '2016-04-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (37, '2020-04-07 14:49:24.131686', 119, 2, '2016-04-01', 3, 1, 2, 1, '2015-01-20', '2025-01-20', 0, '', 4, 6, 1, '', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-07 14:49:24.131686', '18-2016', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0011571', '2016-04-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (38, '2020-04-07 14:50:34.217215', 120, 4, '2016-04-01', 3, 1, 4, 1, '2015-01-20', '2025-01-20', 0, '', 4, 6, 1, '', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-07 14:50:34.217215', '19-2016', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0011571', '2016-04-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (29, '2020-04-07 14:26:14.451686', 104, 10, '2016-04-01', 3, 1, 10, 1, '2015-01-20', '2025-01-20', 0, '', 4, 6, 1, '', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-07 14:26:14.451686', '10-2016', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0011571', '2016-04-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (25, '2020-04-07 12:11:47.104727', 51, 6000, '2016-03-28', 3, 1, 5000, 7, '2015-09-01', '2020-09-01', 1, '', 1, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-07 12:11:47.104727', '6-2016', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№ 495', '2016-03-28');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (46, '2020-04-07 15:28:04.956658', 129, 500, '2016-04-04', 3, 1, 500, 7, '2015-12-01', '2020-12-01', 1, '', 2, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-07 15:28:04.956658', '27-2016', 'Сфера СІМ', '№РН-04122', '2016-04-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (51, '2020-04-07 15:44:51.983584', 133, 20, '2016-04-04', 3, 1, 20, 7, '2015-11-01', '2021-05-01', 1, '', 2, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-07 15:44:51.983584', '32-2016', 'Сфера СІМ', '№РН-04122', '2016-04-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (40, '2020-04-07 14:54:01.629548', 123, 400, '2016-04-01', 3, 1, 400, 1, '2015-01-20', '2025-01-20', 0, '', 4, 6, 1, '', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-07 14:54:01.629548', '21-2016', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0011571', '2016-04-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (41, '2020-04-07 14:56:35.888848', 126, 2, '2016-04-01', 3, 1, 2, 1, '2015-01-20', '2025-01-20', 1, '', 4, 6, 1, '', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-07 14:56:35.888848', '22-2016', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0011571', '2016-04-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (42, '2020-04-07 14:57:38.185797', 127, 2, '2016-04-01', 3, 1, 2, 1, '2015-01-20', '2025-01-20', 1, '', 4, 6, 1, '', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-07 14:57:38.185797', '23-2016', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0011571', '2016-04-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (43, '2020-04-07 15:18:04.914966', 128, 100, '2016-04-04', 3, 1, 100, 7, '2016-03-01', '2020-09-01', 1, '', 2, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-07 15:18:04.914966', '24-2016', 'Сфера СІМ', '№РН-04122', '2016-04-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (44, '2020-04-07 15:20:18.031106', 8, 50, '2016-04-04', 3, 1, 50, 8, '2016-02-01', '2020-08-01', 1, '', 2, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-07 15:20:18.031106', '25-2016', 'Сфера СІМ', '№РН-04122', '2016-04-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (47, '2020-04-07 15:29:40.540673', 19, 50, '2016-04-04', 3, 1, 50, 7, '2015-10-01', '2021-06-01', 1, '', 2, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-07 15:29:40.540673', '28-2016', 'Сфера СІМ', '№РН-04122', '2016-04-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (52, '2020-04-07 15:47:17.675812', 134, 400, '2016-04-04', 3, 1, 400, 7, '2016-03-01', '2020-09-01', 1, '', 2, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-07 15:47:17.675812', '33-2016', 'Сфера СІМ', '№РН-04122', '2016-04-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (50, '2020-04-07 15:41:00.972129', 132, 1000, '2016-04-04', 3, 1, 1000, 8, '2015-12-01', '2020-12-01', 1, '', 2, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-07 15:41:00.972129', '31-2016', 'Сфера СІМ', '№РН-04122', '2016-04-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (59, '2020-04-07 16:19:23.107373', 56, 500, '2016-04-04', 3, 1, 400, 7, '2016-02-01', '2021-02-01', 1, '', 2, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-07 16:19:23.107373', '40-2016', 'Сфера СІМ', '№РН-04122', '2016-04-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (54, '2020-04-07 15:54:12.79237', 136, 800, '2016-04-04', 3, 1, 800, 7, '2016-03-01', '2021-03-01', 1, '', 2, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-07 15:54:12.79237', '35-2016', 'Сфера СІМ', '№РН-04122', '2016-04-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (49, '2020-04-07 15:39:45.131441', 131, 9000, '2016-04-04', 3, 1, 8000, 8, '2016-01-01', '2021-09-01', 1, '', 2, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-07 15:39:45.131441', '30-2016', 'Сфера СІМ', '№РН-04122', '2016-04-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (56, '2020-04-07 16:07:23.074711', 139, 100, '2016-04-04', 3, 1, 100, 7, '2016-03-01', '2020-09-01', 1, '', 2, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-07 16:07:23.074711', '37-2016', 'Сфера СІМ', '№РН-04122', '2016-04-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (57, '2020-04-07 16:12:16.19492', 143, 50, '2016-04-04', 3, 1, 50, 7, '2016-03-01', '2020-09-01', 1, '', 2, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-07 16:12:16.19492', '38-2016', 'Сфера СІМ', '№РН-04122', '2016-04-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (39, '2020-04-07 14:51:41.236859', 121, 4, '2016-04-01', 3, 1, 4, 1, '2015-01-20', '2025-01-20', 0, '', 4, 6, 1, '', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-07 14:51:41.236859', '20-2016', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0011571', '2016-04-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (58, '2020-04-07 16:17:15.625372', 144, 50, '2016-04-04', 3, 1, 50, 7, '2016-03-01', '2021-03-01', 1, '', 2, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-07 16:17:15.625372', '39-2016', 'Сфера СІМ', '№РН-04122', '2016-04-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (53, '2020-04-07 15:48:32.483153', 135, 100, '2016-04-04', 3, 1, 0, 7, '2016-01-01', '2021-09-01', 1, '', 2, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-07 15:48:32.483153', '34-2016', 'Сфера СІМ', '№РН-04122', '2016-04-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (45, '2020-04-07 15:21:59.106707', 8, 200, '2016-04-04', 3, 1, 200, 7, '2016-03-01', '2021-03-01', 1, '', 2, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-07 15:21:59.106707', '26-2016', 'Сфера СІМ', '№РН-04122', '2016-04-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (60, '2020-04-07 16:40:08.546274', 145, 5, '2016-04-04', 3, 1, 5, 2, '2015-05-01', '2022-05-01', 1, '', 2, 5, 1, '', 'лабораторія к. 317', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-07 16:40:08.546274', '41-2016', 'Сфера СІМ', '№РН-04122', '2016-04-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (62, '2020-04-07 16:42:33.495558', 147, 5, '2016-04-04', 3, 1, 5, 2, '2016-03-01', '2022-03-01', 1, '', 2, 5, 1, '', 'лабораторія к. 317', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-07 16:42:33.495558', '43-2016', 'Сфера СІМ', '№РН-04122', '2016-04-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (66, '2020-04-07 16:56:29.852527', 151, 1000, '2016-04-06', 3, 1, 1000, 8, '2016-03-01', '2020-09-01', 1, '', 2, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-07 16:56:29.852527', '47-2016', 'Сфера СІМ', '№РН-04444', '2016-04-06');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (63, '2020-04-07 16:43:42.714447', 148, 5, '2016-04-04', 3, 1, 5, 2, '2016-02-01', '2023-02-01', 1, '', 1, 5, 1, '', 'лабораторія к. 317', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-07 16:43:42.714447', '44-2016', 'Сфера СІМ', '№РН-04122', '2016-04-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (64, '2020-04-07 16:44:51.556009', 149, 5, '2016-04-04', 3, 1, 5, 2, '2016-02-01', '2026-02-01', 1, '', 1, 5, 1, '', 'лабораторія к. 317', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-07 16:44:51.556009', '45-2016', 'Сфера СІМ', '№РН-04122', '2016-04-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (65, '2020-04-07 16:50:04.572352', 150, 100, '2016-04-04', 3, 1, 100, 7, '2016-03-01', '2020-09-01', 1, '', 2, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-07 16:50:04.572352', '46-2016', 'Сфера СІМ', '№РН-04122', '2016-04-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (67, '2020-04-07 16:58:06.335822', 152, 4000, '2016-04-06', 3, 1, 4000, 11, '2016-01-03', '2022-01-03', 1, '', 2, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-07 16:58:06.335822', '48-2016', 'Сфера СІМ', '№РН-04444', '2016-04-06');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (69, '2020-04-07 17:06:43.400915', 27, 1000, '2016-04-06', 3, 1, 0, 11, '2016-03-01', '2021-03-01', 1, '', 2, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-07 17:06:43.400915', '50-2016', 'Сфера СІМ', '№РН-04444', '2016-04-06');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (70, '2020-04-07 17:09:40.238525', 153, 10, '2016-04-06', 3, 1, 10, 7, '2015-07-01', '2020-11-01', 1, '', 2, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-07 17:09:40.238525', '51-2016', 'Сфера СІМ', '№РН-04444', '2016-04-06');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (73, '2020-04-07 17:22:05.548014', 155, 2000, '2016-04-06', 3, 1, 2000, 11, '2015-06-01', '2020-12-01', 1, '', 1, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-07 17:22:05.548014', '54-2016', 'Сфера СІМ', '№РН-04444', '2016-04-06');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (71, '2020-04-07 17:18:25.755861', 154, 10, '2016-04-06', 3, 1, 10, 7, '2015-12-01', '2021-08-01', 1, '', 2, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-07 17:18:25.755861', '52-2016', 'Сфера СІМ', '№РН-04444', '2016-04-06');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (76, '2020-04-07 17:33:23.816878', 158, 100, '2016-04-06', 3, 1, 100, 2, '2016-02-01', '2020-08-01', 1, '', 2, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-07 17:33:23.816878', '57-2016', 'Сфера СІМ', '№РН-04444', '2016-04-06');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (72, '2020-04-07 17:19:57.81801', 46, 100, '2016-04-06', 3, 1, 100, 7, '2015-12-01', '2021-08-01', 1, '', 2, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-07 17:19:57.81801', '53-2016', 'Сфера СІМ', '№РН-04444', '2016-04-06');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (75, '2020-04-07 17:31:32.500673', 157, 50, '2016-04-06', 3, 1, 50, 2, '2016-01-01', '2021-09-01', 1, '', 2, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-07 17:31:32.500673', '56-2016', 'Сфера СІМ', '№РН-04444', '2016-04-06');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (77, '2020-04-07 17:35:05.37929', 159, 30, '2016-04-06', 3, 1, 30, 7, '2016-03-01', '2020-09-01', 1, '', 2, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-07 17:35:05.37929', '58-2016', 'Сфера СІМ', '№РН-04444', '2016-04-06');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (78, '2020-04-07 17:36:51.307268', 138, 100, '2016-04-06', 3, 1, 100, 7, '2016-03-01', '2021-03-01', 1, '', 2, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-07 17:36:51.307268', '59-2016', 'Сфера СІМ', '№РН-04444', '2016-04-06');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (68, '2020-04-07 17:01:17.793885', 61, 4000, '2016-04-06', 3, 1, 3000, 2, '2016-03-01', '2020-09-01', 1, '', 2, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-07 17:01:17.793885', '49-2016', 'Сфера СІМ', '№РН-04444', '2016-04-06');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (79, '2020-04-07 17:40:08.209606', 56, 500, '2016-04-06', 3, 1, 500, 7, '2016-02-01', '2020-12-01', 1, '', 2, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-07 17:40:08.209606', '60-2016', 'Сфера СІМ', '№РН-04444', '2016-04-06');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (80, '2020-04-09 09:12:20.912667', 161, 2, '2016-04-01', 3, 1, 2, 1, '2015-01-20', '2025-01-20', 0, '', 4, 6, 1, '', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-09 09:12:20.912667', '61-2016', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0011571', '2016-04-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (61, '2020-04-07 16:41:31.199469', 146, 5, '2016-04-04', 3, 1, 5, 2, '2015-09-01', '2022-09-01', 1, '', 2, 5, 1, '', 'лабораторія к. 317', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-07 16:41:31.199469', '42-2016', 'Сфера СІМ', '№РН-04122', '2016-04-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (97, '2020-04-09 13:33:25.422899', 162, 8, '2017-05-04', 3, 1, 8, 1, '2017-03-30', '2027-03-30', 0, '', 4, 6, 1, '', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-09 13:33:25.422899', '6-2017', 'Сфера СІМ', '№СФ-07280', '2017-05-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (98, '2020-04-09 13:35:09.507535', 180, 30, '2017-05-04', 3, 1, 30, 1, '2017-03-30', '2027-03-30', 0, '', 4, 6, 1, '', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-09 13:35:09.507535', '7-2017', 'Сфера СІМ', '№СФ-07280', '2017-05-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (99, '2020-04-09 13:35:39.705846', 181, 30, '2017-05-04', 3, 1, 30, 1, '2017-03-30', '2027-03-30', 0, '', 4, 6, 1, '', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-09 13:35:39.705846', '8-2017', 'Сфера СІМ', '№СФ-07280', '2017-05-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (100, '2020-04-09 13:36:10.337698', 182, 30, '2017-05-04', 3, 1, 30, 1, '2017-03-30', '2027-03-30', 0, '', 4, 6, 1, '', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-09 13:36:10.337698', '9-2017', 'Сфера СІМ', '№СФ-07280', '2017-05-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (101, '2020-04-09 13:36:50.180227', 183, 10, '2017-05-04', 3, 1, 10, 1, '2017-03-30', '2027-03-30', 0, '', 4, 6, 1, '', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-09 13:36:50.180227', '10-2017', 'Сфера СІМ', '№СФ-07280', '2017-05-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (102, '2020-04-09 13:39:13.696724', 184, 10, '2017-05-04', 3, 1, 10, 1, '2017-03-30', '2027-03-30', 0, '', 4, 6, 1, '', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-09 13:39:13.696724', '11-2017', 'Сфера СІМ', '№СФ-07280', '2017-05-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (103, '2020-04-09 13:39:52.361329', 185, 10, '2017-05-04', 3, 1, 10, 1, '2017-03-30', '2027-03-30', 0, '', 4, 6, 1, '', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-09 13:39:52.361329', '12-2017', 'Сфера СІМ', '№СФ-07280', '2017-05-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (85, '2020-04-09 09:25:04.776397', 14, 2000, '2016-09-07', 3, 1, 1000, 7, '2016-08-01', '2021-02-01', 1, '', 1, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-09 09:25:04.776397', '66-2016', 'Сфера СІМ', '№РН-12870', '2016-09-07');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (82, '2020-04-09 09:13:54.975473', 163, 1, '2016-04-01', 3, 1, 1, 1, '2015-01-20', '2025-01-20', 1, '', 4, 6, 1, '', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-09 09:13:54.975473', '63-2016', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0011571', '2016-04-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (83, '2020-04-09 09:14:28.607363', 164, 2, '2016-04-01', 3, 1, 2, 1, '2015-01-20', '2025-01-20', 1, '', 4, 6, 1, '', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-09 09:14:28.607363', '64-2016', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0011571', '2016-04-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (87, '2020-04-09 09:28:59.523024', 21, 1000, '2016-09-09', 3, 1, 0, 11, '2015-08-01', '2021-10-01', 0, '', 1, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-09 09:28:59.523024', '68-2016', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0039331', '2016-09-09');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (89, '2020-04-09 12:03:02.072428', 10, 2000, '2016-12-05', 3, 1, 2000, 7, '2016-07-01', '2020-10-01', 1, '', 1, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-09 12:03:02.072428', '70-2016', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0054476', '2016-12-05');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (86, '2020-04-09 09:27:43.18168', 166, 2, '2016-09-07', 3, 1, 2, 1, '2015-01-20', '2025-01-20', 0, '', 4, 6, 1, '', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-09 09:27:43.18168', '67-2016', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№РН-12861', '2016-09-07');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (91, '2020-04-09 12:18:20.290294', 178, 1000, '2016-12-05', 3, 1, 1000, 8, '2016-05-01', '2021-05-01', 1, '', 2, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-09 12:18:20.290294', '72-2016', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№РН-19294', '2016-12-05');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (90, '2020-04-09 12:15:19.488423', 167, 4, '2016-12-08', 3, 1, 4, 1, '2015-01-20', '2025-01-20', 0, '', 4, 6, 1, '', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-09 12:15:19.488423', '71-2016', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№426', '2016-12-08');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (92, '2020-04-09 13:22:07.52569', 58, 2000, '2017-05-01', 3, 1, 2000, 7, '2017-03-01', '2020-09-01', 1, '', 1, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-09 13:22:07.52569', '1-2017', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0018647', '2017-05-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (84, '2020-04-09 09:21:17.325851', 165, 14000, '2016-07-14', 3, 1, 13000, 11, '2016-02-01', '2021-02-01', 1, '', 2, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-09 09:21:17.325851', '65-2016', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0029174', '2016-07-14');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (93, '2020-04-09 13:23:09.078762', 21, 2000, '2017-05-04', 3, 1, 1000, 11, '2017-03-01', '2021-09-01', 1, '', 1, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-09 13:23:09.078762', '2-2017', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0018647', '2017-05-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (94, '2020-04-09 13:24:25.230106', 57, 4000, '2017-05-04', 3, 1, 2000, 8, '2017-03-01', '2021-08-01', 1, '', 1, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-09 13:24:25.230106', '3-2017', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0018647', '2017-05-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (96, '2020-04-09 13:29:18.269615', 171, 2000, '2017-05-04', 3, 1, 2000, 1, '2017-03-30', '2027-03-30', 0, '', 4, 6, 1, '', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-09 13:29:18.269615', '5-2017', 'Сфера СІМ', '№СФ-07280', '2017-05-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (105, '2020-04-09 13:45:28.967249', 14, 1000, '2017-05-04', 3, 1, 1000, 7, '2016-11-01', '2020-11-01', 1, '', 1, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-09 13:45:28.967249', '14-2017', 'Сфера СІМ', '№СФ-07467', '2017-05-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (110, '2020-04-09 14:01:02.573613', 65, 1000, '2017-05-04', 3, 1, 1000, 7, '2016-01-01', '2021-01-02', 1, '', 1, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-09 14:01:02.573613', '19-2017', 'Сфера СІМ', '№Х0019816', '2017-05-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (107, '2020-04-09 13:49:40.586847', 18, 2000, '2017-05-04', 3, 1, 2000, 11, '2017-04-01', '2021-04-01', 1, '', 1, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-09 13:49:40.586847', '16-2017', 'Сфера СІМ', '№СФ-07467', '2017-05-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (108, '2020-04-09 13:55:47.812069', 155, 2000, '2017-05-04', 3, 1, 2000, 11, '2017-01-01', '2021-01-02', 1, '', 1, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-09 13:55:47.812069', '17-2017', 'Сфера СІМ', '№СФ-07467', '2017-05-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (109, '2020-04-09 13:59:40.888994', 145, 5, '2017-05-04', 3, 1, 5, 7, '2014-04-01', '2021-04-01', 1, '', 2, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-09 13:59:40.888994', '18-2017', 'Сфера СІМ', '№СФ-07467', '2017-05-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (115, '2020-04-09 14:16:12.981853', 48, 400, '2017-09-25', 3, 1, 400, 7, '2017-01-25', '2020-07-25', 1, '', 2, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-09 14:16:12.981853', '24-2017', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0046369', '2017-09-25');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (112, '2020-04-09 14:07:00.577002', 189, 50, '2017-06-02', 3, 1, 50, 7, '2017-04-01', '2020-07-01', 0, '', 2, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-09 14:07:00.577002', '21-2017', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0024870', '2017-06-02');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (113, '2020-04-09 14:10:11.48926', 190, 500, '2017-06-02', 3, 1, 500, 1, '2017-03-30', '2027-03-30', 0, '', 4, 6, 1, '', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-09 14:10:11.48926', '22-2017', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0024870', '2017-06-02');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (114, '2020-04-09 14:14:45.797554', 126, 4, '2017-06-02', 3, 1, 4, 1, '2017-03-30', '2027-03-30', 0, '', 4, 6, 1, '', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-09 14:14:45.797554', '23-2017', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0024870', '2017-06-02');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (120, '2020-04-09 14:31:04.335791', 57, 12000, '2017-11-30', 3, 1, 12000, 8, '2017-11-01', '2020-11-01', 1, '', 1, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-09 14:31:04.335791', '29-2017', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0076913', '2017-11-30');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (117, '2020-04-09 14:27:08.537654', 191, 300, '2017-10-27', 3, 1, 300, 1, '2017-03-30', '2027-03-30', 0, '', 4, 6, 1, '', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-09 14:27:08.537654', '26-2017', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0046369', '2017-10-27');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (118, '2020-04-09 14:28:54.542809', 58, 2000, '2017-11-30', 3, 1, 2000, 7, '2017-07-01', '2020-07-02', 1, '', 1, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-09 14:28:54.542809', '27-2017', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0076913', '2017-11-30');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (122, '2020-04-09 14:54:29.642096', 197, 1000, '2017-12-04', 3, 1, 1000, 7, '2017-05-01', '2020-11-01', 1, '', 2, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-09 14:54:29.642096', '31-2017', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0059681', '2017-12-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (116, '2020-04-09 14:21:51.286525', 20, 800, '2017-09-25', 3, 1, 800, 7, '2016-12-10', '2020-12-10', 1, '', 1, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-09 14:21:51.286525', '25-2017', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0046369', '2017-09-25');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (123, '2020-04-09 14:55:27.472514', 178, 1000, '2017-12-04', 3, 1, 1000, 7, '2017-07-01', '2020-07-01', 1, '', 2, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-09 14:55:27.472514', '32-2017', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0059681', '2017-12-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (124, '2020-04-09 14:56:24.136342', 150, 200, '2017-12-04', 3, 1, 200, 8, '2016-12-01', '2021-06-01', 1, '', 2, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-09 14:56:24.136342', '33-2017', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0059681', '2017-12-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (121, '2020-04-09 14:32:04.778502', 63, 10000, '2017-11-30', 3, 1, 9000, 8, '2017-11-01', '2020-11-01', 1, '', 1, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-09 14:32:04.778502', '30-2017', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0076913', '2017-11-30');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (125, '2020-04-09 14:58:29.173799', 199, 100, '2017-12-04', 3, 1, 100, 2, '2015-08-01', '2021-08-01', 1, '', 2, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-09 14:58:29.173799', '34-2017', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0059681', '2017-12-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (106, '2020-04-09 13:46:37.496588', 178, 1000, '2017-05-04', 3, 1, 1000, 7, '2017-01-01', '2020-07-02', 1, '', 2, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-09 13:46:37.496588', '15-2017', 'Сфера СІМ', '№СФ-07467', '2017-05-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (146, '2020-04-09 16:00:03.986051', 212, 10000, '2017-12-04', 3, 1, 7500, 9, '2017-09-04', '2020-09-30', 1, '', 1, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-09 16:00:03.986051', '55-2017', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0059686', '2017-12-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (133, '2020-04-09 15:30:32.931901', 188, 2000, '2017-12-04', 3, 1, 2000, 2, '2017-05-01', '2021-05-01', 1, '', 1, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-09 15:30:32.931901', '42-2017', 'Сфера СІМ', '№РН-17718', '2017-12-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (128, '2020-04-09 15:11:20.723332', 175, 3000, '2017-12-04', 3, 1, 3000, 9, '2017-03-24', '2021-09-30', 1, '', 1, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-09 15:11:20.723332', '37-2017', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0059681', '2017-12-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (127, '2020-04-09 14:59:50.069975', 36, 2000, '2017-12-04', 3, 1, 2000, 2, '2017-09-01', '2020-09-01', 1, '', 2, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-09 14:59:50.069975', '36-2017', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0059681', '2017-12-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (136, '2020-04-09 15:36:54.946433', 209, 2000, '2017-12-04', 3, 1, 2000, 2, '2017-11-01', '2020-11-01', 1, '', 1, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-09 15:36:54.946433', '45-2017', 'Сфера СІМ', '№РН-17718', '2017-12-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (129, '2020-04-09 15:14:27.568964', 200, 10, '2017-12-04', 3, 1, 10, 1, '2017-03-30', '2027-03-30', 0, '', 4, 6, 1, '', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-09 15:14:27.568964', '38-2017', 'Сфера СІМ', '№РН-17697', '2017-12-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (130, '2020-04-09 15:15:01.167613', 201, 10, '2017-12-04', 3, 1, 10, 1, '2017-03-30', '2027-03-30', 0, '', 4, 6, 1, '', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-09 15:15:01.167613', '39-2017', 'Сфера СІМ', '№РН-17697', '2017-12-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (132, '2020-04-09 15:21:31.747916', 208, 1500, '2017-12-04', 3, 1, 1500, 1, '2017-03-30', '2027-03-30', 0, '', 4, 6, 1, '', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-09 15:21:31.747916', '41-2017', 'Сфера СІМ', '№РН-17697', '2017-12-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (134, '2020-04-09 15:32:17.40475', 153, 120, '2017-12-04', 3, 1, 120, 7, '2017-11-01', '2020-11-01', 1, '', 2, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-09 15:32:17.40475', '43-2017', 'Сфера СІМ', '№РН-17718', '2017-12-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (138, '2020-04-09 15:41:28.566112', 202, 3000, '2017-12-04', 3, 1, 3000, 7, '2017-10-01', '2020-10-01', 1, '', 2, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-09 15:41:28.566112', '47-2017', 'Сфера СІМ', '№РН-17718', '2017-12-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (137, '2020-04-09 15:38:21.741368', 198, 3000, '2017-12-04', 3, 1, 3000, 2, '2017-05-01', '2021-05-01', 1, '', 2, 5, 1, '3 уп. з червоною порошкоподібною речовиною по 1.0 кг', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-09 15:38:21.741368', '46-2017', 'Сфера СІМ', '№РН-17718', '2017-12-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (141, '2020-04-09 15:47:07.770281', 45, 2000, '2017-12-04', 3, 1, 2000, 7, '2017-11-01', '2020-11-01', 1, '', 2, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-09 15:47:07.770281', '50-2017', 'Сфера СІМ', '№РН-17718', '2017-12-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (139, '2020-04-09 15:43:10.171664', 203, 3000, '2017-12-04', 3, 1, 3000, 7, '2017-07-01', '2020-07-01', 1, '', 2, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-09 15:43:10.171664', '48-2017', 'Сфера СІМ', '№РН-17718', '2017-12-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (140, '2020-04-09 15:45:37.386097', 210, 2000, '2017-12-04', 3, 1, 2000, 11, '2017-02-01', '2021-02-01', 1, '', 2, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-09 15:45:37.386097', '49-2017', 'Сфера СІМ', '№РН-17718', '2017-12-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (143, '2020-04-09 15:50:13.071858', 207, 600, '2017-12-04', 3, 1, 0, 8, '2017-04-01', '2021-10-01', 1, '', 2, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-09 15:50:13.071858', '52-2017', 'Сфера СІМ', '№РН-17718', '2017-12-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (142, '2020-04-09 15:48:36.721055', 211, 100, '2017-12-04', 3, 1, 100, 7, '2017-03-01', '2021-09-01', 1, '', 2, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-09 15:48:36.721055', '51-2017', 'Сфера СІМ', '№РН-17718', '2017-12-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (131, '2020-04-09 15:17:11.994251', 171, 3000, '2017-12-04', 3, 1, 2000, 1, '2017-03-30', '2027-03-30', 0, '', 4, 6, 1, '', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-09 15:17:11.994251', '40-2017', 'Сфера СІМ', '№РН-17697', '2017-12-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (144, '2020-04-09 15:52:14.343262', 204, 1000, '2017-12-04', 3, 1, 1000, 2, '2017-08-01', '2020-08-01', 1, '', 2, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-09 15:52:14.343262', '53-2017', 'Сфера СІМ', '№РН-17718', '2017-12-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (126, '2020-04-09 14:59:12.31648', 14, 1000, '2017-12-04', 3, 1, 1000, 7, '2017-09-01', '2020-09-01', 1, '', 2, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-09 14:59:12.31648', '35-2017', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0059681', '2017-12-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (148, '2020-04-09 16:30:43.617861', 65, 2000, '2018-06-04', 3, 1, 2000, 7, '2017-10-10', '2020-10-10', 1, '', 1, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-09 16:30:43.617861', '3-2018', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0023632', '2018-06-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (163, '2020-04-10 09:40:06.201022', 141, 2000, '2018-06-04', 3, 1, 2000, 11, '2018-05-02', '2020-08-02', 1, '', 1, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 09:40:06.201022', '18-2018', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0023632', '2018-06-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (149, '2020-04-09 16:54:50.876749', 99, 5000, '2018-06-04', 3, 1, 5000, 8, '2018-04-03', '2020-10-03', 1, '', 1, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-09 16:54:50.876749', '4-2018', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0023632', '2018-06-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (154, '2020-04-09 17:06:34.65202', 14, 5000, '2018-06-04', 3, 1, 4000, 7, '2018-01-18', '2021-01-18', 1, '', 1, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-09 17:06:34.65202', '9-2018', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0023632', '2018-06-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (151, '2020-04-09 17:00:24.480241', 7, 10000, '2018-06-04', 3, 1, 10000, 7, '2018-05-04', '2020-11-04', 1, '', 1, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-09 17:00:24.480241', '6-2018', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0023632', '2018-06-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (152, '2020-04-09 17:01:35.633607', 33, 1000, '2018-06-04', 3, 1, 1000, 1, '2018-03-08', '2021-03-08', 1, '', 1, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-09 17:01:35.633607', '7-2018', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0023632', '2018-06-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (153, '2020-04-09 17:04:49.524917', 53, 7000, '2018-06-04', 3, 1, 7000, 7, '2018-04-23', '2020-10-23', 1, '', 1, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-09 17:04:49.524917', '8-2018', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0023632', '2018-06-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (160, '2020-04-10 09:34:45.981696', 224, 1000, '2018-06-04', 3, 1, 0, 7, '2018-01-12', '2024-01-12', 1, '', 1, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 09:34:45.981696', '15-2018', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0023632', '2018-06-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (158, '2020-04-09 17:12:19.200525', 20, 4000, '2018-06-04', 3, 1, 4000, 7, '2018-02-28', '2020-08-28', 1, '', 1, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-09 17:12:19.200525', '13-2018', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0023632', '2018-06-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (155, '2020-04-09 17:08:27.123998', 64, 5000, '2018-06-04', 3, 1, 5000, 11, '2017-05-05', '2022-05-05', 1, '', 1, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-09 17:08:27.123998', '10-2018', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0023632', '2018-06-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (156, '2020-04-09 17:09:56.985965', 137, 1000, '2018-06-04', 3, 1, 1000, 7, '2017-08-09', '2020-08-08', 1, '', 2, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-09 17:09:56.985965', '11-2018', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0023632', '2018-06-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (162, '2020-04-10 09:39:01.215385', 217, 100, '2018-06-04', 3, 1, 0, 7, '2015-08-17', '2020-08-31', 1, '', 2, 5, 1, '', 'лабораторія к. 317', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 09:39:01.215385', '17-2018', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0023632', '2018-06-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (161, '2020-04-10 09:37:08.798268', 225, 100, '2018-06-04', 3, 1, 100, 7, '2017-03-16', '2022-03-31', 1, '', 2, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 09:37:08.798268', '16-2018', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0023632', '2018-06-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (159, '2020-04-09 17:17:06.884751', 48, 500, '2018-06-04', 3, 1, 500, 7, '2017-12-27', '2020-12-27', 1, '', 2, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-09 17:17:06.884751', '14-2018', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0023632', '2018-06-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (164, '2020-04-10 09:40:45.099831', 142, 2000, '2018-06-04', 3, 1, 2000, 11, '2018-05-02', '2020-08-02', 1, '', 1, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 09:40:45.099831', '19-2018', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0023632', '2018-06-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (150, '2020-04-09 16:58:46.98614', 62, 4000, '2018-06-04', 3, 1, 3000, 1, '2018-04-04', '2020-07-19', 1, '', 1, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-09 16:58:46.98614', '5-2018', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0023632', '2018-06-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (165, '2020-04-10 09:42:49.0516', 218, 3, '2018-06-04', 3, 1, 3, 1, '2018-04-11', '2028-04-11', 0, '', 4, 6, 1, '', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-10 09:42:49.0516', '20-2018', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0023632', '2018-06-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (166, '2020-04-10 09:48:01.281584', 119, 8, '2018-06-04', 3, 1, 8, 1, '2018-04-11', '2028-04-11', 0, '', 4, 6, 1, '', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-10 09:48:01.281584', '21-2018', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0023632', '2018-06-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (147, '2020-04-09 16:29:32.199286', 213, 2000, '2018-06-04', 3, 1, 2000, 1, '2017-08-15', '2020-08-15', 1, '', 1, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-09 16:29:32.199286', '2-2018', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0023632', '2018-06-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (179, '2020-04-10 10:24:00.413844', 20, 4000, '2018-06-05', 3, 1, 4000, 7, '2018-03-28', '2020-09-28', 1, '', 1, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 10:24:00.413844', '34-2018', 'Сфера СІМ', '№РН-07496', '2018-06-05');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (171, '2020-04-10 09:59:49.71204', 10, 4000, '2018-06-19', 3, 1, 2000, 7, '2018-04-25', '2021-04-25', 1, '', 1, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 09:59:49.71204', '26-2018', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0026587', '2018-06-19');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (172, '2020-04-10 10:01:02.920973', 175, 3000, '2018-06-04', 3, 1, 3000, 9, '2018-03-28', '2021-03-31', 1, '', 1, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 10:01:02.920973', '27-2018', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0023632', '2018-06-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (173, '2020-04-10 10:10:06.748404', 226, 4000, '2018-06-04', 3, 1, 4000, 1, '2018-04-11', '2028-04-11', 0, '', 4, 6, 1, '', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-10 10:10:06.748404', '28-2018', 'Сфера СІМ', '№РН-07494', '2018-06-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (182, '2020-04-10 10:33:02.56979', 62, 4000, '2018-06-05', 3, 1, 4000, 1, '2018-04-04', '2020-07-04', 1, '', 1, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 10:33:02.56979', '37-2018', 'Сфера СІМ', '№РН-07496', '2018-06-05');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (181, '2020-04-10 10:26:36.919933', 33, 2000, '2018-06-05', 3, 1, 2000, 1, '2018-04-01', '2021-04-01', 1, '', 1, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 10:26:36.919933', '36-2018', 'Сфера СІМ', '№РН-07496', '2018-06-05');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (174, '2020-04-10 10:11:42.555496', 220, 2000, '2018-06-04', 3, 1, 2000, 1, '2018-04-11', '2028-04-11', 0, '', 4, 6, 1, '', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-10 10:11:42.555496', '29-2018', 'Сфера СІМ', '№РН-07494', '2018-06-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (175, '2020-04-10 10:12:54.496434', 221, 10, '2018-06-04', 3, 1, 10, 1, '2018-04-11', '2028-04-11', 0, '', 4, 6, 1, '', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-10 10:12:54.496434', '30-2018', 'Сфера СІМ', '№РН-07494', '2018-06-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (176, '2020-04-10 10:13:39.050138', 222, 10, '2018-06-04', 3, 1, 10, 1, '2018-04-11', '2028-04-11', 0, '', 4, 6, 1, '', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-10 10:13:39.050138', '31-2018', 'Сфера СІМ', '№РН-07494', '2018-06-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (177, '2020-04-10 10:20:51.085822', 175, 3000, '2018-06-05', 3, 1, 3000, 9, '2018-03-28', '2021-03-31', 1, '', 1, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 10:20:51.085822', '32-2018', 'Сфера СІМ', '№РН-07496', '2018-06-05');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (180, '2020-04-10 10:25:18.199639', 217, 100, '2018-06-05', 3, 1, 100, 7, '2018-05-01', '2020-11-01', 1, '', 2, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 10:25:18.199639', '35-2018', 'Сфера СІМ', '№РН-07496', '2018-06-05');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (168, '2020-04-10 09:54:44.112937', 216, 2500, '2018-06-04', 3, 1, 2500, 9, '2017-12-19', '2022-12-19', 1, 'МЕРК', 1, 5, 1, '', 'лабораторія к. 317', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 09:54:44.112937', '23-2018', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0026585', '2018-06-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (169, '2020-04-10 09:57:28.018004', 21, 5000, '2018-06-08', 3, 1, 5000, 11, '2018-04-25', '2021-04-25', 1, '', 1, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 09:57:28.018004', '24-2018', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0025045', '2018-06-08');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (184, '2020-04-10 10:35:39.829666', 65, 2000, '2018-06-05', 3, 1, 2000, 7, '2018-04-03', '2021-04-03', 1, '', 1, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 10:35:39.829666', '39-2018', 'Сфера СІМ', '№РН-07496', '2018-06-05');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (185, '2020-04-10 10:36:43.715801', 53, 8000, '2018-06-05', 3, 1, 8000, 7, '2018-04-19', '2020-10-19', 1, '', 1, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 10:36:43.715801', '40-2018', 'Сфера СІМ', '№РН-07496', '2018-06-05');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (183, '2020-04-10 10:34:30.454895', 213, 1000, '2018-06-05', 3, 1, 0, 1, '2018-02-02', '2021-02-02', 1, '', 1, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 10:34:30.454895', '38-2018', 'Сфера СІМ', '№РН-07496', '2018-06-05');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (186, '2020-04-10 10:37:43.65824', 215, 5000, '2018-06-05', 3, 1, 4000, 7, '2018-04-07', '2021-04-07', 1, '', 1, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 10:37:43.65824', '41-2018', 'Сфера СІМ', '№РН-07496', '2018-06-05');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (187, '2020-04-10 10:38:37.189325', 137, 1000, '2018-06-05', 3, 1, 1000, 7, '2018-05-04', '2021-05-04', 1, '', 2, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 10:38:37.189325', '42-2018', 'Сфера СІМ', '№РН-07496', '2018-06-05');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (188, '2020-04-10 10:40:10.485391', 27, 1000, '2018-06-05', 3, 1, 1000, 11, '2017-04-20', '2022-04-20', 1, '', 2, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 10:40:10.485391', '43-2018', 'Сфера СІМ', '№РН-07496', '2018-06-05');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (170, '2020-04-10 09:58:29.637276', 58, 2000, '2018-06-04', 3, 1, 2000, 7, '2018-04-25', '2020-10-25', 1, '', 1, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 09:58:29.637276', '25-2018', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0023783', '2018-06-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (198, '2020-04-10 11:23:52.371074', 160, 500, '2019-07-01', 3, 1, 500, 1, '2019-04-03', '2029-04-03', 0, '', 4, 6, 1, '', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-10 11:23:52.371074', '3-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (201, '2020-04-10 11:32:53.440508', 228, 1000, '2019-07-01', 3, 1, 1000, 1, '2019-04-03', '2029-04-03', 0, '', 4, 6, 1, '2 упаковки (по 500 шт) з мікропробірками Амед на 2,0 мл', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-10 11:32:53.440508', '6-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (193, '2020-04-10 10:48:15.747678', 33, 2000, '2018-06-05', 3, 1, 2000, 2, '2018-04-01', '2021-04-01', 1, '', 1, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 10:48:15.747678', '48-2018', 'Сфера СІМ', '№РН-07496', '2018-06-05');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (192, '2020-04-10 10:46:44.384985', 99, 9000, '2018-06-05', 3, 1, 9000, 8, '2018-05-03', '2021-05-03', 1, '', 1, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 10:46:44.384985', '47-2018', 'Сфера СІМ', '№РН-07496', '2018-06-05');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (195, '2020-04-10 10:51:04.586354', 214, 2000, '2018-06-05', 3, 1, 2000, 8, '2018-02-02', '2021-02-02', 1, '', 1, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 10:51:04.586354', '50-2018', 'Сфера СІМ', '№РН-07496', '2018-06-05');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (196, '2020-04-10 10:52:30.393839', 165, 1000, '2018-08-21', 3, 1, 1000, 1, '2018-02-02', '2021-02-02', 1, '', 2, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 10:52:30.393839', '51-2018', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№18-309', '2018-08-21');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (190, '2020-04-10 10:43:36.813298', 64, 6000, '2018-06-05', 3, 1, 5000, 11, '2018-04-05', '2022-04-05', 1, '', 1, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 10:43:36.813298', '45-2018', 'Сфера СІМ', '№РН-07496', '2018-06-05');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (197, '2020-04-10 11:22:42.91856', 246, 10000, '2019-07-01', 3, 1, 10000, 1, '2019-04-03', '2029-04-03', 0, '', 4, 6, 1, '10000 г це 400 листів фільтрувального паперу білого кольору', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-10 11:22:42.91856', '2-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (199, '2020-04-10 11:29:39.880289', 247, 1000, '2019-07-01', 3, 1, 1000, 1, '2019-04-03', '2029-04-03', 0, '', 4, 6, 1, '10 упаковок по 100 штук', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-10 11:29:39.880289', '4-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (200, '2020-04-10 11:32:11.553537', 227, 1000, '2019-07-01', 3, 1, 1000, 1, '2019-04-03', '2029-04-03', 0, '', 4, 6, 1, '2 упаковки (по 500 шт) з мікропробірками Еппендорф на 1,5 мл', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-10 11:32:11.553537', '5-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (203, '2020-04-10 11:37:06.230716', 112, 10, '2019-07-01', 3, 1, 10, 1, '2019-04-03', '2029-04-03', 0, '', 4, 6, 1, 'Скляні мірні циліндри місткістю по 10 мл (10 шт)', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-10 11:37:06.230716', '8-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (204, '2020-04-10 11:39:42.234948', 221, 10, '2019-07-01', 3, 1, 10, 1, '2019-04-03', '2029-04-03', 0, '', 4, 6, 1, 'йоржі для миття посуду 10 шт', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-10 11:39:42.234948', '9-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (205, '2020-04-10 11:40:40.880091', 123, 500, '2019-07-01', 3, 1, 500, 1, '2019-04-03', '2029-04-03', 0, '', 4, 6, 1, 'полімерні пробки до флаконів 1000 шт', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-10 11:40:40.880091', '10-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (206, '2020-04-10 11:42:00.144962', 127, 10, '2019-07-01', 3, 1, 10, 1, '2019-04-03', '2029-04-03', 0, '', 4, 6, 1, '10 скляних лабюораторних воронок', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-10 11:42:00.144962', '11-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (207, '2020-04-10 11:51:29.926029', 229, 2, '2019-07-01', 3, 1, 2, 1, '2019-04-03', '2029-04-03', 0, '', 4, 6, 1, '2 упаковок покривних скелець по 100 шт', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-10 11:51:29.926029', '12-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (208, '2020-04-10 11:56:35.91521', 230, 10, '2019-07-01', 3, 1, 10, 1, '2019-04-03', '2029-04-03', 0, '', 4, 6, 1, '10 скляних стаканів на 50 мл', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-10 11:56:35.91521', '13-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (191, '2020-04-10 10:44:33.867153', 14, 6000, '2018-06-05', 3, 1, 6000, 7, '2018-04-18', '2021-04-18', 1, '', 1, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 10:44:33.867153', '46-2018', 'Сфера СІМ', '№РН-07496', '2018-06-05');
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
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (233, '2020-04-10 14:08:30.576456', 212, 4000, '2019-07-01', 3, 1, 4000, 9, '2019-01-14', '2022-01-31', 1, '', 1, 5, 1, '4 пляшок з прозорою безбарвною рідиною по 1 л', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 14:08:30.576456', '38-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (239, '2020-04-10 14:29:30.551369', 141, 2000, '2019-07-01', 3, 1, 2000, 11, '2019-05-02', '2020-08-02', 0, '', 1, 5, 1, '2 пляшки з прозорою рідиною по 1 л (по 1,15 кг)', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 14:29:30.551369', '44-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (232, '2020-04-10 14:05:31.028873', 237, 10, '2019-07-01', 3, 1, 5, 1, '2019-04-03', '2029-04-03', 1, '', 4, 6, 1, '10 порцелянових чашок на 25 мл', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-10 14:05:31.028873', '37-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (237, '2020-04-10 14:19:57.252968', 253, 1000, '2019-07-01', 3, 1, 1000, 7, '2018-06-13', '2021-06-13', 0, '', 1, 5, 1, 'пляшка з прозорою рідиною 1 л (1 кг)', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 14:19:57.252968', '42-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (238, '2020-04-10 14:20:58.638797', 14, 2000, '2019-07-01', 3, 1, 2000, 7, '2019-04-03', '2021-04-03', 0, '', 1, 5, 1, '2 пляшки з прозорою рідиною по 1 л (по 0,9 кг)', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 14:20:58.638797', '43-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (244, '2020-04-10 14:37:00.040792', 256, 100, '2019-07-01', 3, 1, 100, 2, '2019-02-13', '2020-08-13', 1, '', 2, 5, 1, '1 банка з кристалічною речовиною 0,100 кг', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 14:37:00.040792', '49-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (240, '2020-04-10 14:30:37.915592', 255, 7500, '2019-07-01', 3, 1, 7500, 9, '2019-02-06', '2022-02-06', 1, '', 1, 5, 1, '3 пляшки з прозорою рідиною по 2,5 л', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 14:30:37.915592', '45-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (242, '2020-04-10 14:33:49.727596', 238, 200, '2019-07-01', 3, 1, 200, 7, '2019-04-15', '2021-04-15', 1, '', 2, 5, 1, '2 пакети з кристалічною речовиною білого кольору по 0,1 кг', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 14:33:49.727596', '47-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (243, '2020-04-10 14:34:44.025202', 239, 25, '2019-07-01', 3, 1, 25, 7, '2017-12-21', '2021-12-21', 1, '', 2, 5, 1, '1 банка з кристалічною речовиною 0,025 кг', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 14:34:44.025202', '48-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (245, '2020-04-10 14:43:35.012862', 257, 10, '2019-07-01', 3, 1, 10, 7, '2019-04-04', '2020-10-04', 1, '', 2, 5, 1, '1 банка з кристалічною речовиною 0,010 кг', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 14:43:35.012862', '50-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (236, '2020-04-10 14:17:32.193619', 36, 1000, '2019-07-01', 3, 1, 1000, 2, '2018-06-08', '2021-06-08', 0, '', 1, 5, 1, 'пляшка з прозорою рідиною 1 л (1,2 кг)', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 14:17:32.193619', '41-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (234, '2020-04-10 14:13:06.851175', 29, 10, '2019-07-01', 3, 1, 10, 9, '2019-01-14', '2020-07-14', 1, '', 1, 5, 1, 'пляшка з кристалічною речовиною масою 10 г', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 14:13:06.851175', '39-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (256, '2020-04-10 15:03:18.009671', 175, 6000, '2019-07-01', 3, 1, 6000, 9, '2018-03-28', '2024-01-31', 1, '', 1, 5, 1, '6 пляшок з прозорою рідиною по 1 л', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 15:03:18.009671', '61-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (247, '2020-04-10 14:47:26.702316', 134, 300, '2019-07-01', 3, 1, 300, 7, '2018-12-24', '2020-12-24', 1, '', 2, 5, 1, '3 пакети з кристалічною речовиною по 0,100 кг (Мідь сірчанокисла)', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 14:47:26.702316', '52-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (253, '2020-04-10 14:58:29.186057', 241, 300, '2019-07-01', 3, 1, 300, 7, '2019-03-22', '2020-09-22', 1, '', 2, 5, 1, '3 пакети з кристалічною речовиною по 0,100 кг', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 14:58:29.186057', '58-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (249, '2020-04-10 14:51:15.114433', 39, 400, '2019-07-01', 3, 1, 400, 8, '2019-01-11', '2021-01-11', 1, '', 2, 5, 1, '4 банки з кристалічною речовиною по 0,100 кг', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 14:51:15.114433', '54-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (250, '2020-04-10 14:53:29.887537', 26, 300, '2019-07-01', 3, 1, 300, 11, '2018-09-25', '2020-09-25', 1, '', 2, 5, 1, '3 банки з кристалічною речовиною по 0,100 кг', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 14:53:29.887537', '55-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (251, '2020-04-10 14:55:39.004658', 258, 50, '2019-07-01', 3, 1, 50, 7, '2018-03-28', '2021-03-28', 1, '', 2, 5, 1, '1 банка з кристалічною речовиною 0,050 кг', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 14:55:39.004658', '56-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (252, '2020-04-10 14:57:21.310835', 259, 200, '2019-07-01', 3, 1, 200, 7, '2018-11-14', '2020-11-14', 1, '', 2, 5, 1, '2 пакети з кристалічною речовиною по 0,100 кг', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 14:57:21.310835', '57-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (257, '2020-04-10 15:04:48.216681', 242, 300, '2019-07-01', 3, 1, 300, 11, '2018-06-07', '2021-06-07', 1, '', 2, 5, 1, '3 пакетів з речовиною по 0,100 кг', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 15:04:48.216681', '62-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (260, '2020-04-10 15:10:02.996369', 150, 100, '2019-07-01', 3, 1, 100, 8, '2018-12-25', '2020-12-25', 1, '', 2, 5, 1, '1 пакет з речовиною 0,100 кг', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 15:10:02.996369', '65-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (248, '2020-04-10 14:49:58.906276', 207, 100, '2019-07-01', 3, 1, 100, 8, '2019-03-28', '2020-09-28', 1, '', 2, 5, 1, '1 пакет з кристалічною речовиною 0,100 кг', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 14:49:58.906276', '53-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (258, '2020-04-10 15:06:02.980852', 178, 1000, '2019-07-01', 3, 1, 1000, 7, '2019-03-29', '2022-03-29', 1, '', 2, 5, 1, '1 пакет з речовиною 1,000 кг', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 15:06:02.980852', '63-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (259, '2020-04-10 15:08:43.508399', 28, 100, '2019-07-01', 3, 1, 100, 11, '2019-03-28', '2021-03-28', 1, '', 2, 5, 1, '1 пакет з речовиною 0,100 кг', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 15:08:43.508399', '64-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (261, '2020-04-10 15:14:57.457556', 260, 200, '2019-07-01', 3, 1, 200, 7, '2019-02-18', '2020-08-18', 1, '', 2, 5, 1, '2 пакети з речовиною по 0,100 кг', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 15:14:57.457556', '66-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (254, '2020-04-10 15:00:23.781137', 50, 1000, '2019-07-01', 3, 1, 0, 11, '2018-12-05', '2020-12-04', 0, '', 1, 5, 1, 'пляшка з прозорою рідиною 1 л (1,8 кг)', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 15:00:23.781137', '59-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (262, '2020-04-10 15:16:02.032921', 136, 300, '2019-07-01', 3, 1, 200, 7, '2019-04-18', '2020-07-18', 1, '', 2, 5, 1, '3 пакети з порошкоподібною речовиною по 0,100 кг', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 15:16:02.032921', '67-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (263, '2020-04-10 15:17:48.728412', 8, 200, '2019-07-01', 3, 1, 200, 7, '2019-05-29', '2021-05-29', 1, '', 2, 5, 1, '2 пакети з порошкоподібною речовиною по 0,100 кг', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 15:17:48.728412', '68-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (268, '2020-04-10 15:27:28.729871', 18, 5000, '2019-07-01', 3, 1, 5000, 11, '2019-03-20', '2020-09-20', 0, '', 1, 5, 1, '5 пляшок з прозорою рідиною по 1 л (по 1,26 кг)', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 15:27:28.729871', '73-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (266, '2020-04-10 15:22:49.95371', 27, 200, '2019-07-01', 3, 1, 200, 11, '2018-11-01', '2023-10-30', 1, '', 2, 5, 1, '2 банки з речовиною по 0,100 кг', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 15:22:49.95371', '71-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (267, '2020-04-10 15:23:36.729835', 152, 10000, '2019-07-01', 3, 1, 10000, 11, '2018-06-10', '2021-06-10', 1, '', 2, 5, 1, '10 пакетів з білою речовиною по 1,000 кг', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 15:23:36.729835', '72-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (269, '2020-04-10 15:28:36.160761', 243, 1000, '2019-07-01', 3, 1, 1000, 9, '2017-04-26', '2022-04-30', 1, '', 1, 5, 1, '1 пляшка з прозорою рідиною 1 л', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 15:28:36.160761', '74-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023257', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (270, '2020-04-10 15:30:19.267089', 10, 5000, '2019-07-01', 3, 1, 5000, 7, '2019-03-29', '2022-03-29', 1, '', 1, 5, 1, '5 пляшок з прозорою рідиною по 1 л (по 0,8 кг)', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 15:30:19.267089', '75-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023257', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (276, '2020-04-10 15:38:00.937462', 129, 500, '2019-07-01', 3, 1, 400, 7, '2019-04-06', '2020-10-05', 1, '', 2, 5, 1, '5 банок з кристалічною речовиною по 0,100 кг', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 15:38:00.937462', '81-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (272, '2020-04-10 15:33:08.87157', 262, 1000, '2019-07-01', 3, 1, 1000, 1, '2019-04-03', '2029-04-03', 1, '', 4, 6, 1, 'Фільтри лабораторні знезолені стрічка синя діаметром 150 мм 100 шт/уп', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-10 15:33:08.87157', '77-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (273, '2020-04-10 15:34:12.95766', 122, 20, '2019-07-01', 3, 1, 20, 1, '2019-04-03', '2029-04-03', 1, '', 4, 6, 1, '20 скляних мірних колб на 50 мл', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-10 15:34:12.95766', '78-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (274, '2020-04-10 15:35:13.832431', 245, 2, '2019-07-01', 3, 1, 2, 1, '2019-04-03', '2029-04-03', 1, '', 4, 6, 1, '2 скляних каплеуловлювача', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-10 15:35:13.832431', '79-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (275, '2020-04-10 15:37:04.084195', 263, 10, '2019-07-01', 3, 1, 10, 7, '2019-06-15', '2022-07-15', 1, '', 2, 5, 1, '1 банка з кристалічною речовиною 0,010 кг', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 15:37:04.084195', '80-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (280, '2020-04-10 15:45:53.59556', 99, 7000, '2019-07-30', 3, 1, 7000, 8, '2019-04-04', '2020-10-04', 0, '', 1, 5, 1, '7 пляшок з рідиною по 0.6 кг (по 1.0 л)', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 15:45:53.59556', '85-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№ХМ000537', '2019-07-30');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (278, '2020-04-10 15:41:16.241666', 224, 2000, '2019-07-30', 3, 1, 2000, 7, '2018-01-12', '2024-01-12', 1, '', 1, 5, 1, '2 пляшки з рідиною по 1.0 л', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 15:41:16.241666', '83-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№ХМ000537', '2019-07-30');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (279, '2020-04-10 15:43:01.203513', 215, 10000, '2019-07-30', 3, 1, 10000, 7, '2018-10-15', '2020-10-15', 0, '', 1, 5, 1, '10 пляшок з рідиною по 0.7 кг (по 1.0 л)', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 15:43:01.203513', '84-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№ХМ000537', '2019-07-30');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (281, '2020-04-10 15:47:50.69122', 176, 7500, '2019-07-30', 3, 1, 2500, 7, '2017-09-28', '2020-09-30', 1, '', 1, 5, 1, '3 пляшки з рідиною по 2,5 л (7,5 л в загальному)', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 15:47:50.69122', '86-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№ХМ000537', '2019-07-30');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (271, '2020-04-10 15:32:10.14039', 244, 200, '2019-07-01', 3, 1, 100, 7, '2018-11-16', '2021-11-16', 1, '', 2, 5, 1, '2 банки з кристалічною речовиною по 0,100 кг', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 15:32:10.14039', '76-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (265, '2020-04-10 15:21:54.566181', 159, 30, '2019-07-01', 3, 1, 30, 7, '2017-02-10', '2021-08-10', 1, '', 2, 5, 1, '1 банка з речовиною 0,030 кг', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 15:21:54.566181', '70-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (311, '2020-04-13 12:16:59.931642', 192, 22400, '2020-02-24', 3, 1, 22400, 9, '2020-02-20', '2022-02-20', 0, '', 1, 5, 1, 'балони із стиснутим гелієм 4 шт по 5,6 л', 'лабораторія к. 317', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-13 12:16:59.931642', '1-2020', 'ТОВ "Кріогенсервіс"', '№3067', '2020-02-24');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (283, '2020-04-10 15:51:23.359012', 264, 100, '2019-09-18', 3, 1, 100, 7, '2017-11-08', '2022-11-30', 1, '', 2, 5, 1, '1 упаковка (банка з речовиною масою 100 г)', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 15:51:23.359012', '88-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х034463', '2019-09-18');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (298, '2020-04-10 16:13:44.862052', 22, 25000, '2019-12-24', 3, 1, 24000, 11, '2019-11-02', '2024-12-02', 0, '', 1, 5, 1, '250 пляшок із прозорою рідиною по 100 мл', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 16:13:44.862052', '103-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х046153', '2019-12-24');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (286, '2020-04-10 15:54:54.227929', 63, 2000, '2019-12-18', 3, 1, 2000, 8, '2019-11-15', '2020-11-15', 1, '', 1, 5, 1, '2 пляшки з прозорою рідиною обємом по 1.0 л (по 1,2 кг)', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 15:54:54.227929', '91-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х046210', '2019-12-18');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (287, '2020-04-10 15:55:57.659911', 165, 1000, '2019-12-18', 3, 1, 1000, 11, '2018-05-25', '2021-05-25', 1, '', 2, 5, 1, '1 упаковка з кристалічною речовиною масою 1,0 кг', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 15:55:57.659911', '92-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х046210', '2019-12-18');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (288, '2020-04-10 15:57:17.390362', 136, 4000, '2019-12-17', 3, 1, 4000, 2, '2019-05-25', '2021-05-25', 1, '', 2, 5, 1, '4 упаковки з речовиною масою по 1,0 кг', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 15:57:17.390362', '93-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х046146', '2019-12-17');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (289, '2020-04-10 15:58:58.763756', 51, 1000, '2019-12-17', 3, 1, 1000, 2, '2019-03-18', '2021-03-17', 1, '', 1, 5, 1, '1 пляшка з рідиною обємом 1,0 л (1,0 кг)', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 15:58:58.763756', '94-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х046146', '2019-12-17');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (292, '2020-04-10 16:04:03.47474', 174, 50, '2019-12-17', 3, 1, 0, 1, '2019-10-31', '2029-10-31', 1, '', 4, 6, 1, '2 упаковки алюмінієвих пластинок 25 шт/уп 20*20 см', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-10 16:04:03.47474', '97-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х046154', '2019-12-17');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (290, '2020-04-10 16:00:51.391712', 62, 2000, '2019-12-17', 3, 1, 2000, 2, '2019-10-04', '2020-07-04', 1, '', 1, 5, 1, '2 пляшка із суспензією обємом по 1,0 л (по 1,1 кг)', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 16:00:51.391712', '95-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х046146', '2019-12-17');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (295, '2020-04-10 16:09:39.883567', 191, 800, '2019-12-17', 3, 1, 500, 1, '2019-10-31', '2029-10-31', 1, '', 4, 6, 1, '8 комплектів віал із кришками та септами 100 шт/уп', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-10 16:09:39.883567', '100-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х046154', '2019-12-17');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (293, '2020-04-10 16:05:10.682918', 110, 4, '2019-12-17', 3, 1, 4, 1, '2019-10-31', '2029-10-31', 1, '', 4, 6, 1, '4 скляних конічних колб на 50 мл', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-10 16:05:10.682918', '98-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х046154', '2019-12-17');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (294, '2020-04-10 16:08:34.885618', 265, 8, '2019-12-17', 3, 1, 8, 1, '2019-10-31', '2029-10-31', 1, '', 4, 6, 1, '8 стаканчиків для зважування низьких 50*30 мм', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-10 16:08:34.885618', '99-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х046154', '2019-12-17');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (299, '2020-04-13 10:02:56.639907', 193, 200, '2019-12-17', 3, 1, 100, 1, '2019-10-31', '2029-10-31', 1, '', 4, 6, 1, '2 упаковки з мікровіалами по 100 шт/уп', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-13 10:02:56.639907', '104-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х046154', '2019-12-17');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (296, '2020-04-10 16:10:57.957936', 266, 900, '2019-12-17', 3, 1, 900, 1, '2019-10-31', '2029-10-31', 1, '', 4, 6, 1, '9 упаковок септ для кришок по 100 шт/уп', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-10 16:10:57.957936', '101-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х046154', '2019-12-17');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (291, '2020-04-10 16:02:34.667681', 172, 3500, '2019-12-17', 3, 1, 3000, 1, '2019-04-03', '2029-04-03', 1, '', 4, 6, 1, '7 упаковок із полімерними накінечниками блакитного кольору по 500 шт/уп', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-10 16:02:34.667681', '96-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х046154', '2019-12-17');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (284, '2020-04-10 15:52:54.977859', 176, 10000, '2019-12-18', 3, 1, 7500, 9, '2019-07-03', '2022-07-31', 1, '', 1, 5, 1, '4 пляшки з прозорою рідиною по 2,5 л', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 15:52:54.977859', '89-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х046208', '2019-12-18');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (157, '2020-04-09 17:11:11.693053', 27, 1000, '2018-06-04', 3, 1, 1000, 11, '2017-11-28', '2022-11-28', 1, '', 2, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-09 17:11:11.693053', '12-2018', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0023632', '2018-06-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (167, '2020-04-10 09:53:15.615834', 118, 3, '2018-06-04', 3, 1, 3, 1, '2018-04-11', '2028-04-11', 0, '', 4, 6, 1, '', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-10 09:53:15.615834', '22-2018', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0023632', '2018-06-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (74, '2020-04-07 17:25:50.892422', 156, 5000, '2016-04-06', 3, 1, 5000, 2, '2016-03-01', '2021-03-01', 1, '', 2, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-07 17:25:50.892422', '55-2016', 'Сфера СІМ', '№РН-04444', '2016-04-06');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (189, '2020-04-10 10:42:15.495545', 7, 3000, '2018-06-05', 3, 1, 2000, 7, '2018-04-04', '2020-10-04', 1, '', 1, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 10:42:15.495545', '44-2018', 'Сфера СІМ', '№РН-07496', '2018-06-05');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (81, '2020-04-09 09:13:13.488743', 162, 2, '2016-04-01', 3, 1, 2, 1, '2015-01-20', '2025-01-20', 1, '', 4, 6, 1, '', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-09 09:13:13.488743', '62-2016', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0011571', '2016-04-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (95, '2020-04-09 13:26:20.335194', 179, 2, '2017-05-04', 3, 1, 2, 1, '2017-03-30', '2027-03-30', 0, '', 4, 6, 1, '', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-09 13:26:20.335194', '4-2017', 'Сфера СІМ', '№СФ-07280', '2017-05-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (209, '2020-04-10 12:01:48.493104', 105, 20, '2019-07-01', 3, 1, 20, 1, '2019-04-03', '2029-04-03', 1, '', 4, 6, 1, '', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-10 12:01:48.493104', '14-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (217, '2020-04-10 12:15:43.061559', 226, 1000, '2019-07-01', 3, 1, 1000, 1, '2019-04-03', '2029-04-03', 0, '', 4, 6, 1, '1 упаковка (1000 шт) з жовтими накінечниками до піпет-дозатору ЛЛГ на 1-200 мкл', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-10 12:15:43.061559', '22-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (228, '2020-04-10 14:01:40.483795', 124, 10, '2019-07-01', 3, 1, 10, 1, '2019-04-03', '2029-04-03', 0, '', 4, 6, 1, '10 скляних стаканів на 250 мл', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-10 14:01:40.483795', '33-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (313, '2020-04-13 12:35:19.555341', 224, 1000, '2020-03-23', 3, 1, 1000, 7, '2018-01-12', '2024-01-12', 1, 'CARLO ERBA REAGENTS', 1, 5, 1, '1 пляшка з прозорою рідиною на 1,0 л', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-13 12:35:19.555341', '3-2020', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№ЛР004772', '2020-03-23');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (135, '2020-04-09 15:35:03.374354', 62, 1000, '2017-12-04', 3, 1, 1000, 1, '2017-06-01', '2020-12-01', 1, '', 1, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-09 15:35:03.374354', '44-2017', 'Сфера СІМ', '№РН-17718', '2017-12-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (119, '2020-04-09 14:29:57.362008', 21, 2000, '2017-11-30', 3, 1, 2000, 11, '2017-03-01', '2021-05-01', 1, '', 1, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-09 14:29:57.362008', '28-2017', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0076913', '2017-11-30');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (104, '2020-04-09 13:44:42.413488', 188, 2000, '2017-05-04', 3, 1, 1000, 2, '2016-08-01', '2020-08-01', 1, '', 1, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-09 13:44:42.413488', '13-2017', 'Сфера СІМ', '№СФ-07467', '2017-05-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (48, '2020-04-07 15:35:47.21042', 26, 2000, '2016-04-04', 3, 1, 1000, 8, '2016-03-01', '2020-09-01', 1, '', 2, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-07 15:35:47.21042', '29-2016', 'Сфера СІМ', '№РН-04122', '2016-04-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (88, '2020-04-09 12:02:17.507357', 58, 1000, '2016-12-05', 3, 1, 0, 7, '2016-07-01', '2021-01-01', 1, '', 1, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-09 12:02:17.507357', '69-2016', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0054476', '2016-12-05');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (20, '2020-04-07 11:17:26.064597', 59, 10.8699999999999992, '2016-03-14', 3, 1, 0, 2, '2016-03-01', '2020-09-01', 1, '', 2, 5, 1, 'Кристалічний порошок коричневого кольору', 'лабораторія 317', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-07 11:17:26.064597', '1-2016', 'Сфера СІМ', 'РН-01884', '2016-03-14');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (145, '2020-04-09 15:58:26.212358', 205, 500, '2017-12-04', 3, 1, 500, 2, '2017-01-06', '2021-01-06', 1, '', 2, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-09 15:58:26.212358', '54-2017', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х0059686', '2017-12-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (178, '2020-04-10 10:22:09.907536', 34, 100, '2018-06-05', 3, 1, 100, 9, '2017-09-07', '2021-02-23', 1, '', 2, 5, 1, '', 'лабораторія к. 317', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 10:22:09.907536', '33-2018', 'Сфера СІМ', '№РН-07496', '2018-06-05');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (194, '2020-04-10 10:49:32.989679', 64, 3000, '2018-06-05', 3, 1, 2000, 8, '2018-05-01', '2021-02-01', 1, '', 1, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 10:49:32.989679', '49-2018', 'Сфера СІМ', '№РН-07496', '2018-06-05');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (241, '2020-04-10 14:32:16.077273', 254, 5000, '2019-07-01', 3, 1, 5000, 9, '2018-07-16', '2022-07-16', 1, '', 1, 5, 1, '2 пляшки з прозорою рідиною по 2,5 л', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 14:32:16.077273', '46-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (255, '2020-04-10 15:01:53.534497', 5, 1000, '2019-07-01', 3, 1, 1000, 9, '2019-02-15', '2024-01-31', 0, '', 1, 5, 1, 'пляшка з прозорою рідиною 1 л (1,4 кг)', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 15:01:53.534497', '60-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (264, '2020-04-10 15:19:42.301253', 261, 200, '2019-07-01', 3, 1, 200, 11, '2018-11-09', '2020-11-09', 1, '', 2, 5, 1, '2 пакети з порошкоподібною речовиною по 0,100 кг', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 15:19:42.301253', '69-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (277, '2020-04-10 15:39:59.543205', 59, 300, '2019-07-01', 3, 1, 300, 2, '2019-06-15', '2022-07-15', 1, '', 2, 5, 1, '3 банки з кристалічною речовиною по 0,100 кг', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 15:39:59.543205', '82-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (314, '2020-04-13 16:14:15.675947', 174, 50, '2020-03-17', 3, 1, 0, 2, '2019-09-27', '2029-09-30', 0, 'МЕРК', 4, 6, 1, '2 упаковки з пластинками по 25 шт/уп', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-13 16:14:15.675947', '4-2020', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№ЛР004276', '2020-03-17');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (316, '2020-04-13 16:17:22.667634', 58, 3000, '2020-03-19', 3, 1, 3000, 7, '2019-11-11', '2020-11-11', 1, 'ПП "ТЕХПРОМЗБУТ"', 1, 5, 1, '3 пляшки з прозорою рідиною по 1,0 л (0,8 кг)', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-13 16:17:22.667634', '6-2020', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№ЛР004596', '2020-03-19');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (317, '2020-04-13 16:18:46.575122', 165, 50, '2020-03-19', 3, 1, 50, 11, '2018-05-25', '2021-05-25', 1, 'Китай', 2, 5, 1, '1 банка із кристалічною фіолетовою речовиною 50 г', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-13 16:18:46.575122', '7-2020', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№ЛР004596', '2020-03-19');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (318, '2020-04-13 16:21:06.759135', 57, 20000, '2020-03-19', 3, 1, 20000, 7, '2019-12-20', '2022-12-20', 1, 'Україна', 1, 5, 1, '20 пляшок із вязкою рідиною по 1,0 л (1,8 кг)', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-13 16:21:06.759135', '8-2020', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№ЛР004596', '2020-03-19');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (319, '2020-04-13 16:24:02.529228', 10, 4000, '2020-03-19', 3, 1, 4000, 7, '2019-11-11', '2022-11-11', 1, 'ПП "ТЕХПРОМЗБУТ"', 1, 5, 1, '4 пляшки із прозорою рідиною по 1,0 л (0,8 кг)', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-13 16:24:02.529228', '9-2020', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№ЛР004625', '2020-03-19');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (320, '2020-04-13 16:25:51.880311', 63, 5000, '2020-03-19', 3, 1, 5000, 8, '2019-12-20', '2022-12-20', 1, 'Україна', 1, 5, 1, '5 пляшок із прозорою вязкою рідиною по 1,0 л (1,2 кг)', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-13 16:25:51.880311', '10-2020', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№ЛР004625', '2020-03-19');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (321, '2020-04-13 16:30:30.823183', 176, 12500, '2020-03-23', 3, 1, 12500, 9, '2019-08-16', '2022-08-31', 1, 'МЕРК', 1, 5, 1, '5 пляшок із прозорою рідиною по 2,5 л', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-13 16:30:30.823183', '11-2020', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№ЛР004801', '2020-03-23');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (322, '2020-04-13 16:32:00.608549', 177, 20000, '2020-03-23', 3, 1, 20000, 9, '2019-05-06', '2022-05-31', 1, 'МЕРК', 1, 5, 1, '8 пляшок із прозорою рідиною по 2,5 л', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-13 16:32:00.608549', '12-2020', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№ЛР004801', '2020-03-23');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (246, '2020-04-10 14:44:31.267066', 240, 100, '2019-07-01', 3, 1, 100, 2, '2019-05-02', '2020-11-02', 1, '', 2, 5, 1, '1 банка з кристалічною речовиною 0,100 кг', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 14:44:31.267066', '51-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (282, '2020-04-10 15:49:12.787177', 177, 2500, '2019-07-30', 3, 1, 0, 7, '2019-01-30', '2022-01-31', 1, '', 1, 5, 1, 'пляшка з рідиною 2,5 л', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 15:49:12.787177', '87-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№ХМ000537', '2019-07-30');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (312, '2020-04-13 12:33:37.491257', 32, 15000, '2020-03-19', 3, 1, 12500, 7, '2020-02-25', '2022-02-25', 0, 'Нідерланди', 1, 5, 1, '15 пляшок з прозорою рідиною по 1,0 л (0,8 кг)', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-13 12:33:37.491257', '2-2020', 'ТОВ "Кріогенсервіс"', '№ЛР004547', '2020-03-19');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (285, '2020-04-10 15:53:48.997732', 49, 3000, '2019-12-18', 3, 1, 1000, 1, '2019-11-08', '2021-11-08', 1, '', 1, 5, 1, '3 пляшки з прозорою рідиною обємом по 1.0 л (по 0,8 кг)', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-10 15:53:48.997732', '90-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х046208', '2019-12-18');
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
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (332, '2020-04-14 15:19:24.442818', 108, 8, '2020-03-17', 3, 1, 8, 1, '2019-09-27', '2029-09-30', 1, '', 4, 6, 1, '8 скляних мірних піпеток на 25 мл', 'шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-14 15:19:24.442818', '22-2020', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№ЛР004269', '2020-03-17');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (333, '2020-04-14 15:20:29.17451', 107, 8, '2020-03-17', 3, 1, 8, 1, '2019-09-27', '2029-09-30', 1, '', 4, 6, 1, '8 скляних мірних піпеток на 10 мл', 'шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-14 15:20:29.17451', '23-2020', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№ЛР004269', '2020-03-17');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (334, '2020-04-14 15:25:01.088332', 106, 8, '2020-03-17', 3, 1, 8, 1, '2019-09-27', '2029-09-30', 1, '', 4, 6, 1, '8 скляних мірних піпеток на 5 мл', 'шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-14 15:25:01.088332', '24-2020', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№ЛР004269', '2020-03-17');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (338, '2020-04-14 15:34:49.533088', 103, 8, '2020-03-17', 3, 1, 8, 1, '2019-09-27', '2029-09-30', 1, '', 4, 6, 1, '8 скляних піпеток Мора на 2 мл', 'шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-14 15:34:49.533088', '28-2020', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№ЛР004269', '2020-03-17');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (339, '2020-04-14 15:41:32.743266', 104, 8, '2020-03-17', 3, 1, 8, 1, '2019-09-27', '2029-09-30', 0, '', 4, 6, 1, '8 скляних піпеток Мора на 5 мл', 'шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-14 15:41:32.743266', '29-2020', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№ЛР004269', '2020-03-17');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (331, '2020-04-14 15:11:20.414678', 172, 5000, '2020-03-17', 3, 1, 3500, 1, '2019-09-27', '2029-09-30', 1, '', 4, 6, 1, '10 упаковок із накінечниками до піпет-дозатора по 500 шт/уп', 'шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-14 15:11:20.414678', '21-2020', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№ЛР004269', '2020-03-17');
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
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (358, '2020-04-15 17:02:57.0342', 28, 200, '2020-03-17', 2, 1, 200, 11, '2019-08-21', '2020-08-20', 1, 'Китай', 2, 5, 1, '2 пакета із речовиною по 100 г', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-15 17:02:57.0342', '48-2020', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№ЛР004269', '2020-03-17');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (359, '2020-04-17 09:40:35.542173', 144, 50, '2020-03-17', 3, 1, 50, 7, '2020-01-17', '2022-01-17', 1, 'Польща', 2, 5, 1, '1 банка із речовиною 50 г', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-17 09:40:35.542173', '49-2020', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№ЛР004269', '2020-03-17');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (360, '2020-04-17 09:45:29.464029', 159, 30, '2020-03-17', 3, 1, 30, 7, '2019-02-21', '2022-02-21', 1, 'Китай', 2, 5, 1, '1 банка із речовиною 30 г', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-17 09:45:29.464029', '50-2020', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№ЛР004269', '2020-03-17');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (361, '2020-04-17 10:13:19.022187', 261, 100, '2020-03-17', 3, 1, 100, 11, '2019-01-16', '2021-01-15', 1, 'Китай', 2, 5, 1, '1 пакет із речовиною 100 г', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-17 10:13:19.022187', '51-2020', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№ЛР004269', '2020-03-17');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (362, '2020-04-17 10:14:58.35133', 8, 100, '2020-03-17', 3, 1, 100, 7, '2020-01-02', '2022-01-02', 1, 'Польща', 2, 5, 1, '1 пакет із речовиною 100 г', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-17 10:14:58.35133', '52-2020', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№ЛР004269', '2020-03-17');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (364, '2020-04-17 10:20:27.89365', 136, 500, '2020-03-17', 3, 1, 500, 7, '2019-11-05', '2022-11-30', 1, 'Франція', 2, 5, 1, '5 пакетів із речовиною по 100 г', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-17 10:20:27.89365', '54-2020', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№ЛР004269', '2020-03-17');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (365, '2020-04-17 10:24:24.445408', 241, 200, '2020-03-17', 3, 1, 200, 7, '2019-07-13', '2020-07-13', 1, 'Україна', 2, 5, 1, '2 пакета із речовиною по 100 г', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-17 10:24:24.445408', '55-2020', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№ЛР004269', '2020-03-17');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (367, '2020-04-17 10:41:44.874168', 212, 10000, '2020-03-17', 3, 1, 10000, 9, '2019-09-03', '2023-09-03', 1, 'CARLO ERBA REAGENTS', 1, 5, 1, '4 пялшки з прозорою рідиною по 2,5 л', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-17 10:41:44.874168', '57-2020', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№ЛР004269', '2020-03-17');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (368, '2020-04-17 10:56:09.771223', 52, 50, '2020-03-17', 3, 1, 50, 7, '2018-09-05', '2020-09-05', 1, 'Китай', 2, 5, 1, '1 банка із речовиною 50 г', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-17 10:56:09.771223', '58-2020', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№ЛР004269', '2020-03-17');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (369, '2020-04-17 10:58:00.957702', 46, 50, '2020-03-17', 3, 1, 50, 7, '2018-11-29', '2021-11-29', 1, 'Китай', 2, 5, 1, '1 банка із речовиною 50 г', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-17 10:58:00.957702', '59-2020', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№ЛР004269', '2020-03-17');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (370, '2020-04-17 10:59:33.065554', 138, 50, '2020-03-17', 3, 1, 50, 7, '2019-08-17', '2021-08-17', 1, 'Китай', 2, 5, 1, '1 банка із речовиною 50 г', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-17 10:59:33.065554', '60-2020', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№ЛР004269', '2020-03-17');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (371, '2020-04-17 11:08:28.7116', 238, 200, '2020-03-17', 3, 1, 200, 7, '2019-07-06', '2021-07-06', 1, 'Китай', 2, 5, 1, '2 пакета із речовиною по 100 г', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-17 11:08:28.7116', '61-2020', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№ЛР004269', '2020-03-17');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (372, '2020-04-17 11:17:24.267688', 272, 300, '2020-03-17', 3, 1, 300, 7, '2019-10-17', '2020-10-17', 1, 'Хемел', 2, 5, 1, '3 пакета із речовиною по 100 г', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-17 11:17:24.267688', '62-2020', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№ЛР004269', '2020-03-17');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (373, '2020-04-17 11:20:26.904166', 131, 100, '2020-03-17', 3, 1, 100, 8, '2019-07-17', '2022-07-17', 1, 'Україна', 2, 5, 1, '1 пакет із речовиною 100 г', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-17 11:20:26.904166', '63-2020', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№ЛР004269', '2020-03-17');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (363, '2020-04-17 10:17:13.723965', 271, 100, '2020-03-17', 3, 1, 0, 7, '2019-01-04', '2022-01-04', 1, 'Німеччина', 2, 5, 1, '1 пакет із речовиною 100 г', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-17 10:17:13.723965', '53-2020', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№ЛР004269', '2020-03-17');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (366, '2020-04-17 10:29:49.455861', 137, 200, '2020-03-17', 3, 1, 100, 7, '2019-09-24', '2021-09-23', 1, 'Індія', 2, 5, 1, '2 пакета із речовиною по 100 г', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-17 10:29:49.455861', '56-2020', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№ЛР004269', '2020-03-17');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (374, '2020-04-17 11:22:47.413013', 207, 100, '2020-03-17', 3, 1, 100, 8, '2019-07-17', '2020-07-17', 1, 'Росія', 2, 5, 1, '1 пакет із речовиною 100 г', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-17 11:22:47.413013', '64-2020', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№ЛР004269', '2020-03-17');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (375, '2020-04-17 11:24:28.320463', 259, 100, '2020-03-17', 3, 1, 100, 2, '2019-09-02', '2020-09-02', 1, 'Росія', 2, 5, 1, '1 пакет із речовиною 100 г', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-17 11:24:28.320463', '65-2020', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№ЛР004269', '2020-03-17');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (377, '2020-04-17 11:33:13.633349', 240, 100, '2020-03-17', 3, 1, 100, 2, '2019-07-12', '2021-07-12', 1, 'Китай', 2, 5, 1, '1 банка із речовиною 100 г', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-17 11:33:13.633349', '67-2020', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№ЛР004269', '2020-03-17');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (379, '2020-04-17 11:48:13.181463', 242, 600, '2020-03-17', 3, 1, 600, 11, '2018-06-07', '2021-06-07', 1, 'Франція', 2, 5, 1, '6 пакетів із речовиною по 100 г', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-17 11:48:13.181463', '69-2020', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№ЛР004269', '2020-03-17');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (378, '2020-04-17 11:39:20.9069', 59, 200, '2020-03-17', 3, 1, 200, 2, '2019-08-28', '2022-08-28', 1, 'Україна', 2, 5, 1, '2 банки із речовиною по 100 г', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-17 11:39:20.9069', '68-2020', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№ЛР004269', '2020-03-17');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (380, '2020-04-17 11:55:21.053272', 273, 100, '2020-03-17', 3, 1, 100, 7, '2019-06-03', '2022-06-30', 1, 'Франція', 2, 5, 1, '1 пакет із речовиною 100 г', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-17 11:55:21.053272', '70-2020', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№ЛР004269', '2020-03-17');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (382, '2020-04-17 12:01:23.859668', 12, 200, '2020-03-17', 3, 1, 200, 2, '2018-02-25', '2021-02-25', 1, 'Україна', 2, 5, 1, '2 пакети із речовиною по 100 г', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-17 12:01:23.859668', '72-2020', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№ЛР004269', '2020-03-17');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (383, '2020-04-17 12:05:23.229736', 45, 200, '2020-03-17', 3, 1, 200, 7, '2019-09-23', '2021-09-22', 1, 'Індія', 2, 5, 1, '2 пакети із речовиною по 100 г', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-17 12:05:23.229736', '73-2020', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№ЛР004269', '2020-03-17');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (384, '2020-04-17 12:09:59.875982', 150, 100, '2020-03-17', 3, 1, 100, 8, '2019-11-13', '2022-11-30', 1, 'Індія', 2, 5, 1, '1 пакет із речовиною 100 г', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-17 12:09:59.875982', '74-2020', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№ЛР004269', '2020-03-17');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (385, '2020-04-17 12:12:25.214867', 252, 100, '2020-03-17', 3, 1, 100, 1, '2020-01-20', '2021-01-20', 1, 'Індія', 2, 5, 1, '1 банка із речовиною 100 г', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-17 12:12:25.214867', '75-2020', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№ЛР004269', '2020-03-17');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (386, '2020-04-17 12:14:07.98837', 27, 100, '2020-03-17', 3, 1, 100, 11, '2019-04-01', '2024-03-31', 1, 'Індія', 2, 5, 1, '1 банка із речовиною 100 г', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-17 12:14:07.98837', '76-2020', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№ЛР004269', '2020-03-17');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (387, '2020-04-17 12:16:50.348703', 17, 100, '2020-03-17', 3, 1, 100, 2, '2013-08-01', '2023-07-31', 1, 'Німеччина', 2, 5, 1, '1 банка із речовиною 100 г', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-17 12:16:50.348703', '77-2020', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№ЛР004269', '2020-03-17');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (388, '2020-04-17 12:21:25.326404', 256, 100, '2020-03-17', 3, 1, 100, 2, '2019-10-06', '2020-10-05', 1, 'Китай', 2, 5, 1, '1 банка із речовиною 100 г', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-17 12:21:25.326404', '78-2020', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№ЛР004269', '2020-03-17');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (389, '2020-04-17 12:24:13.766746', 129, 500, '2020-03-17', 3, 1, 500, 7, '2019-12-03', '2020-12-03', 1, 'Китай', 2, 5, 1, '5 банок із речовиною по 100 г', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-17 12:24:13.766746', '79-2020', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№ЛР004269', '2020-03-17');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (390, '2020-04-17 13:56:54.042408', 3, 1000, '2020-03-17', 3, 1, 1000, 7, '2019-12-25', '2020-12-25', 1, 'Україна', 1, 5, 1, '1 пляшка із прозорою рідиною 1000 мл (1,0 кг)', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-17 13:56:54.042408', '80-2020', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№ЛР004269', '2020-03-17');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (376, '2020-04-17 11:30:29.928201', 43, 100, '2020-03-17', 3, 1, 0, 7, '2018-05-31', '2023-05-31', 1, 'Індія', 2, 5, 1, '2 банки із речовиною по 50 г', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-17 11:30:29.928201', '66-2020', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№ЛР004269', '2020-03-17');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (392, '2020-04-17 14:08:12.19341', 5, 1000, '2020-03-17', 3, 1, 1000, 2, '2020-02-03', '2020-08-03', 1, 'Україна', 1, 5, 1, '1 пляшка із прозорою рідиною 1000 мл (1,4 кг)', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-17 14:08:12.19341', '82-2020', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№ЛР004269', '2020-03-17');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (393, '2020-04-17 14:09:48.178237', 18, 1000, '2020-03-17', 3, 1, 1000, 11, '2020-01-10', '2021-01-10', 1, 'Німеччина', 1, 5, 1, '1 пляшка із прозорою рідиною 1 л (1,26 кг)', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-17 14:09:48.178237', '83-2020', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№ЛР004269', '2020-03-17');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (394, '2020-04-17 14:11:15.541687', 36, 1000, '2020-03-17', 3, 1, 1000, 2, '2019-01-08', '2021-01-07', 1, 'Китай', 1, 5, 1, '1 пляшка із прозорою рідиною 1 л (1,2 кг)', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-17 14:11:15.541687', '84-2020', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№ЛР004269', '2020-03-17');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (395, '2020-04-17 14:12:57.770359', 65, 2000, '2020-03-17', 3, 1, 2000, 7, '2019-09-27', '2021-09-27', 1, 'Нідерланди', 1, 5, 1, '2 пляшки із прозорою рідиною по 1 л (по 0,75 кг)', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-17 14:12:57.770359', '85-2020', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№ЛР004269', '2020-03-17');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (396, '2020-04-17 14:15:40.186774', 274, 1000, '2020-03-17', 3, 1, 1000, 7, '2019-05-18', '2022-05-18', 1, 'Росія', 1, 5, 1, '1 пляшка із прозорою рідиною 1 л (1,6 кг)', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-17 14:15:40.186774', '86-2020', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№ЛР004269', '2020-03-17');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (398, '2020-04-17 14:18:03.847174', 33, 1000, '2020-03-17', 3, 1, 1000, 1, '2019-08-01', '2021-08-01', 0, 'Китай', 1, 5, 1, '1 пляшка із прозорою рідиною 1 л (1,3 кг)', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-17 14:18:03.847174', '88-2020', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№ЛР004269', '2020-03-17');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (397, '2020-04-17 14:17:03.038489', 253, 1000, '2020-03-17', 3, 1, 1000, 7, '2019-07-21', '2021-07-21', 0, 'Україна', 1, 5, 1, '1 пляшка із прозорою рідиною 1 л (1,0 кг)', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-17 14:17:03.038489', '87-2020', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№ЛР004269', '2020-03-17');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (399, '2020-04-17 14:37:37.619777', 64, 5000, '2020-03-17', 3, 1, 5000, 11, '2019-07-31', '2021-07-31', 1, 'Франція', 1, 5, 1, '5 пляшок із прозорою рідиною по 1 л (по 1,5 кг)', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-17 14:37:37.619777', '89-2020', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№ЛР004269', '2020-03-17');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (400, '2020-04-17 14:40:03.135641', 14, 5000, '2020-03-17', 3, 1, 5000, 7, '2020-02-18', '2022-02-18', 1, 'Чехія', 1, 5, 1, '5 пляшок із прозорою рідиною по 1 л (по 0,9 кг)', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-17 14:40:03.135641', '90-2020', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№ЛР004269', '2020-03-17');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (401, '2020-04-17 14:56:01.659497', 51, 3000, '2020-03-17', 3, 1, 3000, 7, '2019-03-18', '2021-03-17', 1, 'Китай', 1, 5, 1, '3 пляшок із прозорою рідиною по 1 л (по 1,0 кг)', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-17 14:56:01.659497', '91-2020', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№ЛР004269', '2020-03-17');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (402, '2020-04-17 14:59:52.039402', 50, 2000, '2020-03-17', 3, 1, 2000, 11, '2019-04-15', '2021-04-04', 1, 'Китай', 1, 5, 1, '2 пляшок із прозорою рідиною по 1 л (по 1,8 кг)', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-17 14:59:52.039402', '92-2020', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№ЛР004269', '2020-03-17');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (403, '2020-04-17 15:09:15.393344', 141, 2000, '2020-03-17', 3, 1, 2000, 11, '2020-01-10', '2020-07-10', 1, 'Польща', 1, 5, 1, '2 пляшок із прозорою рідиною по 1 л (по 1,15 кг)', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-17 15:09:15.393344', '93-2020', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№ЛР004269', '2020-03-17');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (404, '2020-04-17 15:12:43.530091', 7, 5000, '2020-03-17', 1, 1, 4000, 7, '2020-01-09', '2021-01-09', 1, 'Україна', 1, 5, 1, '5 пляшок із прозорою рідиною по 1 л (по 0,9 кг)', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-17 15:12:43.530091', '94-2020', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№ЛР004269', '2020-03-17');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (391, '2020-04-17 13:59:39.735225', 20, 3000, '2020-03-17', 3, 1, 3000, 7, '2019-06-17', '2020-12-15', 1, 'Китай', 1, 5, 1, '3 пляшки із прозорою рідиною по 1000 мл (по 0,7 кг)', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-17 13:59:39.735225', '81-2020', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№ЛР004269', '2020-03-17');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (357, '2020-04-15 16:56:42.668003', 39, 1000, '2020-03-17', 3, 1, 900, 8, '2019-04-15', '2021-04-15', 1, 'Франція', 2, 5, 1, '10 банок із речовиною по 100 г', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-15 16:56:42.668003', '47-2020', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№ЛР004269', '2020-03-17');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (406, '2020-06-09 15:41:33.242192', 246, 1000, '2020-04-01', 3, 1, 1000, 1, '2020-03-01', '2030-03-01', 0, '', 4, 6, 1, '1 упаковка із папером фільтрувальним (100 шт)', 'шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-06-09 15:41:33.242192', '95-2020', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№ЛР004257', '2020-04-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (407, '2020-06-09 15:50:09.351556', 29, 10, '2020-03-17', 3, 1, 10, 7, '2020-01-09', '2022-01-09', 1, 'Alfa Aesar', 2, 5, 1, '1 пляшка із речовиною 10 г', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-06-09 15:50:09.351556', '96-2020', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№ЛР004263', '2020-03-17');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (408, '2020-06-09 16:10:42.871831', 171, 500, '2020-05-21', 3, 1, 500, 1, '2020-03-01', '2030-03-01', 0, '', 4, 6, 1, '1 упаковка з накінечниками на 10 мкл (500 шт)', 'шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-06-09 16:10:42.871831', '97-2020', 'ДНДЕКЦ МВС', '20-254', '2020-05-21');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (409, '2020-06-09 16:12:20.589647', 226, 500, '2020-05-21', 3, 1, 500, 1, '2020-03-01', '2030-03-01', 0, '', 4, 6, 1, '1 упаковка з накінечниками жовтими на 200 мкл (500 шт)', 'шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-06-09 16:12:20.589647', '98-2020', 'ДНДЕКЦ МВС', '20-254', '2020-05-21');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (410, '2020-06-09 16:13:15.342351', 172, 2000, '2020-05-21', 3, 1, 2000, 1, '2020-03-01', '2030-03-01', 0, '', 4, 6, 1, '4 упаковки з накінечниками блакитними на 1000 мкл (по 500 шт)', 'шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-06-09 16:13:15.342351', '99-2020', 'ДНДЕКЦ МВС', '20-254', '2020-05-21');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (411, '2020-06-09 16:15:05.537005', 228, 1000, '2020-05-21', 3, 1, 1000, 1, '2020-03-01', '2030-03-01', 0, '', 4, 6, 1, '1 упаковка з мікропробірками на 2 мкл (1000 шт)', 'шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-06-09 16:15:05.537005', '100-2020', 'ДНДЕКЦ МВС', '20-254', '2020-05-21');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (412, '2020-06-09 16:23:18.324825', 174, 100, '2020-05-21', 3, 1, 100, 1, '2020-03-01', '2030-03-01', 0, '', 4, 6, 1, '4 упаковки з алюмінієвими пластинами 20*20 см (по 25 шт)', 'шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-06-09 16:23:18.324825', '101-2020', 'ДНДЕКЦ МВС', '20-254', '2020-05-21');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (413, '2020-06-09 16:24:05.165931', 276, 200, '2020-05-21', 3, 1, 200, 1, '2020-03-01', '2030-03-01', 0, '', 4, 6, 1, '8 упаковки з пластиковими пластинами 20*20 см (по 25 шт)', 'шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-06-09 16:24:05.165931', '102-2020', 'ДНДЕКЦ МВС', '20-254', '2020-05-21');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (381, '2020-04-17 11:57:51.379872', 13, 400, '2020-03-17', 3, 1, 200, 7, '2019-11-18', '2022-11-18', 1, 'Україна', 2, 5, 1, '4 пакетів із речовиною по 100 г', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-17 11:57:51.379872', '71-2020', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№ЛР004269', '2020-03-17');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (315, '2020-04-13 16:15:24.950876', 174, 50, '2020-03-17', 3, 1, 25, 2, '2019-09-27', '2029-09-30', 0, 'МЕРК', 4, 6, 1, '2 упаковки (цілісність порушена) з пластинками по 25 шт/уп', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-13 16:15:24.950876', '5-2020', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№ЛР004276', '2020-03-17');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (414, '2020-06-09 16:30:31.000974', 191, 5200, '2020-05-21', 1, 1, 5200, 1, '2020-03-01', '2030-03-01', 0, '', 4, 6, 1, '50 упаковок з віалами та септами (по 100 шт)', 'шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-06-09 16:30:31.000974', '103-2020', 'ДНДЕКЦ МВС', '20-254', '2020-05-21');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (55, '2020-04-07 15:57:11.749814', 138, 100, '2016-04-04', 3, 1, 0, 7, '2016-03-01', '2021-03-01', 1, '', 2, 5, 1, '', 'шафа для реактивів к. 318', 'В темних шафах (холодильнику) за температури не вище 5 і не нижче 0 град. цельсію', '2020-04-07 15:57:11.749814', '36-2016', 'Сфера СІМ', '№РН-04122', '2016-04-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (202, '2020-04-10 11:34:53.092034', 226, 2000, '2019-07-01', 3, 1, 1000, 1, '2019-04-03', '2029-04-03', 0, '', 4, 6, 1, '2 упаковки (по 1000 шт) з жовтими накінечниками до піпет-дозатору на 10-200 мкл', 'лабораторія к. 317, шафа для розхідних матеріалів к. 313', 'В сухому захищеному від пошкодження місці', '2020-04-10 11:34:53.092034', '7-2019', 'ТОВ "ХІМЛАБОРРЕАКТИВ"', '№Х023251', '2019-07-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (1288, '2020-07-08 00:47:51.683464', 970, 2500, '2017-01-31', 1, 2, 1250, 11, '2016-12-24', '2025-07-07', 1, 'Тестовий виробник 32', 4, 1, 0, 'Запис створено автоматично', 'Тестове місце 57', 'Тестові умови 32', '2020-07-08 00:47:51.683464', '173-2017', 'Тестовий постачальник 85', 'b623afaaa64ce24c', '2017-01-31');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (1271, '2020-07-08 00:47:51.094493', 962, 2600, '2019-04-23', 1, 2, 2080, 1, '2019-03-25', '2022-07-08', 0, 'Тестовий виробник 31', 2, 3, 0, 'Запис створено автоматично', 'Тестове місце 98', 'Тестові умови 48', '2020-07-08 00:47:51.094493', '157-2019', 'Тестовий постачальник 83', 'a8e3a37fc9290354', '2019-04-23');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (1286, '2020-07-08 00:47:51.621525', 987, 2000, '2015-04-10', 1, 2, 1600, 2, '2015-03-20', '2022-07-08', 1, 'Тестовий виробник 16', 2, 1, 1, 'Запис створено автоматично', 'Тестове місце 26', 'Тестові умови 66', '2020-07-08 00:47:51.621525', '140-2015', 'Тестовий постачальник 93', '51d27edee20842d1', '2015-04-10');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (1289, '2020-07-08 00:47:51.721582', 979, 200, '2019-12-23', 1, 2, 100, 9, '2019-12-01', '2022-07-08', 0, 'Тестовий виробник 57', 4, 3, 1, 'Запис створено автоматично', 'Тестове місце 72', 'Тестові умови 30', '2020-07-08 00:47:51.721582', '160-2019', 'Тестовий постачальник 50', 'fe3c5782eb61b69b', '2019-12-23');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (1269, '2020-07-08 00:47:51.02093', 969, 1800, '2019-08-05', 1, 2, 900, 7, '2019-06-11', '2024-07-07', 1, 'Тестовий виробник 99', 1, 4, 1, 'Запис створено автоматично', 'Тестове місце 18', 'Тестові умови 11', '2020-07-08 00:47:51.02093', '156-2019', 'Тестовий постачальник 23', 'da4d5422c0dabe1c', '2019-08-05');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (1280, '2020-07-08 00:47:51.394646', 981, 200, '2019-06-23', 1, 2, 160, 10, '2019-04-04', '2023-07-08', 0, 'Тестовий виробник 8', 2, 6, 0, 'Запис створено автоматично', 'Тестове місце 4', 'Тестові умови 66', '2020-07-08 00:47:51.394646', '159-2019', 'Тестовий постачальник 88', '7e2df07d8027fd5a', '2019-06-23');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (1284, '2020-07-08 00:47:51.550184', 985, 800, '2015-04-30', 1, 2, 640, 1, '2015-04-18', '2022-07-08', 1, 'Тестовий виробник 58', 4, 3, 0, 'Запис створено автоматично', 'Тестове місце 79', 'Тестові умови 37', '2020-07-08 00:47:51.550184', '139-2015', 'Тестовий постачальник 62', '6fe047a2ce7bfdac', '2015-04-30');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (1275, '2020-07-08 00:47:51.227812', 966, 100, '2015-11-01', 1, 2, 80, 1, '2015-10-12', '2026-07-07', 1, 'Тестовий виробник 5', 4, 5, 1, 'Запис створено автоматично', 'Тестове місце 51', 'Тестові умови 97', '2020-07-08 00:47:51.227812', '137-2015', 'Тестовий постачальник 54', 'f538dae008e44586', '2015-11-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (1272, '2020-07-08 00:47:51.127751', 963, 2900, '2016-04-26', 1, 2, 2320, 11, '2016-02-09', '2025-07-07', 0, 'Тестовий виробник 40', 1, 3, 0, 'Запис створено автоматично', 'Тестове місце 1', 'Тестові умови 19', '2020-07-08 00:47:51.127751', '159-2016', 'Тестовий постачальник 40', 'eb3ffd5e4a629c6e', '2016-04-26');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (1270, '2020-07-08 00:47:51.061109', 961, 1000, '2017-02-28', 1, 2, 800, 10, '2016-11-25', '2022-07-08', 0, 'Тестовий виробник 77', 1, 4, 0, 'Запис створено автоматично', 'Тестове місце 28', 'Тестові умови 91', '2020-07-08 00:47:51.061109', '170-2017', 'Тестовий постачальник 95', '4e8e38e29319b010', '2017-02-28');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (1285, '2020-07-08 00:47:51.58351', 986, 400, '2017-02-22', 1, 2, 320, 11, '2017-02-03', '2022-07-08', 0, 'Тестовий виробник 36', 1, 5, 1, 'Запис створено автоматично', 'Тестове місце 87', 'Тестові умови 9', '2020-07-08 00:47:51.58351', '172-2017', 'Тестовий постачальник 9', 'fea62bdc7e029a03', '2017-02-22');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (1283, '2020-07-08 00:47:51.505566', 984, 1700, '2016-09-24', 1, 2, 1360, 7, '2016-06-19', '2025-07-07', 0, 'Тестовий виробник 78', 2, 4, 1, 'Запис створено автоматично', 'Тестове місце 83', 'Тестові умови 33', '2020-07-08 00:47:51.505566', '160-2016', 'Тестовий постачальник 89', '01be8a474c85237d', '2016-09-24');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (1273, '2020-07-08 00:47:51.161165', 964, 400, '2017-04-02', 1, 2, 300, 1, '2016-12-27', '2025-07-07', 0, 'Тестовий виробник 43', 4, 4, 1, 'Запис створено автоматично', 'Тестове місце 88', 'Тестові умови 29', '2020-07-08 00:47:51.161165', '171-2017', 'Тестовий постачальник 100', '2940c5c063e9f174', '2017-04-02');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (1282, '2020-07-08 00:47:51.461209', 983, 2800, '2015-05-13', 1, 2, 2100, 11, '2015-02-25', '2025-07-07', 1, 'Тестовий виробник 97', 4, 5, 1, 'Запис створено автоматично', 'Тестове місце 80', 'Тестові умови 84', '2020-07-08 00:47:51.461209', '138-2015', 'Тестовий постачальник 70', '21f43cf8fbc41d67', '2015-05-13');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (1276, '2020-07-08 00:47:51.261133', 967, 700, '2018-04-15', 1, 2, 466, 1, '2018-02-07', '2024-07-07', 0, 'Тестовий виробник 65', 1, 5, 0, 'Запис створено автоматично', 'Тестове місце 86', 'Тестові умови 87', '2020-07-08 00:47:51.261133', '163-2018', 'Тестовий постачальник 79', '3d9c6b12d1d12e2d', '2018-04-15');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (1279, '2020-07-08 00:47:51.365456', 989, 1400, '2018-04-26', 1, 2, 1050, 2, '2018-04-14', '2026-07-07', 1, 'Тестовий виробник 74', 4, 1, 1, 'Запис створено автоматично', 'Тестове місце 17', 'Тестові умови 96', '2020-07-08 00:47:51.365456', '164-2018', 'Тестовий постачальник 43', '4417e9ae0fafe9da', '2018-04-26');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (1268, '2020-07-08 00:47:50.967939', 960, 1300, '2016-11-04', 1, 2, 650, 11, '2016-09-11', '2022-07-08', 1, 'Тестовий виробник 93', 1, 4, 1, 'Запис створено автоматично', 'Тестове місце 1', 'Тестові умови 91', '2020-07-08 00:47:50.967939', '158-2016', 'Тестовий постачальник 19', '9a71593c9707645b', '2016-11-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (1306, '2020-07-08 00:47:52.321826', 997, 900, '2017-06-01', 1, 2, 450, 11, '2017-02-27', '2025-07-07', 0, 'Тестовий виробник 69', 2, 3, 1, 'Запис створено автоматично', 'Тестове місце 24', 'Тестові умови 75', '2020-07-08 00:47:52.321826', '181-2017', 'Тестовий постачальник 23', '828c337ea9869aed', '2017-06-01');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (1304, '2020-07-08 00:47:52.261239', 995, 600, '2018-11-14', 1, 2, 400, 8, '2018-09-05', '2024-07-07', 0, 'Тестовий виробник 77', 4, 1, 0, 'Запис створено автоматично', 'Тестове місце 25', 'Тестові умови 22', '2020-07-08 00:47:52.261239', '167-2018', 'Тестовий постачальник 61', 'b56e176b988e72ba', '2018-11-14');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (1294, '2020-07-08 00:47:51.905673', 975, 2800, '2017-08-26', 1, 2, 1866, 11, '2017-08-10', '2022-07-08', 1, 'Тестовий виробник 80', 4, 2, 1, 'Запис створено автоматично', 'Тестове місце 52', 'Тестові умови 60', '2020-07-08 00:47:51.905673', '175-2017', 'Тестовий постачальник 65', '952b12b4e79f5065', '2017-08-26');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (1281, '2020-07-08 00:47:51.428359', 982, 1100, '2020-03-15', 1, 2, 880, 10, '2020-01-16', '2022-07-08', 1, 'Тестовий виробник 43', 1, 6, 1, 'Запис створено автоматично', 'Тестове місце 49', 'Тестові умови 99', '2020-07-08 00:47:51.428359', '71-2020', 'Тестовий постачальник 49', '6bcac320557e3d33', '2020-03-15');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (1305, '2020-07-08 00:47:52.294654', 996, 1900, '2018-11-09', 1, 2, 1425, 11, '2018-08-06', '2026-07-07', 1, 'Тестовий виробник 45', 1, 6, 0, 'Запис створено автоматично', 'Тестове місце 9', 'Тестові умови 34', '2020-07-08 00:47:52.294654', '168-2018', 'Тестовий постачальник 81', 'b2565c1416c79ee0', '2018-11-09');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (1287, '2020-07-08 00:47:51.650071', 988, 1400, '2016-05-04', 1, 2, 1120, 7, '2016-04-12', '2022-07-08', 0, 'Тестовий виробник 44', 4, 1, 0, 'Запис створено автоматично', 'Тестове місце 29', 'Тестові умови 95', '2020-07-08 00:47:51.650071', '161-2016', 'Тестовий постачальник 29', 'd5ae5bd3203e169c', '2016-05-04');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (1293, '2020-07-08 00:47:51.861194', 974, 1900, '2018-03-24', 1, 2, 950, 2, '2017-12-28', '2026-07-07', 1, 'Тестовий виробник 9', 2, 2, 0, 'Запис створено автоматично', 'Тестове місце 22', 'Тестові умови 82', '2020-07-08 00:47:51.861194', '165-2018', 'Тестовий постачальник 5', '5426646fe168ed23', '2018-03-24');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (1295, '2020-07-08 00:47:51.950117', 976, 1600, '2018-05-20', 1, 2, 1200, 9, '2018-03-03', '2023-07-08', 0, 'Тестовий виробник 81', 1, 6, 0, 'Запис створено автоматично', 'Тестове місце 32', 'Тестові умови 43', '2020-07-08 00:47:51.950117', '166-2018', 'Тестовий постачальник 81', '0d1d9ab0793314a3', '2018-05-20');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (1290, '2020-07-08 00:47:51.750006', 971, 1700, '2015-03-07', 1, 2, 1133, 2, '2015-01-21', '2023-07-08', 1, 'Тестовий виробник 99', 1, 4, 1, 'Запис створено автоматично', 'Тестове місце 53', 'Тестові умови 66', '2020-07-08 00:47:51.750006', '141-2015', 'Тестовий постачальник 70', '05955b3a878fbec8', '2015-03-07');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (1291, '2020-07-08 00:47:51.794553', 972, 2600, '2017-01-11', 1, 2, 1300, 9, '2016-11-14', '2024-07-07', 0, 'Тестовий виробник 43', 2, 6, 1, 'Запис створено автоматично', 'Тестове місце 79', 'Тестові умови 66', '2020-07-08 00:47:51.794553', '174-2017', 'Тестовий постачальник 26', '509d155bd8624dda', '2017-01-11');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (1301, '2020-07-08 00:47:52.15037', 992, 2900, '2019-10-31', 1, 2, 2320, 8, '2019-10-19', '2025-07-07', 1, 'Тестовий виробник 40', 1, 3, 0, 'Запис створено автоматично', 'Тестове місце 44', 'Тестові умови 81', '2020-07-08 00:47:52.15037', '162-2019', 'Тестовий постачальник 39', '0f76ca4749b83120', '2019-10-31');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (1302, '2020-07-08 00:47:52.187625', 993, 2900, '2017-04-19', 1, 2, 1450, 8, '2017-01-21', '2026-07-07', 0, 'Тестовий виробник 18', 1, 3, 0, 'Запис створено автоматично', 'Тестове місце 39', 'Тестові умови 23', '2020-07-08 00:47:52.187625', '179-2017', 'Тестовий постачальник 88', '284eab6b3f4d15fd', '2017-04-19');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (1298, '2020-07-08 00:47:52.050142', 990, 3000, '2017-09-14', 1, 2, 1500, 9, '2017-06-27', '2026-07-07', 0, 'Тестовий виробник 22', 1, 4, 0, 'Запис створено автоматично', 'Тестове місце 41', 'Тестові умови 41', '2020-07-08 00:47:52.050142', '177-2017', 'Тестовий постачальник 36', '45a941bc276a48fe', '2017-09-14');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (1296, '2020-07-08 00:47:51.983585', 977, 2500, '2017-11-28', 1, 2, 2000, 9, '2017-09-27', '2024-07-07', 1, 'Тестовий виробник 11', 2, 2, 1, 'Запис створено автоматично', 'Тестове місце 95', 'Тестові умови 86', '2020-07-08 00:47:51.983585', '176-2017', 'Тестовий постачальник 55', 'd115f4a7cae30718', '2017-11-28');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (1303, '2020-07-08 00:47:52.216861', 994, 1300, '2017-12-29', 1, 2, 1040, 9, '2017-10-05', '2024-07-07', 1, 'Тестовий виробник 13', 1, 4, 1, 'Запис створено автоматично', 'Тестове місце 47', 'Тестові умови 62', '2020-07-08 00:47:52.216861', '180-2017', 'Тестовий постачальник 64', 'af320618994e3486', '2017-12-29');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (1297, '2020-07-08 00:47:52.021654', 978, 1100, '2016-02-13', 1, 2, 880, 1, '2015-11-28', '2025-07-07', 1, 'Тестовий виробник 71', 2, 2, 1, 'Запис створено автоматично', 'Тестове місце 21', 'Тестові умови 58', '2020-07-08 00:47:52.021654', '162-2016', 'Тестовий постачальник 41', '35c7598f1631a5f1', '2016-02-13');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (1299, '2020-07-08 00:47:52.083636', 999, 500, '2015-06-14', 1, 2, 400, 7, '2015-04-30', '2025-07-07', 0, 'Тестовий виробник 74', 4, 3, 1, 'Запис створено автоматично', 'Тестове місце 45', 'Тестові умови 99', '2020-07-08 00:47:52.083636', '142-2015', 'Тестовий постачальник 11', '787a8344b75afe1d', '2015-06-14');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (1300, '2020-07-08 00:47:52.121713', 991, 200, '2017-06-08', 1, 2, 160, 8, '2017-04-17', '2026-07-07', 0, 'Тестовий виробник 79', 1, 3, 1, 'Запис створено автоматично', 'Тестове місце 53', 'Тестові умови 94', '2020-07-08 00:47:52.121713', '178-2017', 'Тестовий постачальник 21', '85164ed0d890d8ef', '2017-06-08');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (1274, '2020-07-08 00:47:51.194534', 965, 1200, '2019-05-10', 1, 2, 900, 8, '2019-02-23', '2026-07-07', 0, 'Тестовий виробник 73', 1, 4, 1, 'Запис створено автоматично', 'Тестове місце 94', 'Тестові умови 22', '2020-07-08 00:47:51.194534', '158-2019', 'Тестовий постачальник 90', 'b9efa9cbe052debd', '2019-05-10');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (1292, '2020-07-08 00:47:51.825811', 973, 1100, '2019-07-22', 1, 2, 733, 11, '2019-07-03', '2026-07-07', 0, 'Тестовий виробник 52', 2, 3, 1, 'Запис створено автоматично', 'Тестове місце 74', 'Тестові умови 11', '2020-07-08 00:47:51.825811', '161-2019', 'Тестовий постачальник 19', '09b5d11e0fb58493', '2019-07-22');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (1278, '2020-07-08 00:47:51.327752', 980, 2600, '2020-02-28', 1, 2, 1950, 8, '2019-12-21', '2026-07-07', 0, 'Тестовий виробник 48', 1, 2, 1, 'Запис створено автоматично', 'Тестове місце 77', 'Тестові умови 88', '2020-07-08 00:47:51.327752', '70-2020', 'Тестовий постачальник 50', 'b3d0c719ddc12941', '2020-02-28');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (1277, '2020-07-08 00:47:51.29453', 968, 2200, '2020-06-11', 1, 2, 1760, 10, '2020-05-23', '2022-07-08', 0, 'Тестовий виробник 57', 4, 4, 0, 'Запис створено автоматично', 'Тестове місце 6', 'Тестові умови 63', '2020-07-08 00:47:51.29453', '69-2020', 'Тестовий постачальник 50', '39c8d6da608f6407', '2020-06-11');
INSERT INTO "public"."stock" ("id", "ts", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts", "reagent_number", "provider", "nakladna_num", "nakladna_date") VALUES (1307, '2020-07-08 00:47:52.350185', 998, 800, '2018-04-26', 1, 2, 533, 1, '2018-04-15', '2022-07-08', 0, 'Тестовий виробник 13', 4, 4, 1, 'Запис створено автоматично', 'Тестове місце 89', 'Тестові умови 91', '2020-07-08 00:47:52.350185', '169-2018', 'Тестовий постачальник 73', '4bfb37a21c05bca8', '2018-04-26');


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

INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('bfc0bfffe4427d00c1443738ff7dcafc', 5, '2018-07-03', 2, 'test-2018-679', '1970-01-01', 7, 'Тестове використання 2018-2', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('c97f06277101990d58e1dbf1bcc611fe', 1, '2020-04-21', 2, 'test-2020-144', '1970-01-01', 54, 'Тестове використання 2020-3', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('5ffe1b0204bf8dd0f1ee688299ef790f', 1, '2019-01-13', 2, 'test-2019-579', '1970-01-01', 42, 'Тестове використання 2019-4', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('48d07c7f98c102cd4b2913ef8f703394', 1, '2018-04-04', 2, 'test-2018-745', '1970-01-01', 98, 'Тестове використання 2018-5', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('09509dc742f04ad80f00ee9823ac1bbb', 5, '2020-04-30', 2, 'test-2020-851', '1970-01-01', 4, 'Тестове використання 2020-6', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('0e01087c5cc7ad8b2bd841dc7f28e145', 2, '2019-07-19', 2, 'test-2019-83', '1970-01-01', 42, 'Тестове використання 2019-7', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('07050dc3fea0deca94f34d0ff59e698b', 2, '2020-05-12', 2, 'test-2020-215', '1970-01-01', 64, 'Тестове використання 2020-8', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('8f1deac07ca16ac59a921764f49dac6f', 5, '2019-06-02', 2, 'test-2019-412', '1970-01-01', 58, 'Тестове використання 2019-9', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('209a6bbbec20bf120c482b1971fc9a86', 5, '2020-03-25', 2, 'test-2020-340', '1970-01-01', 5, 'Тестове використання 2020-10', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('feec65308df108cc5ab4531b5f8b1b5a', 5, '2020-05-09', 2, 'test-2020-111', '1970-01-01', 12, 'Тестове використання 2020-11', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('5c2a7ae114c5b4f7fc006ffd54669d3a', 2, '2016-03-03', 2, 'test-2016-71', '1970-01-01', 32, 'Тестове використання 2016-12', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('67773a3120921c0a09f8e95552b0a3fd', 2, '2019-03-30', 2, 'test-2019-377', '1970-01-01', 78, 'Тестове використання 2019-13', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('902a8bf2cac69ecec3902fccb824d885', 1, '2019-09-18', 2, 'test-2019-481', '1970-01-01', 7, 'Тестове використання 2019-14', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('8c17aac3ef9069baa2b395f54b87bc29', 1, '2019-01-14', 2, 'test-2019-275', '1970-01-01', 41, 'Тестове використання 2019-15', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('ec65a81a825f51bbf55517dee7ac2ee1', 2, '2020-06-10', 2, 'test-2020-586', '1970-01-01', 76, 'Тестове використання 2020-16', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('c56efdf9e1929defd261f66b215f1c5b', 2, '2019-12-16', 2, 'test-2019-637', '1970-01-01', 48, 'Тестове використання 2019-17', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('527d64e9f7819965cc25e152dac820ed', 1, '2020-04-10', 2, 'test-2020-25', '1970-01-01', 51, 'Тестове використання 2020-18', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('be6d1bdecb2fbbaa99abfeddeddce7bb', 5, '2017-06-06', 2, 'test-2017-392', '1970-01-01', 45, 'Тестове використання 2017-19', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('de49acd5d2e0aabf332d2c477a468ce7', 5, '2020-07-04', 2, 'test-2020-373', '1970-01-01', 31, 'Тестове використання 2020-20', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('575f8ec6389e33e05ca89aa2b03b16cb', 1, '2020-05-15', 2, 'test-2020-954', '1970-01-01', 20, 'Тестове використання 2020-21', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('b97b5a2241597dcb0d0a286aa3c2b72a', 1, '2019-08-15', 2, 'test-2019-880', '1970-01-01', 32, 'Тестове використання 2019-22', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('f4fb843feed1d47cb67de5e951b8ed25', 5, '2019-09-30', 2, 'test-2019-657', '1970-01-01', 42, 'Тестове використання 2019-23', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('55fd5331b4a67abff8f2a4bb1dbe7c5f', 2, '2020-06-11', 2, 'test-2020-971', '1970-01-01', 81, 'Тестове використання 2020-24', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('218f3fa909b15752467d271fa224c5f1', 5, '2020-05-04', 2, 'test-2020-407', '1970-01-01', 89, 'Тестове використання 2020-25', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('ba5b102a10d22ec34dae97a7c2cad677', 5, '2020-05-25', 2, 'test-2020-264', '1970-01-01', 25, 'Тестове використання 2020-26', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('0cf56a304a4826bdef3e2f25e468f675', 2, '2019-10-04', 2, 'test-2019-543', '1970-01-01', 18, 'Тестове використання 2019-27', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('8bef5026937e532e4a85f641292b3341', 5, '2020-04-27', 2, 'test-2020-541', '1970-01-01', 10, 'Тестове використання 2020-28', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('53fbaeba245b14f555a4b0529a568c3d', 2, '2020-03-05', 2, 'test-2020-350', '1970-01-01', 65, 'Тестове використання 2020-29', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('b127606e8fca823f574ba3bd6aba6a51', 1, '2017-04-16', 2, 'test-2017-161', '1970-01-01', 44, 'Тестове використання 2017-30', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('702121f666a6fa59d671aebe6b2f3dc6', 5, '2017-11-26', 2, 'test-2017-851', '1970-01-01', 11, 'Тестове використання 2017-31', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('b82e525688e956e9e63ca793b88060e2', 1, '2020-01-01', 2, 'test-2020-990', '1970-01-01', 73, 'Тестове використання 2020-32', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('8c8de92c656042dc4d4b319975010209', 1, '2020-02-07', 2, 'test-2020-937', '1970-01-01', 28, 'Тестове використання 2020-33', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('a6b48587bb55651be6b09aba0142f1d5', 5, '2017-05-20', 2, 'test-2017-107', '1970-01-01', 20, 'Тестове використання 2017-34', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('c4fbd4d8b210363a9e45b37a66528c6b', 1, '2020-04-21', 2, 'test-2020-399', '1970-01-01', 60, 'Тестове використання 2020-35', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('31111e4d4fd86709dc96f563ab5e64e9', 5, '2020-02-08', 2, 'test-2020-720', '1970-01-01', 1, 'Тестове використання 2020-36', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('a6d2b7226dc420a93506e12fe77701a3', 1, '2016-04-16', 2, 'test-2016-332', '1970-01-01', 95, 'Тестове використання 2016-37', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('391bd394d082d9b042679d547290a6b6', 1, '2020-04-06', 2, 'test-2020-402', '1970-01-01', 78, 'Тестове використання 2020-38', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('23373dbc310bcc976b5c0e15e90eab2e', 5, '2019-09-17', 2, 'test-2019-484', '1970-01-01', 62, 'Тестове використання 2019-39', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('ef049568db442527aad823cd255d89d5', 1, '2020-04-14', 2, 'test-2020-853', '1970-01-01', 90, 'Тестове використання 2020-40', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('0de0deada60fa8b96f1ecc0d6a4800de', 1, '2020-01-16', 2, 'test-2020-361', '1970-01-01', 86, 'Тестове використання 2020-41', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('4384d92068b511e5b0eafc949413a508', 5, '2020-03-23', 2, 'test-2020-910', '1970-01-01', 85, 'Тестове використання 2020-42', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('1187e55a2905d227fd4cf2f8105242ef', 5, '2018-12-19', 2, 'test-2018-834', '1970-01-01', 65, 'Тестове використання 2018-43', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('cdf00633079ce459f076c3ff8e02d291', 2, '2020-03-19', 2, 'test-2020-377', '1970-01-01', 45, 'Тестове використання 2020-44', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('5fd877af43b6212a95ba3539b7138a80', 1, '2020-03-17', 2, 'test-2020-610', '1970-01-01', 35, 'Тестове використання 2020-45', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('57841d2378ee6aed05bbca59bb601c00', 5, '2020-04-27', 2, 'test-2020-468', '1970-01-01', 90, 'Тестове використання 2020-46', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('b80a5071a9f78ccd0a4b364061b34da4', 1, '2020-03-21', 2, 'test-2020-31', '1970-01-01', 27, 'Тестове використання 2020-47', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('9e08241a3fdcbe3d98d29955a1abc091', 4, '2020-07-02', 1, '', '1970-01-01', 0, 'Використано за призначенням', '', 3);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('f47cac1eabb4a2759abee6ea3d67b38c', 2, '2018-06-16', 2, 'test-2018-740', '1970-01-01', 74, 'Тестове використання 2018-48', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('efebe2f22264f184b483b615e38a253c', 2, '2020-03-12', 2, 'test-2020-919', '1970-01-01', 86, 'Тестове використання 2020-49', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('53b21d506279be7ef4a030bbb7bfc8f5', 5, '2020-03-27', 2, 'test-2020-56', '1970-01-01', 37, 'Тестове використання 2020-50', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('ddae773ecdc3f922d1354fc12f9866d6', 2, '2020-05-11', 2, 'test-2020-212', '1970-01-01', 67, 'Тестове використання 2020-51', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('8c3d5de00fe9604f72f2e24036921327', 5, '2020-04-14', 2, 'test-2020-554', '1970-01-01', 77, 'Тестове використання 2020-52', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('7c24d1559a9d75968595708f4d69d80d', 2, '2020-06-12', 2, 'test-2020-608', '1970-01-01', 14, 'Тестове використання 2020-53', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('b23a7525b44438490047ad681fba2ebd', 1, '2020-02-02', 2, 'test-2020-353', '1970-01-01', 87, 'Тестове використання 2020-54', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('4d40a9884f4b0eb71e47f744c1b8b4a8', 1, '2020-03-15', 2, 'test-2020-11', '1970-01-01', 11, 'Тестове використання 2020-55', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('a7c121938ed19c4ba9cf452060f209f4', 5, '2020-07-04', 2, 'test-2020-656', '1970-01-01', 5, 'Тестове використання 2020-56', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('d34b8c719b4b0a4d51b904652282699e', 5, '2018-11-02', 2, 'test-2018-533', '1970-01-01', 71, 'Тестове використання 2018-57', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('37c0b81a4f3f1720ae120a07bf0c18f4', 1, '2017-03-20', 2, 'test-2017-788', '1970-01-01', 27, 'Тестове використання 2017-58', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('8a91804a02f6544b2ee2565996362c8b', 1, '2020-05-05', 2, 'test-2020-854', '1970-01-01', 83, 'Тестове використання 2020-59', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('09a0d9ba401a92d203e03ceb41768cd4', 1, '2020-07-05', 2, 'test-2020-136', '1970-01-01', 54, 'Тестове використання 2020-60', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('92e9e0dbacb60be592abb93d97761e8b', 5, '2020-06-10', 2, 'test-2020-599', '1970-01-01', 68, 'Тестове використання 2020-61', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('2be9e615388a54a4aa7e131a89b18e8f', 2, '2019-08-31', 2, 'test-2019-926', '1970-01-01', 38, 'Тестове використання 2019-62', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('ceb502d2c43a77dad8ba5bb3292e736d', 5, '2018-03-13', 2, 'test-2018-33', '1970-01-01', 39, 'Тестове використання 2018-63', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('67ee8de4d76482be15f37154c3cd7cb0', 1, '2019-08-30', 2, 'test-2019-305', '1970-01-01', 9, 'Тестове використання 2019-64', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('83468fb8ad911493c7b2ce41c21f1b83', 5, '2020-06-28', 2, 'test-2020-44', '1970-01-01', 68, 'Тестове використання 2020-65', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('adb030fbb53cb645ad4bd6e54b4fbb7e', 1, '2020-07-04', 2, 'test-2020-216', '1970-01-01', 34, 'Тестове використання 2020-66', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('c44cbc6fd59daf73c00fde117450133f', 2, '2020-06-10', 2, 'test-2020-150', '1970-01-01', 38, 'Тестове використання 2020-67', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('a39881291c261ec0be12c67487ac7b49', 2, '2019-12-07', 2, 'test-2019-785', '1970-01-01', 35, 'Тестове використання 2019-68', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('636a6ca797ed8b3165eef6e00f757e6b', 2, '2020-07-04', 2, 'test-2020-717', '1970-01-01', 55, 'Тестове використання 2020-69', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('43edebb6d871f5db8498ab573ea89452', 5, '2019-12-19', 2, 'test-2019-816', '1970-01-01', 97, 'Тестове використання 2019-70', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('eb6c384ea036c31025e66071682acf18', 2, '2020-07-05', 2, 'test-2020-692', '1970-01-01', 54, 'Тестове використання 2020-71', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('f6b0b72f2619b30f1ea89538ba2dabd6', 2, '2020-04-06', 2, 'test-2020-471', '1970-01-01', 65, 'Тестове використання 2020-72', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('aa19bdffd51796b3703d178e2b2e9495', 1, '2020-03-16', 2, 'test-2020-153', '1970-01-01', 42, 'Тестове використання 2020-73', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('0d4ceaa517b5c31729f65668e8c75358', 5, '2020-07-04', 2, 'test-2020-517', '1970-01-01', 41, 'Тестове використання 2020-74', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('1311a9982c7467b15f7e0246cb848716', 1, '2019-05-03', 2, 'test-2019-761', '1970-01-01', 26, 'Тестове використання 2019-75', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('59982851b8b1e6b38f2c338837066348', 2, '2020-05-26', 2, 'test-2020-690', '1970-01-01', 46, 'Тестове використання 2020-76', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('7e24584fcd1dcd1060681b7c1d04a919', 1, '2020-02-07', 2, 'test-2020-6', '1970-01-01', 26, 'Тестове використання 2020-77', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('fff0f3f1c8db7e21a9657679ac644305', 1, '2019-08-26', 2, 'test-2019-596', '1970-01-01', 80, 'Тестове використання 2019-78', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('82629bb992420c0c3db1e1782247cf65', 5, '2020-01-26', 2, 'test-2020-782', '1970-01-01', 3, 'Тестове використання 2020-79', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('d277bad47e2ee37fc06b04e7aad32dc6', 1, '2019-12-06', 2, 'test-2019-68', '1970-01-01', 60, 'Тестове використання 2019-80', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('85ff9b81bd2e709ea2ccaaa3158a91dd', 5, '2020-06-08', 2, 'test-2020-502', '1970-01-01', 20, 'Тестове використання 2020-81', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('c6d0b15025aa83a14744c696dfc4f8b3', 5, '2019-11-26', 2, 'test-2019-610', '1970-01-01', 40, 'Тестове використання 2019-82', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('f9212111e24601c846d6931f82ce304f', 2, '2018-12-12', 2, 'test-2018-743', '1970-01-01', 65, 'Тестове використання 2018-83', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('1555dc0fe8821c545006ee62178cec94', 2, '2020-03-12', 2, 'test-2020-243', '1970-01-01', 2, 'Тестове використання 2020-84', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('2130b9824c2e53fa0ca086a1ff1aaf66', 2, '2020-02-07', 2, 'test-2020-265', '1970-01-01', 81, 'Тестове використання 2020-85', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('d6644b15c9c0c0abf040e6c00b004628', 1, '2020-04-21', 2, 'test-2020-847', '1970-01-01', 40, 'Тестове використання 2020-86', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('785850a36be502d69ca1ae4c600e2f26', 1, '2019-10-21', 2, 'test-2019-7', '1970-01-01', 30, 'Тестове використання 2019-87', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('bc7b3be3017376df35202c004dbe5ec3', 5, '2020-03-15', 2, 'test-2020-598', '1970-01-01', 35, 'Тестове використання 2020-88', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('20a59b0f2d35fdf06280f6894036d354', 5, '2020-06-27', 2, 'test-2020-904', '1970-01-01', 66, 'Тестове використання 2020-89', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('184301881fb14d7d0a035c909d80e8ca', 5, '2018-05-29', 2, 'test-2018-490', '1970-01-01', 78, 'Тестове використання 2018-90', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('51f0ca0e3ad8b040fd67457d68439bd8', 1, '2019-02-24', 2, 'test-2019-546', '1970-01-01', 84, 'Тестове використання 2019-91', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('009ca7e9ddf3f0285eee5c68ddbc6c64', 1, '2020-06-16', 2, 'test-2020-887', '1970-01-01', 37, 'Тестове використання 2020-92', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('713b4cb50da304d5d46eec1e2afea8a3', 5, '2018-03-20', 2, 'test-2018-927', '1970-01-01', 98, 'Тестове використання 2018-93', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('ea84287b6093a6148571177994358967', 2, '2020-04-03', 2, 'test-2020-687', '1970-01-01', 68, 'Тестове використання 2020-94', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('b9339436008b5fdb3be4a23c8833609d', 1, '2017-12-06', 2, 'test-2017-242', '1970-01-01', 90, 'Тестове використання 2017-95', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('fbf43d440b3589be1c4e24d201842a1d', 5, '2020-07-06', 2, 'test-2020-773', '1970-01-01', 47, 'Тестове використання 2020-96', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('406dd65c452f55c67db4cae44641e303', 5, '2020-07-04', 2, 'test-2020-775', '1970-01-01', 40, 'Тестове використання 2020-97', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('a24d705bfa0c42d6d20d77a664b10150', 2, '2019-12-25', 2, 'test-2019-913', '1970-01-01', 79, 'Тестове використання 2019-98', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('3c8fddfa71e6b08014d8d203c07c0cd3', 5, '2019-12-05', 2, 'test-2019-874', '1970-01-01', 86, 'Тестове використання 2019-99', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('4827fc00b2eaba41e4d44bdfad9772e2', 2, '2020-07-04', 2, 'test-2020-279', '1970-01-01', 23, 'Тестове використання 2020-100', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('7b61773ac307174b2d11264f5020310c', 5, '2020-01-30', 2, 'test-2020-807', '1970-01-01', 92, 'Тестове використання 2020-2', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('31de707ec8d607dd8c063b3440b307d0', 5, '2020-03-16', 2, 'test-2020-396', '1970-01-01', 63, 'Тестове використання 2020-3', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('551d62a1dbe38278a0c141a7c3f5cf07', 5, '2019-06-26', 2, 'test-2019-723', '1970-01-01', 7, 'Тестове використання 2019-4', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('8a4254297ede04972d34bc4d0ca490ff', 5, '2020-05-30', 2, 'test-2020-346', '1970-01-01', 92, 'Тестове використання 2020-5', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('aacb7ccb3da54ac98c147eaead32a531', 5, '2020-03-22', 2, 'test-2020-915', '1970-01-01', 10, 'Тестове використання 2020-6', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('e4c3d668c6367becf3942d41217dcb94', 5, '2020-05-19', 2, 'test-2020-841', '1970-01-01', 63, 'Тестове використання 2020-7', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('a83019acd7e7dbba42be246406a7c108', 2, '2017-12-27', 2, 'test-2017-707', '1970-01-01', 26, 'Тестове використання 2017-8', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('b09046dad5687605e179b2d49794c2f7', 5, '2019-10-19', 2, 'test-2019-371', '1970-01-01', 88, 'Тестове використання 2019-9', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('1cea89293a4dc00b22543159118eeb22', 5, '2020-04-03', 2, 'test-2020-325', '1970-01-01', 26, 'Тестове використання 2020-10', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('52984d175e00c594760a6e359f543038', 5, '2020-07-06', 2, 'test-2020-798', '1970-01-01', 73, 'Тестове використання 2020-11', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('d9f1058c3c096a388a0df1721f1c9472', 1, '2020-07-06', 2, 'test-2020-898', '1970-01-01', 98, 'Тестове використання 2020-12', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('babb346028b5e28ba6c7a4ff041f841d', 5, '2017-03-29', 2, 'test-2017-917', '1970-01-01', 25, 'Тестове використання 2017-13', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('8c2b8fb26978f39a19fac76bafb4e7b8', 1, '2020-05-03', 2, 'test-2020-619', '1970-01-01', 68, 'Тестове використання 2020-14', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('e5433f4391863cf5a3dc58b11cbd54af', 5, '2019-11-18', 2, 'test-2019-679', '1970-01-01', 95, 'Тестове використання 2019-15', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('c7eb504470c5fd340d87e916d5b9c012', 2, '2020-03-24', 2, 'test-2020-943', '1970-01-01', 68, 'Тестове використання 2020-16', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('38d5c053b0b4fbb06ec953fd8f4fb945', 2, '2020-01-12', 2, 'test-2020-401', '1970-01-01', 14, 'Тестове використання 2020-17', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('b28a74fecee1b19561beccc62a361cd2', 2, '2019-12-24', 2, 'test-2019-110', '1970-01-01', 90, 'Тестове використання 2019-18', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('56b2ecffd32013185f8074292a4d1d61', 5, '2020-02-15', 2, 'test-2020-566', '1970-01-01', 28, 'Тестове використання 2020-19', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('852ff00f725609f35c9d11b8e2bcbbfa', 2, '2020-01-26', 2, 'test-2020-865', '1970-01-01', 8, 'Тестове використання 2020-20', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('84595d97cb2df42092be869c3a7ac02d', 1, '2020-07-06', 2, 'test-2020-526', '1970-01-01', 94, 'Тестове використання 2020-21', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('2d0d892a058fb84536d0ba6824cc8fd9', 2, '2019-08-28', 2, 'test-2019-94', '1970-01-01', 55, 'Тестове використання 2019-22', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('6d1fb453735d7c041fb45e1b50e2d9dd', 5, '2020-01-23', 2, 'test-2020-781', '1970-01-01', 93, 'Тестове використання 2020-23', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('7a7c3d975723a4e0eea6a410c956158a', 5, '2018-06-28', 2, 'test-2018-423', '1970-01-01', 34, 'Тестове використання 2018-24', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('a04bae4d5b99c08a01840c28ae10ec6f', 1, '2018-11-26', 2, 'test-2018-813', '1970-01-01', 33, 'Тестове використання 2018-25', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('dfb696c14c6dede09676c0b26e4ceda4', 5, '2019-07-16', 2, 'test-2019-972', '1970-01-01', 100, 'Тестове використання 2019-26', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('7cec65222a4b21e45409e6124613d66f', 1, '2020-01-16', 2, 'test-2020-808', '1970-01-01', 40, 'Тестове використання 2020-27', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('9f1e2ef759e79a32bbf177031ac381a2', 5, '2019-10-14', 2, 'test-2019-612', '1970-01-01', 30, 'Тестове використання 2019-28', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('edbf450293acd64f8940133c4163f927', 5, '2020-04-09', 2, 'test-2020-349', '1970-01-01', 44, 'Тестове використання 2020-29', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('0a705282fdbe8b5ad7de5ca97c0c89ca', 1, '2020-07-06', 2, 'test-2020-207', '1970-01-01', 83, 'Тестове використання 2020-30', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('7944666ea47eb89ed625f788e1dd3ead', 2, '2018-04-02', 2, 'test-2018-401', '1970-01-01', 80, 'Тестове використання 2018-31', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('6bb5381ccfece4e4d0b16f07f9e63452', 1, '2019-11-22', 2, 'test-2019-549', '1970-01-01', 59, 'Тестове використання 2019-32', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('8ed7d6ea281b0a5d9a28681960661c28', 1, '2019-08-18', 2, 'test-2019-690', '1970-01-01', 40, 'Тестове використання 2019-33', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('f69c4f545e3f0fd532692aef00acc5ad', 5, '2020-05-30', 2, 'test-2020-224', '1970-01-01', 69, 'Тестове використання 2020-34', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('77453a3152da2dba3be2a24ccf0ffd40', 2, '2020-02-20', 2, 'test-2020-75', '1970-01-01', 3, 'Тестове використання 2020-35', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('abb6eb79274604afc6534f43d314f98a', 5, '2018-08-04', 2, 'test-2018-517', '1970-01-01', 43, 'Тестове використання 2018-36', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('1c5f1f1e30fb47ce8eeaec8b23342ff8', 5, '2018-12-15', 2, 'test-2018-796', '1970-01-01', 61, 'Тестове використання 2018-37', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('bfc92e753f0d3992deead61421364dcc', 2, '2019-02-04', 2, 'test-2019-504', '1970-01-01', 58, 'Тестове використання 2019-38', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('9d39d89c83d3e855e0d26baf37507ec2', 2, '2020-06-30', 2, 'test-2020-329', '1970-01-01', 82, 'Тестове використання 2020-39', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('9b44106291d72900dc192f05d8248e6f', 2, '2018-04-07', 2, 'test-2018-759', '1970-01-01', 80, 'Тестове використання 2018-40', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('86bf14ec88a8ad08e316e8b2c108c788', 5, '2020-03-10', 2, 'test-2020-576', '1970-01-01', 6, 'Тестове використання 2020-41', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('e4a1e03a799c19b4794bc7271f288c1e', 2, '2020-07-04', 2, 'test-2020-595', '1970-01-01', 38, 'Тестове використання 2020-42', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('4d7867217f18fa91200bfa08856bb7ad', 2, '2020-04-23', 2, 'test-2020-373', '1970-01-01', 26, 'Тестове використання 2020-43', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('8f9f01a61e3f71f833e27ffd53af55d4', 5, '2018-09-22', 2, 'test-2018-811', '1970-01-01', 2, 'Тестове використання 2018-44', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('81aee1170a934ec479712fac583cd5cf', 1, '2019-10-31', 2, 'test-2019-807', '1970-01-01', 80, 'Тестове використання 2019-45', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('932d40168dede9edcf09da5939a6e598', 1, '2020-07-06', 2, 'test-2020-437', '1970-01-01', 27, 'Тестове використання 2020-46', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('12c396fe31245c57124829541a923fb8', 2, '2020-05-23', 2, 'test-2020-735', '1970-01-01', 32, 'Тестове використання 2020-47', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('9f877790499da7853b26c796bd600e95', 1, '2020-05-15', 2, 'test-2020-832', '1970-01-01', 42, 'Тестове використання 2020-48', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('bfe48c0438022de07411c54a96ebe928', 5, '2018-08-20', 2, 'test-2018-323', '1970-01-01', 82, 'Тестове використання 2018-49', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('b7989d5904bdca064daa222b24e84451', 2, '2018-02-06', 2, 'test-2018-849', '1970-01-01', 68, 'Тестове використання 2018-50', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('45f22fbd89c8d7d7fd282c03a97e19d1', 5, '2019-02-05', 2, 'test-2019-739', '1970-01-01', 34, 'Тестове використання 2019-51', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('f928912dd009e8a6e63ae5a8b03026ec', 1, '2020-07-04', 2, 'test-2020-330', '1970-01-01', 11, 'Тестове використання 2020-52', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('ddb424c44eb81aad3ac4e306d2b115a2', 5, '2020-02-23', 2, 'test-2020-852', '1970-01-01', 18, 'Тестове використання 2020-53', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('e8257d9dce99c1588c5f95e4f636dfec', 5, '2020-05-27', 2, 'test-2020-928', '1970-01-01', 62, 'Тестове використання 2020-54', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('2f983cce1d38929db6a7d8159efc7592', 5, '2020-07-05', 2, 'test-2020-792', '1970-01-01', 78, 'Тестове використання 2020-55', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('37442d116cb6551e0865fd340a20f3b2', 5, '2019-03-21', 2, 'test-2019-584', '1970-01-01', 57, 'Тестове використання 2019-56', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('d25abf7a800d00b40c57d8573bfaaaf7', 5, '2018-05-18', 2, 'test-2018-921', '1970-01-01', 80, 'Тестове використання 2018-57', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('45e95ade17dc026b2168c409ccc5f516', 2, '2020-03-28', 2, 'test-2020-671', '1970-01-01', 61, 'Тестове використання 2020-58', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('ff9809e15656af4d80ca4c32c2d77d4c', 5, '2020-05-06', 2, 'test-2020-863', '1970-01-01', 35, 'Тестове використання 2020-59', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('73eabe994b939cd9f3f45705264eb7e9', 2, '2017-05-07', 2, 'test-2017-416', '1970-01-01', 76, 'Тестове використання 2017-60', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('4dd724c2986bafe97805d45a7a634f98', 2, '2020-07-06', 2, 'test-2020-135', '1970-01-01', 17, 'Тестове використання 2020-61', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('872d28c19783b93b13e053df1924628b', 2, '2020-02-24', 2, 'test-2020-793', '1970-01-01', 12, 'Тестове використання 2020-62', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('8cb4ad30540db0fc0ee98e080623f086', 2, '2020-04-05', 2, 'test-2020-253', '1970-01-01', 73, 'Тестове використання 2020-63', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('7838c638bb76e98141e68b42273ccc8b', 1, '2020-04-29', 2, 'test-2020-547', '1970-01-01', 85, 'Тестове використання 2020-64', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('aba69cc22d1e7d455b335f3b6a3e35eb', 2, '2020-07-04', 2, 'test-2020-855', '1970-01-01', 84, 'Тестове використання 2020-65', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('a5dc651734940d6e96bae500fd91545f', 2, '2020-06-14', 2, 'test-2020-390', '1970-01-01', 19, 'Тестове використання 2020-66', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('26d934d9592e8149f98aecf24b06f721', 1, '2020-04-10', 2, 'test-2020-943', '1970-01-01', 39, 'Тестове використання 2020-67', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('a2fc5bf2a93ecef8938b35e930c28863', 5, '2018-07-29', 2, 'test-2018-262', '1970-01-01', 51, 'Тестове використання 2018-68', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('813304752aa40e1d7f02b2aebbaa1a35', 5, '2020-07-04', 2, 'test-2020-327', '1970-01-01', 84, 'Тестове використання 2020-69', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('7b20debb9ccb401e558dba42fdfedf9e', 2, '2020-07-06', 2, 'test-2020-175', '1970-01-01', 23, 'Тестове використання 2020-70', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('64c2ea10aa83b452bb760cb31509f900', 2, '2016-10-07', 2, 'test-2016-348', '1970-01-01', 96, 'Тестове використання 2016-71', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('e1fd4cbf7cbedcdaa8de71724d07a8e9', 1, '2019-04-01', 2, 'test-2019-174', '1970-01-01', 25, 'Тестове використання 2019-72', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('560c49e9f5dd59dc899a28eaed34a2dc', 5, '2019-01-09', 2, 'test-2019-861', '1970-01-01', 84, 'Тестове використання 2019-73', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('d73c8892147ee2d1dcc2cc59491cd8d2', 1, '2020-03-05', 2, 'test-2020-775', '1970-01-01', 36, 'Тестове використання 2020-74', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('63e9fcc8b161ad878a406a879d1b26da', 2, '2018-07-17', 2, 'test-2018-534', '1970-01-01', 64, 'Тестове використання 2018-75', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('f737629bb9b42abb5af951094f75062f', 5, '2020-01-16', 2, 'test-2020-591', '1970-01-01', 25, 'Тестове використання 2020-76', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('8177b34efb1c9a79205e9f5dee88f477', 5, '2020-03-22', 2, 'test-2020-243', '1970-01-01', 80, 'Тестове використання 2020-77', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('3278c49ed9ab128d8e2cc0ac90271aa7', 1, '2019-11-12', 2, 'test-2019-929', '1970-01-01', 99, 'Тестове використання 2019-78', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('74fdb202bca92558c2813d0b43380b4b', 1, '2018-06-06', 2, 'test-2018-740', '1970-01-01', 82, 'Тестове використання 2018-79', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('c53496c65ae5b31a6e1e4489b584ceb8', 5, '2019-08-31', 2, 'test-2019-254', '1970-01-01', 66, 'Тестове використання 2019-80', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('744be03b6e97d0d2ad40601b8977a9fd', 1, '2019-09-01', 2, 'test-2019-456', '1970-01-01', 56, 'Тестове використання 2019-81', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('85d1f96f9c090e7328977af6b02bed52', 5, '2020-05-24', 2, 'test-2020-202', '1970-01-01', 58, 'Тестове використання 2020-82', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('0174b4e651a03d50c03c7d0cf2477d1a', 2, '2019-11-19', 2, 'test-2019-735', '1970-01-01', 79, 'Тестове використання 2019-83', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('b46680b4764bf1e131e7a68d835d99d9', 5, '2020-02-10', 2, 'test-2020-129', '1970-01-01', 80, 'Тестове використання 2020-84', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('7e9f28c36f3cc78036ed52ace48ca048', 5, '2020-06-21', 2, 'test-2020-46', '1970-01-01', 9, 'Тестове використання 2020-85', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('87cac9e1332e12ae3b86780a06595d38', 1, '2019-08-22', 2, 'test-2019-160', '1970-01-01', 16, 'Тестове використання 2019-86', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('7d67da07816ddd51b26e5bc7b283afde', 5, '2020-05-25', 2, 'test-2020-168', '1970-01-01', 88, 'Тестове використання 2020-87', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('90f39aa27342a9ee112ee41001bf5626', 2, '2019-05-12', 2, 'test-2019-981', '1970-01-01', 34, 'Тестове використання 2019-88', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('800f5141037464bdfeb88b12bc8550c7', 1, '2019-07-23', 2, 'test-2019-784', '1970-01-01', 33, 'Тестове використання 2019-89', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('acf7cc208c3aa633ed5fb74ceb0d0847', 1, '2017-12-09', 2, 'test-2017-516', '1970-01-01', 35, 'Тестове використання 2017-90', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('de31d367c7a42d9d02716359011bfb74', 2, '2020-06-12', 2, 'test-2020-348', '1970-01-01', 77, 'Тестове використання 2020-91', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('4b524e73a75184005ba65dd156833f2a', 2, '2019-11-21', 2, 'test-2019-219', '1970-01-01', 32, 'Тестове використання 2019-92', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('2f2b0aca2e85a0db8e74b8dcb2d9feaa', 1, '2020-06-04', 2, 'test-2020-262', '1970-01-01', 27, 'Тестове використання 2020-93', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('0aada211b1bcbd14f01e367d5c301cc3', 2, '2020-06-07', 2, 'test-2020-803', '1970-01-01', 45, 'Тестове використання 2020-94', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('d3d18cdcf2dab63bde3bf513371ca20d', 5, '2017-12-27', 2, 'test-2017-826', '1970-01-01', 33, 'Тестове використання 2017-95', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('2839ae3b697f52a90e7beebfb40ba451', 2, '2020-06-02', 2, 'test-2020-195', '1970-01-01', 49, 'Тестове використання 2020-96', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('dbc4d2df82fc5506d1adfb4ced8416d2', 1, '2020-04-09', 2, 'test-2020-658', '1970-01-01', 12, 'Тестове використання 2020-97', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('e874c1a94c4d442bf09c8cfac0c61562', 2, '2017-11-09', 2, 'test-2017-839', '1970-01-01', 19, 'Тестове використання 2017-98', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('e0e48655963a0bf860c947c363ff9143', 1, '2020-02-22', 2, 'test-2020-688', '1970-01-01', 48, 'Тестове використання 2020-99', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('98763715261a09e2071cec405cbc1957', 2, '2018-09-26', 2, 'test-2018-881', '1970-01-01', 60, 'Тестове використання 2018-100', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('8562d3b6e4841dc8abc0ad4c189b6b31', 5, '2019-05-29', 2, 'test-2019-721', '1970-01-01', 60, 'Тестове використання 2019-2', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('9940882e65754fbd8544549c4bd40ec2', 5, '2020-05-12', 2, 'test-2020-314', '1970-01-01', 34, 'Тестове використання 2020-3', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('5bd7ededc9ce09228fa2fd44f6fac97a', 2, '2020-07-06', 2, 'test-2020-873', '1970-01-01', 85, 'Тестове використання 2020-4', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('fc3bf89648989d1f7566e0d1bdf24105', 5, '2015-08-23', 2, 'test-2015-882', '1970-01-01', 10, 'Тестове використання 2015-5', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('697cf65273ac243c0e0d02fdccf30f64', 1, '2019-11-16', 2, 'test-2019-404', '1970-01-01', 16, 'Тестове використання 2019-6', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('84ac0984c32b6698a5eed82a9b61f40b', 1, '2020-06-28', 2, 'test-2020-457', '1970-01-01', 88, 'Тестове використання 2020-7', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('3d610029d33565e29a6e881758836560', 5, '2020-04-06', 2, 'test-2020-756', '1970-01-01', 63, 'Тестове використання 2020-8', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('d8d5b7e0d1eafdb9f950cf0edac4f614', 1, '2020-02-22', 2, 'test-2020-160', '1970-01-01', 100, 'Тестове використання 2020-9', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('011aa6ba065ee4681a77e7f23068d021', 2, '2019-09-26', 2, 'test-2019-511', '1970-01-01', 73, 'Тестове використання 2019-10', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('caaab10820e8c0fafa296b111a0c55d7', 1, '2018-11-26', 2, 'test-2018-436', '1970-01-01', 63, 'Тестове використання 2018-11', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('d82c3abc50b0b52edebbf7c1b22b4f63', 1, '2020-06-11', 2, 'test-2020-44', '1970-01-01', 32, 'Тестове використання 2020-12', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('9512c0f09801f3b2623442744e15a959', 2, '2019-08-19', 2, 'test-2019-147', '1970-01-01', 62, 'Тестове використання 2019-13', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('a4025f3b3077b558a5f8412cb0b9c6d8', 2, '2020-01-23', 2, 'test-2020-561', '1970-01-01', 45, 'Тестове використання 2020-14', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('030f1460a85382190d983f1bb483808a', 1, '2020-07-06', 2, 'test-2020-445', '1970-01-01', 72, 'Тестове використання 2020-15', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('bde889116c5bf6c826cfa935ed395e0e', 2, '2020-05-28', 2, 'test-2020-29', '1970-01-01', 43, 'Тестове використання 2020-16', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('2f70e8ba91b8381487e0bd6f35e8c460', 1, '2017-06-06', 2, 'test-2017-759', '1970-01-01', 32, 'Тестове використання 2017-17', '', 1);
INSERT INTO "public"."using" ("hash", "purpose_id", "date", "group_id", "exp_number", "exp_date", "obj_count", "tech_info", "ucomment", "expert_id") VALUES ('de302762ff46c456ddc29647b79c48a9', 5, '2019-03-05', 2, 'test-2019-425', '1970-01-01', 69, 'Тестове використання 2019-18', '', 1);


--
-- Name: access_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('"public"."access_id_seq"', 4, true);


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

SELECT pg_catalog.setval('"public"."dispersion_id_seq"', 1005, true);


--
-- Name: expert_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('"public"."expert_id_seq"', 8, true);


--
-- Name: groups_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('"public"."groups_id_seq"', 3, true);


--
-- Name: purpose_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('"public"."purpose_id_seq"', 6, true);


--
-- Name: reactiv_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('"public"."reactiv_id_seq"', 1, false);


--
-- Name: reactiv_menu_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('"public"."reactiv_menu_id_seq"', 113, true);


--
-- Name: reagent_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('"public"."reagent_id_seq"', 999, true);


--
-- Name: reagent_state_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('"public"."reagent_state_id_seq"', 4, true);


--
-- Name: region_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('"public"."region_id_seq"', 2, true);


--
-- Name: spr_access_actions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('"public"."spr_access_actions_id_seq"', 16, true);


--
-- Name: stock_gr_0_2020_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('"public"."stock_gr_0_2020_seq"', 3, true);


--
-- Name: stock_gr_1_2010_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('"public"."stock_gr_1_2010_seq"', 1, true);


--
-- Name: stock_gr_1_2011_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('"public"."stock_gr_1_2011_seq"', 3, true);


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

SELECT pg_catalog.setval('"public"."stock_gr_1_2020_seq"', 103, true);


--
-- Name: stock_gr_2_2015_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('"public"."stock_gr_2_2015_seq"', 142, true);


--
-- Name: stock_gr_2_2016_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('"public"."stock_gr_2_2016_seq"', 162, true);


--
-- Name: stock_gr_2_2017_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('"public"."stock_gr_2_2017_seq"', 181, true);


--
-- Name: stock_gr_2_2018_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('"public"."stock_gr_2_2018_seq"', 169, true);


--
-- Name: stock_gr_2_2019_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('"public"."stock_gr_2_2019_seq"', 162, true);


--
-- Name: stock_gr_2_2020_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('"public"."stock_gr_2_2020_seq"', 71, true);


--
-- Name: stock_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('"public"."stock_id_seq"', 1307, true);


--
-- Name: units_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('"public"."units_id_seq"', 9, true);


--
-- Name: access access_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."access"
    ADD CONSTRAINT "access_pkey" PRIMARY KEY ("id");


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
-- Name: consume_using consume_using_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."consume_using"
    ADD CONSTRAINT "consume_using_unique" UNIQUE ("consume_hash", "using_hash");


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
-- Name: groups groups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."groups"
    ADD CONSTRAINT "groups_pkey" PRIMARY KEY ("id");


--
-- Name: prolongation prolongation_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."prolongation"
    ADD CONSTRAINT "prolongation_pkey" PRIMARY KEY ("hash");


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
-- Name: reactiv_consume_using reactiv_consume_using_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."reactiv_consume_using"
    ADD CONSTRAINT "reactiv_consume_using_unique" UNIQUE ("consume_hash", "using_hash");


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
-- Name: reactiv_menu_reactives reactiv_menu_reactives_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."reactiv_menu_reactives"
    ADD CONSTRAINT "reactiv_menu_reactives_pkey" PRIMARY KEY ("unique_index");


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
-- Name: spr_access_actions spr_access_actions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."spr_access_actions"
    ADD CONSTRAINT "spr_access_actions_pkey" PRIMARY KEY ("id");


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
-- Name: consume_date_part_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "consume_date_part_idx" ON "public"."consume" USING "btree" ("date_part"('month'::"text", "date"));


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
-- Name: reactiv_menu_reactives trig_MAKE_RECIPE_REACT_UNIQUE_INDEX_TRIG; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER "trig_MAKE_RECIPE_REACT_UNIQUE_INDEX_TRIG" BEFORE INSERT OR UPDATE ON "public"."reactiv_menu_reactives" FOR EACH ROW EXECUTE PROCEDURE "public"."MAKE_RECIPE_REACT_UNIQUE_INDEX_TRIG"();


--
-- Name: access_actions access_actions_access_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."access_actions"
    ADD CONSTRAINT "access_actions_access_id_fkey" FOREIGN KEY ("access_id") REFERENCES "public"."access"("id") ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: access_actions access_actions_action_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."access_actions"
    ADD CONSTRAINT "access_actions_action_id_fkey" FOREIGN KEY ("action_id") REFERENCES "public"."spr_access_actions"("id") ON UPDATE CASCADE ON DELETE CASCADE;


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
-- Name: consume_using consume_using_consume_hash_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."consume_using"
    ADD CONSTRAINT "consume_using_consume_hash_fkey" FOREIGN KEY ("consume_hash") REFERENCES "public"."consume"("hash") ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: consume_using consume_using_using_hash_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."consume_using"
    ADD CONSTRAINT "consume_using_using_hash_fkey" FOREIGN KEY ("using_hash") REFERENCES "public"."using"("hash") ON UPDATE CASCADE ON DELETE CASCADE;


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
-- Name: expert expert_access_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."expert"
    ADD CONSTRAINT "expert_access_id_fkey" FOREIGN KEY ("access_id") REFERENCES "public"."access"("id") ON UPDATE CASCADE ON DELETE SET DEFAULT;


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
-- Name: prolongation prolongation_expert_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."prolongation"
    ADD CONSTRAINT "prolongation_expert_id_fkey" FOREIGN KEY ("expert_id") REFERENCES "public"."expert"("id") ON UPDATE CASCADE ON DELETE SET DEFAULT;


--
-- Name: prolongation prolongation_stock_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."prolongation"
    ADD CONSTRAINT "prolongation_stock_id_fkey" FOREIGN KEY ("stock_id") REFERENCES "public"."stock"("id") ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: reactiv_consume reactiv_consume_reactive_hash_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."reactiv_consume"
    ADD CONSTRAINT "reactiv_consume_reactive_hash_fkey" FOREIGN KEY ("reactiv_hash") REFERENCES "public"."reactiv"("hash") ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: reactiv_consume_using reactiv_consume_using_consume_hash_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."reactiv_consume_using"
    ADD CONSTRAINT "reactiv_consume_using_consume_hash_fkey" FOREIGN KEY ("consume_hash") REFERENCES "public"."reactiv_consume"("hash") ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: reactiv_consume_using reactiv_consume_using_using_hash_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."reactiv_consume_using"
    ADD CONSTRAINT "reactiv_consume_using_using_hash_fkey" FOREIGN KEY ("using_hash") REFERENCES "public"."using"("hash") ON UPDATE CASCADE ON DELETE CASCADE;


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
-- Name: reactiv_ingr_reactiv reactiv_ingr_reactiv_consume_hash_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."reactiv_ingr_reactiv"
    ADD CONSTRAINT "reactiv_ingr_reactiv_consume_hash_fkey" FOREIGN KEY ("consume_hash") REFERENCES "public"."reactiv_consume"("hash") ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: reactiv_ingr_reactiv reactiv_ingr_reactiv_reactiv_hash_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."reactiv_ingr_reactiv"
    ADD CONSTRAINT "reactiv_ingr_reactiv_reactiv_hash_fkey" FOREIGN KEY ("reactiv_hash") REFERENCES "public"."reactiv"("hash") ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: reactiv_ingr_reagent reactiv_ingr_reagent_consume_hash_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."reactiv_ingr_reagent"
    ADD CONSTRAINT "reactiv_ingr_reagent_consume_hash_fkey" FOREIGN KEY ("consume_hash") REFERENCES "public"."consume"("hash") ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: reactiv_ingr_reagent reactiv_ingr_reagent_reactiv_hash_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."reactiv_ingr_reagent"
    ADD CONSTRAINT "reactiv_ingr_reagent_reactiv_hash_fkey" FOREIGN KEY ("reactiv_hash") REFERENCES "public"."reactiv"("hash") ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: reactiv_menu reactiv_menu_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."reactiv_menu"
    ADD CONSTRAINT "reactiv_menu_group_id_fkey" FOREIGN KEY ("group_id") REFERENCES "public"."groups"("id") ON UPDATE CASCADE ON DELETE CASCADE;


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
-- Name: reactiv_menu_reactives reactiv_menu_reactives_reactiv_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."reactiv_menu_reactives"
    ADD CONSTRAINT "reactiv_menu_reactives_reactiv_id_fkey" FOREIGN KEY ("reactiv_id") REFERENCES "public"."reactiv_menu"("id") ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: reactiv_menu_reactives reactiv_menu_reactives_reactiv_menu_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."reactiv_menu_reactives"
    ADD CONSTRAINT "reactiv_menu_reactives_reactiv_menu_id_fkey" FOREIGN KEY ("reactiv_menu_id") REFERENCES "public"."reactiv_menu"("id") ON UPDATE CASCADE ON DELETE CASCADE;


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
-- Name: reagent reagent_created_by_expert_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."reagent"
    ADD CONSTRAINT "reagent_created_by_expert_id_fkey" FOREIGN KEY ("created_by_expert_id") REFERENCES "public"."expert"("id") ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: reagent reagent_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."reagent"
    ADD CONSTRAINT "reagent_group_id_fkey" FOREIGN KEY ("group_id") REFERENCES "public"."groups"("id") ON UPDATE CASCADE ON DELETE CASCADE;


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
-- Name: using using_expert_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."using"
    ADD CONSTRAINT "using_expert_id_fkey" FOREIGN KEY ("expert_id") REFERENCES "public"."expert"("id") ON UPDATE CASCADE ON DELETE CASCADE;


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

