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
		EXECUTE 'SELECT COUNT(hash) as c FROM ' || tab_name || ' WHERE hash=' || quote_literal( rhash ) INTO cnt; 

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
-- Name: composition; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE "public"."composition" (
    "consume_hash" character varying(32) DEFAULT 0 NOT NULL,
    "reactiv_hash" character varying(32) DEFAULT 0 NOT NULL
);


--
-- Name: consume; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE "public"."consume" (
    "hash" character varying(32) DEFAULT "public"."generate_hash"('consume'::"text") NOT NULL,
    "ts" timestamp(6) without time zone DEFAULT ("now"())::timestamp without time zone NOT NULL,
    "dispersion_id" bigint DEFAULT 0 NOT NULL,
    "inc_expert_id" bigint DEFAULT 0 NOT NULL,
    "out_expert_id" bigint DEFAULT 0 NOT NULL,
    "quantity" double precision DEFAULT 0 NOT NULL
);


--
-- Name: COLUMN "consume"."inc_expert_id"; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN "public"."consume"."inc_expert_id" IS 'Хто отримав для використання';


--
-- Name: COLUMN "consume"."out_expert_id"; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN "public"."consume"."out_expert_id" IS 'Хто видав для використання';


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
    "region_id" integer DEFAULT 0 NOT NULL,
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
    "region_id" integer DEFAULT 0 NOT NULL,
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
    "full_name" character varying(255) DEFAULT ''::character varying NOT NULL
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
    "ts" timestamp(6) without time zone DEFAULT ("now"())::timestamp without time zone NOT NULL
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
    "quantity_left" double precision DEFAULT 0 NOT NULL
);


--
-- Name: reactiv_consume; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE "public"."reactiv_consume" (
    "hash" character varying(32) DEFAULT "public"."generate_hash"('reactiv_consume'::"text") NOT NULL,
    "reactive_hash" character varying(32) DEFAULT ''::character varying NOT NULL,
    "quantity" double precision DEFAULT 0 NOT NULL
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
    "position" integer DEFAULT 0 NOT NULL
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
    "quantity" double precision DEFAULT 0 NOT NULL
);


--
-- Name: reagent; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE "public"."reagent" (
    "id" bigint NOT NULL,
    "ts" timestamp(6) without time zone DEFAULT ("now"())::timestamp without time zone NOT NULL,
    "units" character varying(32) DEFAULT ''::character varying NOT NULL,
    "name" character varying(255) DEFAULT ''::character varying NOT NULL,
    "created_by_expert_id" bigint DEFAULT 0 NOT NULL
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
    "region_id" integer DEFAULT 0 NOT NULL,
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
    "created_ts" timestamp(6) without time zone DEFAULT ("now"())::timestamp without time zone NOT NULL
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
-- Data for Name: clearence; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO "public"."clearence" ("id", "name", "position") VALUES (0, '--', 0);
INSERT INTO "public"."clearence" ("id", "name", "position") VALUES (1, 'Хуйова', 0);
INSERT INTO "public"."clearence" ("id", "name", "position") VALUES (2, 'Хароша', 0);
INSERT INTO "public"."clearence" ("id", "name", "position") VALUES (4, 'Мутняк', 0);


--
-- Data for Name: composition; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: consume; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "out_expert_id", "quantity") VALUES ('0', '2020-01-02 15:37:30.168681', 0, 0, 0, 0);
INSERT INTO "public"."consume" ("hash", "ts", "dispersion_id", "inc_expert_id", "out_expert_id", "quantity") VALUES ('e237637c008f2af947fa174c4ea86f8d', '2020-03-11 11:25:43.954161', 4, 1, 0, 0.699999999999999956);


--
-- Data for Name: danger_class; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO "public"."danger_class" ("id", "name", "position") VALUES (0, '--', 0);
INSERT INTO "public"."danger_class" ("id", "name", "position") VALUES (2, 'Страшне', 0);
INSERT INTO "public"."danger_class" ("id", "name", "position") VALUES (1, 'Піздєц яке страшне', 0);
INSERT INTO "public"."danger_class" ("id", "name", "position") VALUES (3, 'Хуйня', 0);


--
-- Data for Name: dispersion; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO "public"."dispersion" ("id", "stock_id", "ts", "inc_expert_id", "out_expert_id", "quantity_inc", "quantity_left", "region_id", "group_id", "inc_date", "comment", "created_ts") VALUES (0, 0, '2020-01-02 15:37:24.48078', 0, 0, 0, 0, 0, 0, '1970-01-01', '', '2020-03-13 11:54:36.766118+02');
INSERT INTO "public"."dispersion" ("id", "stock_id", "ts", "inc_expert_id", "out_expert_id", "quantity_inc", "quantity_left", "region_id", "group_id", "inc_date", "comment", "created_ts") VALUES (4, 3, '2020-01-02 15:44:29.526382', 1, 1, 20, 19.3000000000000007, 1, 1, '2020-03-11', '', '2020-03-13 11:54:36.766118+02');


--
-- Data for Name: expert; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO "public"."expert" ("id", "region_id", "surname", "name", "phname", "visible", "ts", "login", "password", "token", "group_id", "last_ip") VALUES (0, 0, '', '', '', 1, '2019-12-28 11:10:20.623791', '', '', '', 0, '0.0.0.0');
INSERT INTO "public"."expert" ("id", "region_id", "surname", "name", "phname", "visible", "ts", "login", "password", "token", "group_id", "last_ip") VALUES (1, 1, 'Пташкін', 'Роман', 'Леонідович', 1, '2019-12-29 23:17:39.53982', 'root', '855cb86bd065112c52899ef9ea7b9918', 'bdd722eae62e2a9681d345e946e5db4e', 1, '192.168.2.127');


--
-- Data for Name: expertise; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO "public"."expertise" ("id", "region_id", "eint", "inc_date") VALUES (0, 0, '0', '1970-01-01');


--
-- Data for Name: groups; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO "public"."groups" ("id", "ts", "name", "full_name") VALUES (0, '2019-12-28 11:09:48.499219', '--', '--');
INSERT INTO "public"."groups" ("id", "ts", "name", "full_name") VALUES (1, '2019-12-29 23:20:15.009224', 'root', 'root');


--
-- Data for Name: purpose; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO "public"."purpose" ("id", "name", "ts") VALUES (0, '--', '2019-12-28 11:09:37.583434');


--
-- Data for Name: reactiv; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: reactiv_consume; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: reactiv_menu; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO "public"."reactiv_menu" ("id", "name", "position") VALUES (0, '--', 0);
INSERT INTO "public"."reactiv_menu" ("id", "name", "position") VALUES (1, 'Бухло', 0);


--
-- Data for Name: reactiv_menu_ingredients; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO "public"."reactiv_menu_ingredients" ("reagent_id", "reactiv_menu_id", "quantity") VALUES (22, 1, 0);
INSERT INTO "public"."reactiv_menu_ingredients" ("reagent_id", "reactiv_menu_id", "quantity") VALUES (64, 1, 0);
INSERT INTO "public"."reactiv_menu_ingredients" ("reagent_id", "reactiv_menu_id", "quantity") VALUES (16, 1, 0);


--
-- Data for Name: reagent; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO "public"."reagent" ("id", "ts", "units", "name", "created_by_expert_id") VALUES (10, '2020-01-02 15:39:01.529732', 'Літри', 'Ацетон', 1);
INSERT INTO "public"."reagent" ("id", "ts", "units", "name", "created_by_expert_id") VALUES (2, '2020-01-02 15:39:01.529732', 'Літри', '1,3 - Динітробензол', 1);
INSERT INTO "public"."reagent" ("id", "ts", "units", "name", "created_by_expert_id") VALUES (8, '2020-01-02 15:39:01.529732', 'Літри', 'Амоній молібденовокислий', 1);
INSERT INTO "public"."reagent" ("id", "ts", "units", "name", "created_by_expert_id") VALUES (0, '2019-12-28 11:10:26.287818', 'Літри', '--', 0);
INSERT INTO "public"."reagent" ("id", "ts", "units", "name", "created_by_expert_id") VALUES (4, '2020-01-02 15:39:01.529732', 'Літри', 'N, N - диметилформамід', 0);
INSERT INTO "public"."reagent" ("id", "ts", "units", "name", "created_by_expert_id") VALUES (5, '2020-01-02 15:39:01.529732', 'Літри', 'Азотна кислота', 0);
INSERT INTO "public"."reagent" ("id", "ts", "units", "name", "created_by_expert_id") VALUES (6, '2020-01-02 15:39:01.529732', 'Літри', 'Альдегід оцтовий', 0);
INSERT INTO "public"."reagent" ("id", "ts", "units", "name", "created_by_expert_id") VALUES (7, '2020-01-02 15:39:01.529732', 'Літри', 'Аміак 25%', 0);
INSERT INTO "public"."reagent" ("id", "ts", "units", "name", "created_by_expert_id") VALUES (9, '2020-01-02 15:39:01.529732', 'Літри', 'Аргентум нітрат', 0);
INSERT INTO "public"."reagent" ("id", "ts", "units", "name", "created_by_expert_id") VALUES (11, '2020-01-02 15:39:01.529732', 'Літри', 'Ацетонітрил', 0);
INSERT INTO "public"."reagent" ("id", "ts", "units", "name", "created_by_expert_id") VALUES (12, '2020-01-02 15:39:01.529732', 'Літри', 'Барій сульфат', 0);
INSERT INTO "public"."reagent" ("id", "ts", "units", "name", "created_by_expert_id") VALUES (13, '2020-01-02 15:39:01.529732', 'Літри', 'Барію хлорид', 0);
INSERT INTO "public"."reagent" ("id", "ts", "units", "name", "created_by_expert_id") VALUES (14, '2020-01-02 15:39:01.529732', 'Літри', 'Бензол', 0);
INSERT INTO "public"."reagent" ("id", "ts", "units", "name", "created_by_expert_id") VALUES (15, '2020-01-02 15:39:01.529732', 'Літри', 'Бутанол', 0);
INSERT INTO "public"."reagent" ("id", "ts", "units", "name", "created_by_expert_id") VALUES (16, '2020-01-02 15:39:01.529732', 'Літри', 'Ванілін', 0);
INSERT INTO "public"."reagent" ("id", "ts", "units", "name", "created_by_expert_id") VALUES (17, '2020-01-02 15:39:01.529732', 'Літри', 'Вісмут нітрат', 0);
INSERT INTO "public"."reagent" ("id", "ts", "units", "name", "created_by_expert_id") VALUES (18, '2020-01-02 15:39:01.529732', 'Літри', 'Гліцерин', 0);
INSERT INTO "public"."reagent" ("id", "ts", "units", "name", "created_by_expert_id") VALUES (19, '2020-01-02 15:39:01.529732', 'Літри', 'Дифенілкарбазон', 0);
INSERT INTO "public"."reagent" ("id", "ts", "units", "name", "created_by_expert_id") VALUES (20, '2020-01-02 15:39:01.529732', 'Літри', 'Діетиламін', 0);
INSERT INTO "public"."reagent" ("id", "ts", "units", "name", "created_by_expert_id") VALUES (21, '2020-01-02 15:39:01.529732', 'Літри', 'Діетиловий ефір', 0);
INSERT INTO "public"."reagent" ("id", "ts", "units", "name", "created_by_expert_id") VALUES (22, '2020-01-02 15:39:01.529732', 'Літри', 'Етанол', 0);
INSERT INTO "public"."reagent" ("id", "ts", "units", "name", "created_by_expert_id") VALUES (23, '2020-01-02 15:39:01.529732', 'Літри', 'Етилацетат', 0);
INSERT INTO "public"."reagent" ("id", "ts", "units", "name", "created_by_expert_id") VALUES (24, '2020-01-02 15:39:01.529732', 'Літри', 'Ефір діізопропіловий', 0);
INSERT INTO "public"."reagent" ("id", "ts", "units", "name", "created_by_expert_id") VALUES (25, '2020-01-02 15:39:01.529732', 'Літри', 'Ізопропанол', 0);
INSERT INTO "public"."reagent" ("id", "ts", "units", "name", "created_by_expert_id") VALUES (3, '2020-01-02 15:39:01.529732', 'Літри', '1,4-Диоксан', 1);
INSERT INTO "public"."reagent" ("id", "ts", "units", "name", "created_by_expert_id") VALUES (26, '2020-01-02 15:39:01.529732', 'Літри', 'Калій гідроксид', 0);
INSERT INTO "public"."reagent" ("id", "ts", "units", "name", "created_by_expert_id") VALUES (27, '2020-01-02 15:39:01.529732', 'Літри', 'Калію йодид', 0);
INSERT INTO "public"."reagent" ("id", "ts", "units", "name", "created_by_expert_id") VALUES (28, '2020-01-02 15:39:01.529732', 'Літри', 'Кальцію хлорид б/в', 0);
INSERT INTO "public"."reagent" ("id", "ts", "units", "name", "created_by_expert_id") VALUES (29, '2020-01-02 15:39:01.529732', 'Літри', 'Кобальт тіоціонат', 0);
INSERT INTO "public"."reagent" ("id", "ts", "units", "name", "created_by_expert_id") VALUES (30, '2020-01-02 15:39:01.529732', 'Літри', 'Магній сульфат', 0);
INSERT INTO "public"."reagent" ("id", "ts", "units", "name", "created_by_expert_id") VALUES (31, '2020-01-02 15:39:01.529732', 'Літри', 'Меркурій (ІІ) хлорид', 0);
INSERT INTO "public"."reagent" ("id", "ts", "units", "name", "created_by_expert_id") VALUES (32, '2020-01-02 15:39:01.529732', 'Літри', 'Метанол', 0);
INSERT INTO "public"."reagent" ("id", "ts", "units", "name", "created_by_expert_id") VALUES (33, '2020-01-02 15:39:01.529732', 'Літри', 'Метилен хлористий', 0);
INSERT INTO "public"."reagent" ("id", "ts", "units", "name", "created_by_expert_id") VALUES (34, '2020-01-02 15:39:01.529732', 'Літри', 'Метилстеарат для ГХ', 0);
INSERT INTO "public"."reagent" ("id", "ts", "units", "name", "created_by_expert_id") VALUES (35, '2020-01-02 15:39:01.529732', 'Літри', 'Мідь (ІІ) сульфат', 0);
INSERT INTO "public"."reagent" ("id", "ts", "units", "name", "created_by_expert_id") VALUES (36, '2020-01-02 15:39:01.529732', 'Літри', 'Мурашина кислота', 0);
INSERT INTO "public"."reagent" ("id", "ts", "units", "name", "created_by_expert_id") VALUES (37, '2020-01-02 15:39:01.529732', 'Літри', 'Натрій ванадат', 0);
INSERT INTO "public"."reagent" ("id", "ts", "units", "name", "created_by_expert_id") VALUES (38, '2020-01-02 15:39:01.529732', 'Літри', 'Натрій гідрокарбонат', 0);
INSERT INTO "public"."reagent" ("id", "ts", "units", "name", "created_by_expert_id") VALUES (39, '2020-01-02 15:39:01.529732', 'Літри', 'Натрій гідроксид', 0);
INSERT INTO "public"."reagent" ("id", "ts", "units", "name", "created_by_expert_id") VALUES (40, '2020-01-02 15:39:01.529732', 'Літри', 'Натрій карбонат', 0);
INSERT INTO "public"."reagent" ("id", "ts", "units", "name", "created_by_expert_id") VALUES (41, '2020-01-02 15:39:01.529732', 'Літри', 'Натрій молібдат', 0);
INSERT INTO "public"."reagent" ("id", "ts", "units", "name", "created_by_expert_id") VALUES (42, '2020-01-02 15:39:01.529732', 'Літри', 'Натрій нітрит', 0);
INSERT INTO "public"."reagent" ("id", "ts", "units", "name", "created_by_expert_id") VALUES (43, '2020-01-02 15:39:01.529732', 'Літри', 'Натрій нітропрусид', 0);
INSERT INTO "public"."reagent" ("id", "ts", "units", "name", "created_by_expert_id") VALUES (44, '2020-01-02 15:39:01.529732', 'Літри', 'Натрій сульфат б/в', 0);
INSERT INTO "public"."reagent" ("id", "ts", "units", "name", "created_by_expert_id") VALUES (45, '2020-01-02 15:39:01.529732', 'Літри', 'Натрію хлорид', 0);
INSERT INTO "public"."reagent" ("id", "ts", "units", "name", "created_by_expert_id") VALUES (46, '2020-01-02 15:39:01.529732', 'Літри', 'Нафтол альфа', 0);
INSERT INTO "public"."reagent" ("id", "ts", "units", "name", "created_by_expert_id") VALUES (47, '2020-01-02 15:39:01.529732', 'Літри', 'н-Гексан', 0);
INSERT INTO "public"."reagent" ("id", "ts", "units", "name", "created_by_expert_id") VALUES (48, '2020-01-02 15:39:01.529732', 'Літри', 'Нінгідрин', 0);
INSERT INTO "public"."reagent" ("id", "ts", "units", "name", "created_by_expert_id") VALUES (49, '2020-01-02 15:39:01.529732', 'Літри', 'о-Ксилол', 0);
INSERT INTO "public"."reagent" ("id", "ts", "units", "name", "created_by_expert_id") VALUES (50, '2020-01-02 15:39:01.529732', 'Літри', 'Ортофосфорна кислота', 0);
INSERT INTO "public"."reagent" ("id", "ts", "units", "name", "created_by_expert_id") VALUES (51, '2020-01-02 15:39:01.529732', 'Літри', 'Оцтова кислота, льодяна', 0);
INSERT INTO "public"."reagent" ("id", "ts", "units", "name", "created_by_expert_id") VALUES (52, '2020-01-02 15:39:01.529732', 'Літри', 'п-Диметиламінобензальдегід', 0);
INSERT INTO "public"."reagent" ("id", "ts", "units", "name", "created_by_expert_id") VALUES (53, '2020-01-02 15:39:01.529732', 'Літри', 'Петролейний ефір', 0);
INSERT INTO "public"."reagent" ("id", "ts", "units", "name", "created_by_expert_id") VALUES (54, '2020-01-02 15:39:01.529732', 'Літри', 'Піридин', 0);
INSERT INTO "public"."reagent" ("id", "ts", "units", "name", "created_by_expert_id") VALUES (55, '2020-01-02 15:39:01.529732', 'Літри', 'Платина VI хлорид', 0);
INSERT INTO "public"."reagent" ("id", "ts", "units", "name", "created_by_expert_id") VALUES (56, '2020-01-02 15:39:01.529732', 'Літри', 'Сульфанілова кислота', 0);
INSERT INTO "public"."reagent" ("id", "ts", "units", "name", "created_by_expert_id") VALUES (57, '2020-01-02 15:39:01.529732', 'Літри', 'Сульфатна кислота концентрована', 0);
INSERT INTO "public"."reagent" ("id", "ts", "units", "name", "created_by_expert_id") VALUES (58, '2020-01-02 15:39:01.529732', 'Літри', 'Толуол', 0);
INSERT INTO "public"."reagent" ("id", "ts", "units", "name", "created_by_expert_id") VALUES (59, '2020-01-02 15:39:01.529732', 'Літри', 'Тривкий синій Б', 0);
INSERT INTO "public"."reagent" ("id", "ts", "units", "name", "created_by_expert_id") VALUES (60, '2020-01-02 15:39:01.529732', 'Літри', 'Фенолфталеїн', 0);
INSERT INTO "public"."reagent" ("id", "ts", "units", "name", "created_by_expert_id") VALUES (61, '2020-01-02 15:39:01.529732', 'Літри', 'Ферум (ІІІ) хлорид', 0);
INSERT INTO "public"."reagent" ("id", "ts", "units", "name", "created_by_expert_id") VALUES (62, '2020-01-02 15:39:01.529732', 'Літри', 'Формальдегід', 0);
INSERT INTO "public"."reagent" ("id", "ts", "units", "name", "created_by_expert_id") VALUES (63, '2020-01-02 15:39:01.529732', 'Літри', 'Хлоридна кислота концентрована', 0);
INSERT INTO "public"."reagent" ("id", "ts", "units", "name", "created_by_expert_id") VALUES (64, '2020-01-02 15:39:01.529732', 'Літри', 'Хлороформ', 0);
INSERT INTO "public"."reagent" ("id", "ts", "units", "name", "created_by_expert_id") VALUES (65, '2020-01-02 15:39:01.529732', 'Літри', 'Циклогексан', 0);


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

INSERT INTO "public"."stock" ("id", "ts", "region_id", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts") VALUES (0, '2020-01-02 15:37:14.580544', 0, 0, 0, '2020-01-01', 0, 0, 0, 0, '1970-01-01', '1970-01-01', 0, '', 0, 0, 0, '', '', '', '2020-03-12 09:48:19.879959');
INSERT INTO "public"."stock" ("id", "ts", "region_id", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts") VALUES (7, '2020-03-12 17:40:18.36426', 1, 22, 10, '2020-01-01', 1, 1, 10, 2, '2019-07-10', '2021-05-13', 0, 'Самжене', 1, 1, 0, '', 'В пляшках', 'Шоб холодненька була', '2020-03-12 17:40:18.36426');
INSERT INTO "public"."stock" ("id", "ts", "region_id", "reagent_id", "quantity_inc", "inc_date", "inc_expert_id", "group_id", "quantity_left", "clearence_id", "create_date", "dead_date", "is_sertificat", "creator", "reagent_state_id", "danger_class_id", "is_suitability", "comment", "safe_place", "safe_needs", "created_ts") VALUES (3, '2020-01-02 15:40:23.725801', 1, 10, 200, '2020-01-01', 1, 1, 180, 2, '2019-01-01', '2023-01-01', 1, 'Юрія-фарм', 2, 2, 1, 'хуйня', 'тестове місце', 'тестові умови', '2020-03-12 09:48:19.879959');


--
-- Name: clearence_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('"public"."clearence_id_seq"', 4, true);


--
-- Name: consume_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('"public"."consume_id_seq"', 8, true);


--
-- Name: danger_class_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('"public"."danger_class_id_seq"', 3, true);


--
-- Name: dispersion_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('"public"."dispersion_id_seq"', 7, true);


--
-- Name: expert_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('"public"."expert_id_seq"', 1, true);


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

SELECT pg_catalog.setval('"public"."purpose_id_seq"', 1, false);


--
-- Name: reactiv_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('"public"."reactiv_id_seq"', 1, false);


--
-- Name: reactiv_menu_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('"public"."reactiv_menu_id_seq"', 1, true);


--
-- Name: reagent_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('"public"."reagent_id_seq"', 80, true);


--
-- Name: reagent_state_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('"public"."reagent_state_id_seq"', 2, true);


--
-- Name: region_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('"public"."region_id_seq"', 1, true);


--
-- Name: stock_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('"public"."stock_id_seq"', 7, true);


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
    ADD CONSTRAINT "reactiv_menu_ingredients_pkey" PRIMARY KEY ("reagent_id");


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
-- Name: dispersion UPDATE_DISPERSION_QUANTITY_SELF_TRIG_tr; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER "UPDATE_DISPERSION_QUANTITY_SELF_TRIG_tr" BEFORE INSERT OR UPDATE ON "public"."dispersion" FOR EACH ROW EXECUTE PROCEDURE "public"."UPDATE_DISPERSION_QUANTITY_SELF_TRIG"();


--
-- Name: consume UPDATE_DISPERSION_QUANTITY_TRIG_cons; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER "UPDATE_DISPERSION_QUANTITY_TRIG_cons" AFTER INSERT OR DELETE OR UPDATE ON "public"."consume" FOR EACH ROW EXECUTE PROCEDURE "public"."UPDATE_DISPERSION_QUANTITY_TRIG"();


--
-- Name: stock UPDATE_STOCK_QUANTITY_SELF_TRIG_tr; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER "UPDATE_STOCK_QUANTITY_SELF_TRIG_tr" BEFORE INSERT OR UPDATE ON "public"."stock" FOR EACH ROW EXECUTE PROCEDURE "public"."UPDATE_STOCK_QUANTITY_SELF_TRIG"();


--
-- Name: dispersion UPDATE_STOCK_QUANTITY_in_disp; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER "UPDATE_STOCK_QUANTITY_in_disp" AFTER INSERT OR DELETE OR UPDATE ON "public"."dispersion" FOR EACH ROW EXECUTE PROCEDURE "public"."UPDATE_STOCK_QUANTITY_TRIG"();


--
-- Name: composition composition_consume_hash_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."composition"
    ADD CONSTRAINT "composition_consume_hash_fkey" FOREIGN KEY ("consume_hash") REFERENCES "public"."consume"("hash") ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: composition composition_reactiv_hash_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."composition"
    ADD CONSTRAINT "composition_reactiv_hash_fkey" FOREIGN KEY ("reactiv_hash") REFERENCES "public"."reactiv"("hash") ON UPDATE CASCADE ON DELETE CASCADE;


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
-- Name: consume consume_out_expert_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."consume"
    ADD CONSTRAINT "consume_out_expert_id_fkey" FOREIGN KEY ("out_expert_id") REFERENCES "public"."expert"("id") ON UPDATE CASCADE ON DELETE CASCADE;


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
-- Name: dispersion dispersion_region_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."dispersion"
    ADD CONSTRAINT "dispersion_region_id_fkey" FOREIGN KEY ("region_id") REFERENCES "public"."region"("id") ON UPDATE CASCADE ON DELETE CASCADE;


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
-- Name: expert expert_region_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."expert"
    ADD CONSTRAINT "expert_region_id_fkey" FOREIGN KEY ("region_id") REFERENCES "public"."region"("id") ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: reactiv_consume reactiv_consume_reactive_hash_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."reactiv_consume"
    ADD CONSTRAINT "reactiv_consume_reactive_hash_fkey" FOREIGN KEY ("reactive_hash") REFERENCES "public"."reactiv"("hash") ON UPDATE CASCADE ON DELETE CASCADE;


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
-- Name: stock stock_region_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."stock"
    ADD CONSTRAINT "stock_region_id_fkey" FOREIGN KEY ("region_id") REFERENCES "public"."region"("id") ON UPDATE CASCADE ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

