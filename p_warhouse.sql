--
-- PostgreSQL database dump
--

-- Dumped from database version 13.2
-- Dumped by pg_dump version 13.2

-- Started on 2021-05-27 21:55:16

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
-- TOC entry 246 (class 1255 OID 17048)
-- Name: costmedicine(money); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.costmedicine(m_price money) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
declare
	answer VARCHAR(20);
BEGIN
   CASE 
   	    WHEN m_price <= money(100) THEN
		     answer = 'Дешёвое';
		WHEN m_price > money(100) AND m_price <= money(500) THEN
			 answer = 'Средняя цена';
		WHEN m_price > money(500) THEN
			 answer = 'Дорогое';
	END CASE;
	
	RETURN answer;
END;
$$;


ALTER FUNCTION public.costmedicine(m_price money) OWNER TO postgres;

--
-- TOC entry 231 (class 1255 OID 17017)
-- Name: countmedicinepharmagroup(character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.countmedicinepharmagroup(p_group character varying) RETURNS integer
    LANGUAGE plpgsql
    AS $$
declare
	number integer;
BEGIN
   SELECT sum(department_stores_medicine.number) 
   INTO number 
   FROM medicine 
   JOIN pharmacological_group ON pharmacological_group.id = medicine.id_pharmacological_group
   JOIN department_stores_medicine ON department_stores_medicine.id_medicine = medicine.id
   WHERE pharmacological_group.name = p_group;
   RETURN number;
END;
$$;


ALTER FUNCTION public.countmedicinepharmagroup(p_group character varying) OWNER TO postgres;

--
-- TOC entry 243 (class 1255 OID 17079)
-- Name: isqzone(character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.isqzone(m_name character varying) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
declare
	answer record;
BEGIN
   	SELECT medicine.date_quarantine_zone
	INTO answer
	FROM medicine
	WHERE medicine.name = m_name;
	
	IF answer.date_quarantine_zone IS NULL THEN 
	   RETURN VARCHAR(20)'Хорошее';
	ELSE 
	   RETURN VARCHAR(20)'В карантине';
	END IF;
END;
$$;


ALTER FUNCTION public.isqzone(m_name character varying) OWNER TO postgres;

--
-- TOC entry 248 (class 1255 OID 17053)
-- Name: lowercostmed(money); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.lowercostmed(cost money) RETURNS TABLE(m_name character varying, m_price money)
    LANGUAGE plpgsql
    AS $$
BEGIN
   RETURN QUERY
      SELECT medicine.name, medicine.price
	  FROM medicine
	  WHERE medicine.price <= cost;
END;
$$;


ALTER FUNCTION public.lowercostmed(cost money) OWNER TO postgres;

--
-- TOC entry 245 (class 1255 OID 17047)
-- Name: voyageafterdate(timestamp without time zone); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.voyageafterdate(date timestamp without time zone) RETURNS TABLE(dest_point character varying, number integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
	answer record;
BEGIN
   FOR answer in(SELECT voyage.destination_point, COUNT(*)
				 FROM voyage
				 JOIN pharmacy_warhouse ON pharmacy_warhouse.address != voyage.destination_point
				 JOIN worker ON worker.id_warhouse = pharmacy_warhouse.id 
				 JOIN contract ON contract.id_worker = worker.id AND contract.id = voyage.id_contract
				 WHERE voyage.start_date_time > date
      			 GROUP BY voyage.destination_point
				 ORDER BY count DESC) 
   LOOP dest_point := answer.destination_point; 
		number := answer.count;
        return next;
   END LOOP;
END;
$$;


ALTER FUNCTION public.voyageafterdate(date timestamp without time zone) OWNER TO postgres;

--
-- TOC entry 244 (class 1255 OID 17044)
-- Name: weightsindep(character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.weightsindep(name_st_dep character varying) RETURNS TABLE(weight character varying, num_weight integer)
    LANGUAGE plpgsql
    AS $$
DECLARE 
	min_weight integer;
	avg_weight integer;
	max_weight integer;
BEGIN
	SELECT MAX(medicine.gross_weight)
	INTO max_weight
	FROM medicine
	JOIN department_stores_medicine ON department_stores_medicine.id_medicine = medicine.id
	JOIN storage_department ON storage_department.id = department_stores_medicine.id_storage_department
	WHERE storage_department.name = name_st_dep;
	
	SELECT MIN(medicine.gross_weight)
	INTO min_weight
	FROM medicine
	JOIN department_stores_medicine ON department_stores_medicine.id_medicine = medicine.id
	JOIN storage_department ON storage_department.id = department_stores_medicine.id_storage_department
	WHERE storage_department.name = name_st_dep;
	
	SELECT AVG(medicine.gross_weight)
	INTO avg_weight
	FROM medicine
	JOIN department_stores_medicine ON department_stores_medicine.id_medicine = medicine.id
	JOIN storage_department ON storage_department.id = department_stores_medicine.id_storage_department
	WHERE storage_department.name = name_st_dep;
	
	RETURN QUERY VALUES
		   (VARCHAR(20)'Максимальный вес', max_weight),
		   (VARCHAR(20)'Средний вес', avg_weight),
		   (VARCHAR(20)'Минимальный вес', min_weight);
END
$$;


ALTER FUNCTION public.weightsindep(name_st_dep character varying) OWNER TO postgres;

--
-- TOC entry 247 (class 1255 OID 17052)
-- Name: workervoyages(character varying, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.workervoyages(w_name character varying, w_surname character varying) RETURNS TABLE(contract_name character varying)
    LANGUAGE plpgsql
    AS $$
DECLARE
	answer record;
BEGIN
   FOR answer in(SELECT voyage.voyage_number
				 FROM contract
				 JOIN worker ON worker.id = contract.id_worker
				 JOIN voyage ON voyage.id_contract = contract.id
				 WHERE w_name = worker.name AND w_surname = worker.surname) 
   LOOP contract_name = answer.voyage_number;
        return next;
   END LOOP;
END;
$$;


ALTER FUNCTION public.workervoyages(w_name character varying, w_surname character varying) OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 221 (class 1259 OID 16577)
-- Name: contract; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.contract (
    id integer NOT NULL,
    sending_receiving boolean DEFAULT false NOT NULL,
    documents character varying(100) NOT NULL,
    voyage_payment money NOT NULL,
    id_worker integer NOT NULL,
    complete boolean DEFAULT false
);


ALTER TABLE public.contract OWNER TO postgres;

--
-- TOC entry 220 (class 1259 OID 16575)
-- Name: contract_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.contract_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.contract_id_seq OWNER TO postgres;

--
-- TOC entry 3195 (class 0 OID 0)
-- Dependencies: 220
-- Name: contract_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.contract_id_seq OWNED BY public.contract.id;


--
-- TOC entry 214 (class 1259 OID 16513)
-- Name: department_stores_medicine; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.department_stores_medicine (
    id_medicine integer NOT NULL,
    id_storage_department integer NOT NULL,
    number integer DEFAULT 1 NOT NULL
);


ALTER TABLE public.department_stores_medicine OWNER TO postgres;

--
-- TOC entry 207 (class 1259 OID 16463)
-- Name: manufacturer_firm; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.manufacturer_firm (
    id integer NOT NULL,
    name character varying(80) NOT NULL,
    address character varying(80) NOT NULL
);


ALTER TABLE public.manufacturer_firm OWNER TO postgres;

--
-- TOC entry 213 (class 1259 OID 16487)
-- Name: medicine; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.medicine (
    id integer NOT NULL,
    price money NOT NULL,
    name character varying(80) NOT NULL,
    expiration_date date NOT NULL,
    series character varying(5) NOT NULL,
    date_quarantine_zone date,
    return_distruction_date date,
    gross_weight smallint NOT NULL,
    id_medicine_form integer NOT NULL,
    id_manufacturer_firm integer NOT NULL,
    id_storage_method integer NOT NULL,
    id_pharmacological_group integer NOT NULL
);


ALTER TABLE public.medicine OWNER TO postgres;

--
-- TOC entry 205 (class 1259 OID 16445)
-- Name: storage_department; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.storage_department (
    id integer NOT NULL,
    name character varying(5) NOT NULL,
    id_medicine_form integer NOT NULL,
    id_pharmacy_warhouse integer NOT NULL
);


ALTER TABLE public.storage_department OWNER TO postgres;

--
-- TOC entry 228 (class 1259 OID 17054)
-- Name: countmedmanfac; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.countmedmanfac AS
 SELECT manufacturer_firm.name AS "Фирма производитель",
    sum(department_stores_medicine.number) AS "Количество"
   FROM (((public.manufacturer_firm
     JOIN public.medicine ON ((medicine.id_manufacturer_firm = manufacturer_firm.id)))
     JOIN public.department_stores_medicine ON ((department_stores_medicine.id_medicine = medicine.id)))
     JOIN public.storage_department ON ((storage_department.id = department_stores_medicine.id_storage_department)))
  WHERE (storage_department.id_pharmacy_warhouse = 4)
  GROUP BY manufacturer_firm.name
  ORDER BY (sum(department_stores_medicine.number)) DESC
 LIMIT 5;


ALTER TABLE public.countmedmanfac OWNER TO postgres;

--
-- TOC entry 206 (class 1259 OID 16461)
-- Name: manufacturer_firm_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.manufacturer_firm_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.manufacturer_firm_id_seq OWNER TO postgres;

--
-- TOC entry 3196 (class 0 OID 0)
-- Dependencies: 206
-- Name: manufacturer_firm_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.manufacturer_firm_id_seq OWNED BY public.manufacturer_firm.id;


--
-- TOC entry 216 (class 1259 OID 16531)
-- Name: medicine_equipment; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.medicine_equipment (
    id integer NOT NULL,
    price money NOT NULL,
    name character varying(100) NOT NULL
);


ALTER TABLE public.medicine_equipment OWNER TO postgres;

--
-- TOC entry 201 (class 1259 OID 16429)
-- Name: pharmacy_warhouse; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pharmacy_warhouse (
    id integer NOT NULL,
    opening_hours character varying(11) NOT NULL,
    address character varying(100) NOT NULL
);


ALTER TABLE public.pharmacy_warhouse OWNER TO postgres;

--
-- TOC entry 217 (class 1259 OID 16537)
-- Name: warhouse_stores_m_equipment; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.warhouse_stores_m_equipment (
    id_pharmacy_warhouse integer NOT NULL,
    id_medicine_equipment integer NOT NULL,
    number integer DEFAULT 1 NOT NULL
);


ALTER TABLE public.warhouse_stores_m_equipment OWNER TO postgres;

--
-- TOC entry 230 (class 1259 OID 17064)
-- Name: maxpricemedequip; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.maxpricemedequip AS
 SELECT pharmacy_warhouse.address AS "Адрес аптечного склада",
    medicine_equipment.name AS "Мед. оборудование",
    medicine_equipment.price AS "Цена"
   FROM ((public.warhouse_stores_m_equipment
     JOIN public.pharmacy_warhouse ON ((warhouse_stores_m_equipment.id_pharmacy_warhouse = pharmacy_warhouse.id)))
     JOIN public.medicine_equipment ON ((medicine_equipment.id = warhouse_stores_m_equipment.id_medicine_equipment)))
  WHERE (medicine_equipment.price = ( SELECT max(medicine_equipment_1.price) AS max
           FROM public.medicine_equipment medicine_equipment_1));


ALTER TABLE public.maxpricemedequip OWNER TO postgres;

--
-- TOC entry 215 (class 1259 OID 16529)
-- Name: medicine_equipment_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.medicine_equipment_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.medicine_equipment_id_seq OWNER TO postgres;

--
-- TOC entry 3197 (class 0 OID 0)
-- Dependencies: 215
-- Name: medicine_equipment_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.medicine_equipment_id_seq OWNED BY public.medicine_equipment.id;


--
-- TOC entry 203 (class 1259 OID 16437)
-- Name: medicine_form; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.medicine_form (
    id integer NOT NULL,
    name character varying(50) NOT NULL
);


ALTER TABLE public.medicine_form OWNER TO postgres;

--
-- TOC entry 202 (class 1259 OID 16435)
-- Name: medicine_form_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.medicine_form_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.medicine_form_id_seq OWNER TO postgres;

--
-- TOC entry 3198 (class 0 OID 0)
-- Dependencies: 202
-- Name: medicine_form_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.medicine_form_id_seq OWNED BY public.medicine_form.id;


--
-- TOC entry 212 (class 1259 OID 16485)
-- Name: medicine_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.medicine_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.medicine_id_seq OWNER TO postgres;

--
-- TOC entry 3199 (class 0 OID 0)
-- Dependencies: 212
-- Name: medicine_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.medicine_id_seq OWNED BY public.medicine.id;


--
-- TOC entry 211 (class 1259 OID 16479)
-- Name: pharmacological_group; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pharmacological_group (
    id integer NOT NULL,
    name character varying(50) NOT NULL
);


ALTER TABLE public.pharmacological_group OWNER TO postgres;

--
-- TOC entry 210 (class 1259 OID 16477)
-- Name: pharmacological_group_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.pharmacological_group_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.pharmacological_group_id_seq OWNER TO postgres;

--
-- TOC entry 3200 (class 0 OID 0)
-- Dependencies: 210
-- Name: pharmacological_group_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.pharmacological_group_id_seq OWNED BY public.pharmacological_group.id;


--
-- TOC entry 200 (class 1259 OID 16427)
-- Name: pharmacy_warhouse_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.pharmacy_warhouse_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.pharmacy_warhouse_id_seq OWNER TO postgres;

--
-- TOC entry 3201 (class 0 OID 0)
-- Dependencies: 200
-- Name: pharmacy_warhouse_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.pharmacy_warhouse_id_seq OWNED BY public.pharmacy_warhouse.id;


--
-- TOC entry 223 (class 1259 OID 16591)
-- Name: voyage; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.voyage (
    id integer NOT NULL,
    voyage_number character varying(7) NOT NULL,
    car_number character varying(6) NOT NULL,
    destination_point character varying(70) NOT NULL,
    end_date_time timestamp without time zone,
    id_contract integer NOT NULL,
    start_date_time timestamp without time zone
);


ALTER TABLE public.voyage OWNER TO postgres;

--
-- TOC entry 224 (class 1259 OID 16648)
-- Name: voyage_transports_m_equipment; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.voyage_transports_m_equipment (
    id_voyage integer NOT NULL,
    id_p_warehouse integer NOT NULL,
    id_m_equipment integer NOT NULL,
    number integer NOT NULL,
    in_out boolean DEFAULT true
);


ALTER TABLE public.voyage_transports_m_equipment OWNER TO postgres;

--
-- TOC entry 229 (class 1259 OID 17059)
-- Name: sendmedequip; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.sendmedequip AS
 SELECT medicine_equipment.name AS "Мед. оборудование",
    sum(voyage_transports_m_equipment.number) AS "Количество",
    voyage.destination_point AS "Место назначения"
   FROM ((public.voyage_transports_m_equipment
     JOIN public.medicine_equipment ON ((medicine_equipment.id = voyage_transports_m_equipment.id_m_equipment)))
     JOIN public.voyage ON ((voyage.id = voyage_transports_m_equipment.id_voyage)))
  WHERE (voyage_transports_m_equipment.in_out = false)
  GROUP BY medicine_equipment.name, voyage.destination_point
  ORDER BY (sum(voyage_transports_m_equipment.number)) DESC;


ALTER TABLE public.sendmedequip OWNER TO postgres;

--
-- TOC entry 204 (class 1259 OID 16443)
-- Name: storage_department_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.storage_department_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.storage_department_id_seq OWNER TO postgres;

--
-- TOC entry 3202 (class 0 OID 0)
-- Dependencies: 204
-- Name: storage_department_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.storage_department_id_seq OWNED BY public.storage_department.id;


--
-- TOC entry 209 (class 1259 OID 16471)
-- Name: storage_method; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.storage_method (
    id integer NOT NULL,
    name character varying(30) NOT NULL
);


ALTER TABLE public.storage_method OWNER TO postgres;

--
-- TOC entry 208 (class 1259 OID 16469)
-- Name: storage_method_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.storage_method_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.storage_method_id_seq OWNER TO postgres;

--
-- TOC entry 3203 (class 0 OID 0)
-- Dependencies: 208
-- Name: storage_method_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.storage_method_id_seq OWNED BY public.storage_method.id;


--
-- TOC entry 222 (class 1259 OID 16589)
-- Name: voyage_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.voyage_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.voyage_id_seq OWNER TO postgres;

--
-- TOC entry 3204 (class 0 OID 0)
-- Dependencies: 222
-- Name: voyage_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.voyage_id_seq OWNED BY public.voyage.id;


--
-- TOC entry 225 (class 1259 OID 16664)
-- Name: voyage_transports_medicine; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.voyage_transports_medicine (
    id_voyage integer NOT NULL,
    id_medicine integer NOT NULL,
    id_storage_department integer NOT NULL,
    number integer DEFAULT 1 NOT NULL,
    in_out boolean DEFAULT true NOT NULL
);


ALTER TABLE public.voyage_transports_medicine OWNER TO postgres;

--
-- TOC entry 219 (class 1259 OID 16555)
-- Name: worker; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.worker (
    id integer NOT NULL,
    name character varying(30) NOT NULL,
    surname character varying(30) NOT NULL,
    id_warhouse integer NOT NULL,
    id_position integer
);


ALTER TABLE public.worker OWNER TO postgres;

--
-- TOC entry 218 (class 1259 OID 16553)
-- Name: worker_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.worker_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.worker_id_seq OWNER TO postgres;

--
-- TOC entry 3205 (class 0 OID 0)
-- Dependencies: 218
-- Name: worker_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.worker_id_seq OWNED BY public.worker.id;


--
-- TOC entry 227 (class 1259 OID 16936)
-- Name: worker_position; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.worker_position (
    id integer NOT NULL,
    "position" character varying(50) NOT NULL
);


ALTER TABLE public.worker_position OWNER TO postgres;

--
-- TOC entry 226 (class 1259 OID 16934)
-- Name: worker_position_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.worker_position_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.worker_position_id_seq OWNER TO postgres;

--
-- TOC entry 3206 (class 0 OID 0)
-- Dependencies: 226
-- Name: worker_position_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.worker_position_id_seq OWNED BY public.worker_position.id;


--
-- TOC entry 2963 (class 2604 OID 16981)
-- Name: contract id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.contract ALTER COLUMN id SET DEFAULT nextval('public.contract_id_seq'::regclass);


--
-- TOC entry 2954 (class 2604 OID 16982)
-- Name: manufacturer_firm id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.manufacturer_firm ALTER COLUMN id SET DEFAULT nextval('public.manufacturer_firm_id_seq'::regclass);


--
-- TOC entry 2957 (class 2604 OID 16983)
-- Name: medicine id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.medicine ALTER COLUMN id SET DEFAULT nextval('public.medicine_id_seq'::regclass);


--
-- TOC entry 2959 (class 2604 OID 16984)
-- Name: medicine_equipment id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.medicine_equipment ALTER COLUMN id SET DEFAULT nextval('public.medicine_equipment_id_seq'::regclass);


--
-- TOC entry 2952 (class 2604 OID 16985)
-- Name: medicine_form id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.medicine_form ALTER COLUMN id SET DEFAULT nextval('public.medicine_form_id_seq'::regclass);


--
-- TOC entry 2956 (class 2604 OID 16986)
-- Name: pharmacological_group id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pharmacological_group ALTER COLUMN id SET DEFAULT nextval('public.pharmacological_group_id_seq'::regclass);


--
-- TOC entry 2951 (class 2604 OID 16987)
-- Name: pharmacy_warhouse id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pharmacy_warhouse ALTER COLUMN id SET DEFAULT nextval('public.pharmacy_warhouse_id_seq'::regclass);


--
-- TOC entry 2953 (class 2604 OID 16988)
-- Name: storage_department id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.storage_department ALTER COLUMN id SET DEFAULT nextval('public.storage_department_id_seq'::regclass);


--
-- TOC entry 2955 (class 2604 OID 16989)
-- Name: storage_method id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.storage_method ALTER COLUMN id SET DEFAULT nextval('public.storage_method_id_seq'::regclass);


--
-- TOC entry 2965 (class 2604 OID 16990)
-- Name: voyage id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.voyage ALTER COLUMN id SET DEFAULT nextval('public.voyage_id_seq'::regclass);


--
-- TOC entry 2961 (class 2604 OID 16991)
-- Name: worker id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.worker ALTER COLUMN id SET DEFAULT nextval('public.worker_id_seq'::regclass);


--
-- TOC entry 2969 (class 2604 OID 16939)
-- Name: worker_position id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.worker_position ALTER COLUMN id SET DEFAULT nextval('public.worker_position_id_seq'::regclass);


--
-- TOC entry 3183 (class 0 OID 16577)
-- Dependencies: 221
-- Data for Name: contract; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.contract (id, sending_receiving, documents, voyage_payment, id_worker, complete) FROM stdin;
4	t	Лицензия на лекарства	15 000,00 ?	4	f
5	f	Лицензия на наркотические средства	40 000,00 ?	5	f
6	f	Лицензия на лекарства	10 000,00 ?	6	f
10	f	Удостоверения на лекарства	35 000,00 ?	10	f
13	t	erat quisque erat eros viverra	21 850,00 ?	13	f
14	f	blandit nam nulla integer pede justo	14 855,00 ?	14	t
15	t	dictumst etiam faucibus cursus urna ut tellus	79 441,00 ?	15	f
16	t	dictumst morbi vestibulum velit id	53 075,00 ?	16	t
17	t	lorem ipsum dolor sit amet consectetuer	69 046,00 ?	17	f
18	t	amet lobortis sapien sapien non mi	47 241,00 ?	18	t
19	t	vestibulum velit id pretium iaculis diam erat	84 518,00 ?	19	f
20	t	volutpat dui maecenas tristique est et tempus	87 281,00 ?	20	t
21	t	amet nulla quisque arcu libero	43 933,00 ?	21	t
22	t	ultrices posuere cubilia curae duis	41 527,00 ?	22	f
23	f	mattis pulvinar nulla pede ullamcorper	64 185,00 ?	23	f
24	t	mi sit amet lobortis sapien sapien	16 204,00 ?	24	f
25	f	eros elementum pellentesque quisque porta volutpat	83 912,00 ?	25	f
26	t	sit amet nunc viverra dapibus nulla suscipit	30 973,00 ?	26	t
27	t	aliquet massa id lobortis convallis	95 015,00 ?	27	t
28	f	imperdiet nullam orci pede venenatis	85 629,00 ?	28	t
29	f	eget orci vehicula condimentum curabitur	81 520,00 ?	29	t
30	f	sem fusce consequat nulla nisl	90 349,00 ?	30	f
31	t	sed tristique in tempus sit	65 200,00 ?	31	f
32	f	et magnis dis parturient montes nascetur ridiculus	82 352,00 ?	32	f
33	t	nascetur ridiculus mus etiam vel augue	84 591,00 ?	33	f
34	t	diam erat fermentum justo nec condimentum neque	78 032,00 ?	34	t
35	f	volutpat quam pede lobortis ligula sit	92 554,00 ?	35	f
36	t	fringilla rhoncus mauris enim leo rhoncus sed	17 726,00 ?	36	t
37	f	orci mauris lacinia sapien quis libero nullam	51 740,00 ?	37	t
38	t	nec dui luctus rutrum nulla tellus	24 781,00 ?	38	t
39	t	orci eget orci vehicula condimentum curabitur	46 092,00 ?	39	f
40	t	quisque arcu libero rutrum ac lobortis vel	59 743,00 ?	40	f
41	f	sem praesent id massa id	10 590,00 ?	41	f
42	f	malesuada in imperdiet et commodo	79 970,00 ?	42	f
43	f	varius integer ac leo pellentesque	43 670,00 ?	43	t
44	f	semper sapien a libero nam dui proin	12 774,00 ?	44	f
45	f	nullam orci pede venenatis non sodales sed	49 012,00 ?	45	f
46	f	ante ipsum primis in faucibus	84 290,00 ?	46	t
47	f	lorem ipsum dolor sit amet consectetuer	78 402,00 ?	47	f
48	f	adipiscing molestie hendrerit at vulputate	22 143,00 ?	48	f
49	f	gravida nisi at nibh in hac habitasse	75 506,00 ?	49	f
50	t	vestibulum sagittis sapien cum sociis natoque penatibus	71 621,00 ?	50	f
51	f	a suscipit nulla elit ac nulla	65 709,00 ?	51	f
52	t	commodo vulputate justo in blandit ultrices enim	78 619,00 ?	52	f
11	f	Сертификат на лекарства и медицинское оборудование	20 000,00 ?	7	f
12	t	Сертификат на лекарства и медицинское оборудование	25 000,00 ?	8	f
2	t	Лицензия на медицинское оборудование, Сертификат на лекарства	30 000,00 ?	2	t
3	f	Удостоверение на препараты	13 000,00 ?	2	t
7	t	Сертификат на препараты	17 000,00 ?	7	t
9	t	Сертификат на продажу наркотических средств	27 000,00 ?	9	t
8	t	Лицензия на продажу ядов	30 000,00 ?	8	t
1	t	Сертификат на лекарства	15 000,00 ?	1	f
53	t	in faucibus orci luctus et ultrices	71 359,00 ?	53	t
54	t	sapien quis libero nullam sit	22 739,00 ?	54	f
55	t	in leo maecenas pulvinar lobortis	47 003,00 ?	55	f
56	f	aliquet ultrices erat tortor sollicitudin mi sit	10 368,00 ?	56	f
57	t	nulla sed accumsan felis ut	93 065,00 ?	57	f
58	f	vestibulum velit id pretium iaculis	73 063,00 ?	58	f
59	f	donec dapibus duis at velit eu	80 513,00 ?	59	f
60	f	cubilia curae nulla dapibus dolor	36 030,00 ?	60	t
61	t	ut massa quis augue luctus tincidunt nulla	92 327,00 ?	61	t
62	t	suscipit a feugiat et eros	61 490,00 ?	62	t
63	t	ridiculus mus vivamus vestibulum sagittis	21 201,00 ?	63	f
64	f	vivamus metus arcu adipiscing molestie hendrerit at	80 194,00 ?	64	f
65	t	consequat in consequat ut nulla sed	91 002,00 ?	65	t
66	f	nunc commodo placerat praesent blandit nam	74 977,00 ?	66	t
67	f	amet consectetuer adipiscing elit proin	61 586,00 ?	67	f
68	t	non quam nec dui luctus rutrum nulla	63 967,00 ?	68	f
69	f	posuere cubilia curae donec pharetra magna vestibulum	77 740,00 ?	69	f
70	f	arcu libero rutrum ac lobortis	32 519,00 ?	70	t
71	f	ut suscipit a feugiat et eros vestibulum	54 741,00 ?	71	f
72	f	eros suspendisse accumsan tortor quis	49 004,00 ?	72	f
73	t	pellentesque at nulla suspendisse potenti	45 836,00 ?	73	t
74	t	vulputate elementum nullam varius nulla facilisi cras	98 954,00 ?	74	t
75	f	iaculis diam erat fermentum justo nec	30 129,00 ?	75	f
76	t	accumsan tortor quis turpis sed	35 294,00 ?	76	t
77	t	massa tempor convallis nulla neque	61 143,00 ?	77	t
78	f	sed vel enim sit amet nunc viverra	44 419,00 ?	78	t
79	f	in eleifend quam a odio	38 139,00 ?	79	t
80	t	sodales scelerisque mauris sit amet eros	36 043,00 ?	80	t
81	f	hac habitasse platea dictumst aliquam	39 841,00 ?	81	f
82	f	interdum eu tincidunt in leo	77 881,00 ?	82	f
83	f	vel accumsan tellus nisi eu orci	21 004,00 ?	83	f
84	t	maecenas pulvinar lobortis est phasellus sit amet	28 145,00 ?	84	f
85	t	enim sit amet nunc viverra	71 033,00 ?	85	f
86	t	diam erat fermentum justo nec condimentum	62 361,00 ?	86	f
87	t	vestibulum sit amet cursus id turpis integer	51 679,00 ?	87	f
88	t	arcu adipiscing molestie hendrerit at vulputate vitae	67 653,00 ?	88	t
89	f	vivamus metus arcu adipiscing molestie	93 244,00 ?	89	t
90	t	ac diam cras pellentesque volutpat	89 623,00 ?	90	t
91	f	nisi venenatis tristique fusce congue diam id	36 625,00 ?	91	t
92	f	sit amet consectetuer adipiscing elit proin interdum	82 416,00 ?	92	t
93	f	semper est quam pharetra magna	65 097,00 ?	93	t
94	f	elementum pellentesque quisque porta volutpat	93 191,00 ?	94	t
95	t	odio donec vitae nisi nam ultrices	95 080,00 ?	95	f
96	t	ipsum ac tellus semper interdum mauris ullamcorper	43 659,00 ?	96	f
97	f	in lectus pellentesque at nulla	28 446,00 ?	97	t
98	t	morbi non lectus aliquam sit amet	24 818,00 ?	98	f
99	f	ligula nec sem duis aliquam convallis	14 728,00 ?	99	f
100	f	etiam vel augue vestibulum rutrum	97 988,00 ?	100	t
101	t	lobortis sapien sapien non mi integer ac	69 023,00 ?	101	t
102	t	in faucibus orci luctus et ultrices	69 717,00 ?	102	f
103	f	sed justo pellentesque viverra pede ac diam	22 870,00 ?	103	t
104	t	natoque penatibus et magnis dis parturient	66 576,00 ?	104	f
105	f	non mi integer ac neque	16 458,00 ?	105	t
106	t	ac leo pellentesque ultrices mattis	17 440,00 ?	106	t
107	f	nisi at nibh in hac	15 050,00 ?	107	f
108	f	faucibus orci luctus et ultrices	56 481,00 ?	108	t
109	t	vivamus vestibulum sagittis sapien cum	56 140,00 ?	109	f
110	t	id sapien in sapien iaculis congue	20 231,00 ?	110	t
111	f	vulputate ut ultrices vel augue vestibulum	74 592,00 ?	111	f
112	t	a odio in hac habitasse	17 797,00 ?	112	f
113	f	ut erat id mauris vulputate elementum	81 437,00 ?	113	t
114	t	diam cras pellentesque volutpat dui maecenas tristique	27 338,00 ?	114	f
115	t	venenatis non sodales sed tincidunt eu	22 147,00 ?	115	t
116	f	blandit non interdum in ante	47 262,00 ?	116	f
117	f	vitae mattis nibh ligula nec	17 405,00 ?	117	t
118	t	elit sodales scelerisque mauris sit amet eros	29 136,00 ?	118	f
119	t	et eros vestibulum ac est lacinia	57 660,00 ?	119	f
120	f	lacus at turpis donec posuere metus	17 824,00 ?	120	t
121	t	integer ac neque duis bibendum morbi non	43 222,00 ?	121	t
122	f	donec dapibus duis at velit eu est	98 483,00 ?	122	t
123	t	vestibulum ante ipsum primis in	33 707,00 ?	123	t
124	t	ligula in lacus curabitur at ipsum ac	65 940,00 ?	124	t
125	f	lorem integer tincidunt ante vel ipsum praesent	82 767,00 ?	125	f
126	t	eget vulputate ut ultrices vel	94 847,00 ?	126	f
127	t	lobortis vel dapibus at diam	12 288,00 ?	127	f
128	t	nulla dapibus dolor vel est	56 075,00 ?	128	t
129	t	sem mauris laoreet ut rhoncus aliquet	84 878,00 ?	129	f
130	t	rutrum nulla nunc purus phasellus in felis	12 021,00 ?	130	f
131	t	nisi venenatis tristique fusce congue diam	96 034,00 ?	131	t
132	t	eu orci mauris lacinia sapien quis	92 417,00 ?	132	t
133	t	eget vulputate ut ultrices vel augue	75 236,00 ?	133	f
134	f	sollicitudin ut suscipit a feugiat et	31 268,00 ?	134	t
135	t	interdum eu tincidunt in leo	61 093,00 ?	135	f
136	t	pellentesque quisque porta volutpat erat quisque erat	83 197,00 ?	136	t
137	f	turpis elementum ligula vehicula consequat morbi a	32 458,00 ?	137	t
138	f	pellentesque eget nunc donec quis	18 417,00 ?	138	f
139	t	erat nulla tempus vivamus in felis	73 605,00 ?	139	f
140	t	in lacus curabitur at ipsum ac	54 136,00 ?	140	f
141	f	maecenas tristique est et tempus semper	51 844,00 ?	141	f
142	t	lorem id ligula suspendisse ornare	13 734,00 ?	142	f
143	t	sed tincidunt eu felis fusce posuere	32 869,00 ?	143	f
144	t	etiam faucibus cursus urna ut	39 836,00 ?	144	f
145	t	lobortis ligula sit amet eleifend	25 301,00 ?	145	f
146	t	tortor quis turpis sed ante vivamus	28 264,00 ?	146	f
147	t	enim sit amet nunc viverra dapibus nulla	73 554,00 ?	147	t
148	t	integer ac leo pellentesque ultrices mattis odio	86 365,00 ?	148	f
149	t	proin at turpis a pede	93 667,00 ?	149	f
150	f	sapien a libero nam dui proin	47 155,00 ?	150	f
151	t	augue quam sollicitudin vitae consectetuer eget	64 110,00 ?	151	f
152	f	in hac habitasse platea dictumst	63 151,00 ?	152	f
153	t	at turpis a pede posuere nonummy integer	42 762,00 ?	153	t
154	f	ac lobortis vel dapibus at	37 375,00 ?	154	t
155	t	tellus semper interdum mauris ullamcorper	20 701,00 ?	155	f
156	f	id nulla ultrices aliquet maecenas leo	53 073,00 ?	156	f
157	t	iaculis justo in hac habitasse platea	67 220,00 ?	157	f
158	t	imperdiet nullam orci pede venenatis non sodales	53 660,00 ?	158	t
159	f	ut massa quis augue luctus	81 238,00 ?	159	f
160	t	nascetur ridiculus mus vivamus vestibulum sagittis	83 451,00 ?	160	f
161	t	elementum nullam varius nulla facilisi	95 689,00 ?	161	f
162	t	quam pharetra magna ac consequat metus sapien	94 993,00 ?	162	f
163	f	in ante vestibulum ante ipsum primis	82 312,00 ?	163	t
164	f	ipsum dolor sit amet consectetuer adipiscing elit	10 873,00 ?	164	t
165	f	sit amet erat nulla tempus	65 488,00 ?	165	t
166	t	vivamus in felis eu sapien cursus vestibulum	72 573,00 ?	166	f
167	t	bibendum felis sed interdum venenatis turpis	88 216,00 ?	167	f
168	t	at feugiat non pretium quis lectus suspendisse	33 185,00 ?	168	f
169	f	sociis natoque penatibus et magnis dis parturient	38 024,00 ?	169	f
170	f	lectus in quam fringilla rhoncus mauris	43 600,00 ?	170	f
171	t	tortor sollicitudin mi sit amet	30 539,00 ?	171	t
172	t	pede libero quis orci nullam molestie nibh	33 593,00 ?	172	f
173	f	id turpis integer aliquet massa id lobortis	17 140,00 ?	173	f
174	f	eu nibh quisque id justo sit amet	23 930,00 ?	174	f
175	f	orci pede venenatis non sodales	71 220,00 ?	175	f
176	t	felis sed lacus morbi sem	20 335,00 ?	176	t
177	t	maecenas tincidunt lacus at velit vivamus	95 087,00 ?	177	f
178	f	proin leo odio porttitor id consequat	86 409,00 ?	178	t
179	f	in blandit ultrices enim lorem	70 195,00 ?	179	f
180	t	venenatis tristique fusce congue diam	25 758,00 ?	180	f
181	t	cubilia curae nulla dapibus dolor vel est	11 943,00 ?	181	t
182	t	nibh ligula nec sem duis	98 408,00 ?	182	t
183	f	enim leo rhoncus sed vestibulum sit	70 776,00 ?	183	t
184	f	quam a odio in hac	83 608,00 ?	184	f
185	t	faucibus orci luctus et ultrices posuere	46 763,00 ?	185	f
186	f	nulla dapibus dolor vel est	69 747,00 ?	186	f
187	f	vestibulum quam sapien varius ut blandit	34 567,00 ?	187	t
188	f	libero nam dui proin leo	87 975,00 ?	188	t
189	t	lorem integer tincidunt ante vel ipsum praesent	76 577,00 ?	189	t
190	f	dapibus duis at velit eu est	46 291,00 ?	190	f
191	f	sem praesent id massa id	93 715,00 ?	191	f
192	t	non interdum in ante vestibulum	16 694,00 ?	192	t
193	t	dapibus dolor vel est donec odio justo	40 108,00 ?	193	t
194	f	fusce posuere felis sed lacus	43 873,00 ?	194	f
195	t	sit amet erat nulla tempus vivamus in	31 220,00 ?	195	t
196	f	velit donec diam neque vestibulum eget	34 182,00 ?	196	f
197	t	leo odio porttitor id consequat in	45 459,00 ?	197	f
198	f	sed magna at nunc commodo placerat praesent	73 351,00 ?	198	t
199	t	ultrices erat tortor sollicitudin mi sit amet	94 552,00 ?	199	t
200	t	nullam sit amet turpis elementum ligula vehicula	67 907,00 ?	200	t
201	f	massa donec dapibus duis at velit	58 119,00 ?	201	t
206	t	eget semper rutrum nulla nunc purus phasellus	20 589,00 ?	206	f
207	f	massa donec dapibus duis at	51 141,00 ?	207	t
208	f	ut ultrices vel augue vestibulum	24 286,00 ?	208	t
209	t	varius nulla facilisi cras non velit nec	10 131,00 ?	209	t
210	t	vestibulum ante ipsum primis in faucibus	19 106,00 ?	210	t
211	t	diam id ornare imperdiet sapien urna	22 549,00 ?	211	t
212	f	orci pede venenatis non sodales	78 377,00 ?	212	t
213	t	lobortis ligula sit amet eleifend pede libero	26 826,00 ?	213	t
214	t	duis aliquam convallis nunc proin at turpis	62 349,00 ?	214	f
215	f	sollicitudin ut suscipit a feugiat et eros	25 316,00 ?	215	t
216	t	ipsum integer a nibh in	75 345,00 ?	216	t
217	t	posuere cubilia curae mauris viverra	98 253,00 ?	217	f
218	f	morbi vel lectus in quam fringilla rhoncus	61 528,00 ?	218	t
219	f	nec nisi vulputate nonummy maecenas	81 745,00 ?	219	t
220	f	duis bibendum morbi non quam	85 946,00 ?	220	t
221	f	condimentum id luctus nec molestie	67 845,00 ?	221	f
222	t	sit amet nunc viverra dapibus	24 676,00 ?	222	f
223	t	vivamus vel nulla eget eros elementum	75 099,00 ?	223	f
224	t	scelerisque mauris sit amet eros	51 125,00 ?	224	f
225	t	integer pede justo lacinia eget tincidunt eget	40 423,00 ?	225	f
226	f	adipiscing lorem vitae mattis nibh ligula	87 728,00 ?	226	t
227	f	libero quis orci nullam molestie nibh in	32 540,00 ?	227	t
228	t	quisque id justo sit amet	92 586,00 ?	228	t
229	t	felis sed interdum venenatis turpis enim blandit	60 249,00 ?	229	f
230	f	ut tellus nulla ut erat id	44 478,00 ?	230	f
231	t	nascetur ridiculus mus vivamus vestibulum	58 374,00 ?	231	f
232	t	faucibus orci luctus et ultrices posuere cubilia	68 506,00 ?	232	t
233	t	quis tortor id nulla ultrices aliquet maecenas	87 698,00 ?	233	f
234	t	massa volutpat convallis morbi odio odio	21 009,00 ?	234	f
235	f	integer pede justo lacinia eget	60 318,00 ?	235	f
236	f	purus eu magna vulputate luctus	63 463,00 ?	236	f
237	t	quam nec dui luctus rutrum nulla tellus	47 762,00 ?	237	t
238	t	turpis integer aliquet massa id lobortis convallis	54 452,00 ?	238	t
239	t	vestibulum ante ipsum primis in faucibus	57 501,00 ?	239	f
240	t	amet eleifend pede libero quis	27 174,00 ?	240	f
241	f	integer tincidunt ante vel ipsum praesent blandit	70 309,00 ?	241	f
242	t	pretium nisl ut volutpat sapien arcu	46 602,00 ?	242	t
243	t	nulla ut erat id mauris vulputate elementum	16 940,00 ?	243	f
244	f	leo maecenas pulvinar lobortis est	71 944,00 ?	244	f
245	t	vitae nisi nam ultrices libero	27 040,00 ?	245	t
246	f	nullam sit amet turpis elementum ligula	91 646,00 ?	246	t
247	t	cras pellentesque volutpat dui maecenas tristique	27 193,00 ?	247	t
248	f	augue a suscipit nulla elit	28 182,00 ?	248	t
249	f	mi in porttitor pede justo	25 067,00 ?	249	t
250	f	id lobortis convallis tortor risus dapibus augue	53 581,00 ?	250	f
251	f	ipsum primis in faucibus orci luctus	19 143,00 ?	251	t
252	f	pulvinar nulla pede ullamcorper augue a suscipit	78 963,00 ?	252	t
253	t	nulla suscipit ligula in lacus curabitur	63 693,00 ?	253	t
254	f	cursus vestibulum proin eu mi	22 064,00 ?	254	f
255	t	ipsum ac tellus semper interdum	36 312,00 ?	255	f
256	t	pellentesque volutpat dui maecenas tristique est et	12 038,00 ?	256	t
257	f	mauris enim leo rhoncus sed vestibulum sit	29 506,00 ?	257	t
258	f	bibendum felis sed interdum venenatis turpis	81 327,00 ?	258	t
259	f	vel nulla eget eros elementum pellentesque quisque	55 664,00 ?	259	t
260	f	a odio in hac habitasse	13 843,00 ?	260	f
261	f	volutpat convallis morbi odio odio	82 684,00 ?	261	f
262	t	mi sit amet lobortis sapien sapien	16 303,00 ?	262	f
263	f	ligula pellentesque ultrices phasellus id sapien in	21 429,00 ?	263	t
264	f	in blandit ultrices enim lorem ipsum dolor	43 899,00 ?	264	t
265	f	est phasellus sit amet erat nulla tempus	90 925,00 ?	265	t
266	t	diam erat fermentum justo nec condimentum	52 432,00 ?	266	t
204	t	curae mauris viverra diam vitae quam	43 442,00 ?	204	t
205	t	aliquam sit amet diam in magna	72 162,00 ?	205	t
202	f	proin interdum mauris non ligula pellentesque ultrices	95 039,00 ?	202	t
267	f	ac neque duis bibendum morbi non	64 530,00 ?	267	f
268	t	vulputate vitae nisl aenean lectus	32 551,00 ?	268	f
269	f	erat curabitur gravida nisi at nibh in	50 085,00 ?	269	t
270	t	non interdum in ante vestibulum ante ipsum	87 171,00 ?	270	t
271	f	vestibulum quam sapien varius ut blandit	99 045,00 ?	271	t
272	t	diam cras pellentesque volutpat dui	20 798,00 ?	272	f
273	t	nisi venenatis tristique fusce congue diam id	64 804,00 ?	273	t
274	t	natoque penatibus et magnis dis	42 312,00 ?	274	t
275	t	et ultrices posuere cubilia curae	25 687,00 ?	275	t
276	t	nec nisi vulputate nonummy maecenas	42 808,00 ?	276	f
277	t	faucibus orci luctus et ultrices posuere	91 812,00 ?	277	t
278	t	quis orci eget orci vehicula condimentum curabitur	82 214,00 ?	278	t
279	f	ligula nec sem duis aliquam convallis nunc	85 541,00 ?	279	f
280	f	dapibus at diam nam tristique	44 851,00 ?	280	t
281	f	dictumst etiam faucibus cursus urna ut tellus	78 847,00 ?	281	f
282	f	at dolor quis odio consequat	96 925,00 ?	282	f
283	f	amet cursus id turpis integer aliquet	85 403,00 ?	283	t
284	t	eu magna vulputate luctus cum sociis natoque	45 011,00 ?	284	f
285	t	leo rhoncus sed vestibulum sit amet cursus	37 046,00 ?	285	f
286	t	lacus at turpis donec posuere metus vitae	25 292,00 ?	286	f
287	t	tristique fusce congue diam id ornare imperdiet	92 640,00 ?	287	t
288	f	eleifend pede libero quis orci nullam	41 133,00 ?	288	f
289	f	quisque arcu libero rutrum ac lobortis	80 449,00 ?	289	t
290	f	in faucibus orci luctus et	54 404,00 ?	290	f
291	t	libero convallis eget eleifend luctus	38 037,00 ?	291	f
292	f	pede malesuada in imperdiet et	47 818,00 ?	292	t
293	f	accumsan odio curabitur convallis duis	76 816,00 ?	293	t
294	t	lacus at velit vivamus vel nulla	93 415,00 ?	294	t
295	t	hac habitasse platea dictumst etiam	68 260,00 ?	295	t
296	f	mauris ullamcorper purus sit amet nulla quisque	57 467,00 ?	296	t
297	t	rutrum neque aenean auctor gravida	45 014,00 ?	297	f
298	f	in felis donec semper sapien a libero	25 276,00 ?	298	f
299	f	justo aliquam quis turpis eget	64 608,00 ?	299	t
300	t	varius integer ac leo pellentesque ultrices mattis	11 961,00 ?	300	f
301	f	tincidunt lacus at velit vivamus vel nulla	42 068,00 ?	301	t
302	t	etiam vel augue vestibulum rutrum rutrum	62 033,00 ?	302	t
303	t	libero ut massa volutpat convallis	59 413,00 ?	303	t
304	t	mi in porttitor pede justo	84 716,00 ?	304	f
305	f	enim lorem ipsum dolor sit amet consectetuer	85 321,00 ?	305	t
306	f	integer non velit donec diam neque vestibulum	46 406,00 ?	306	f
307	t	vestibulum quam sapien varius ut	16 745,00 ?	307	t
308	t	quam pede lobortis ligula sit amet	81 471,00 ?	308	t
309	f	vel ipsum praesent blandit lacinia erat vestibulum	79 326,00 ?	309	f
310	f	quis orci eget orci vehicula condimentum	10 313,00 ?	310	t
311	t	turpis donec posuere metus vitae ipsum	21 411,00 ?	311	t
312	f	pellentesque viverra pede ac diam cras	86 704,00 ?	312	t
313	t	amet erat nulla tempus vivamus	83 896,00 ?	313	t
314	f	libero quis orci nullam molestie nibh	31 990,00 ?	314	f
315	t	habitasse platea dictumst morbi vestibulum velit	17 838,00 ?	315	t
316	t	nullam varius nulla facilisi cras	75 338,00 ?	316	f
317	f	ligula in lacus curabitur at ipsum	45 918,00 ?	317	t
318	t	pede venenatis non sodales sed	36 246,00 ?	318	f
319	f	vestibulum vestibulum ante ipsum primis	88 202,00 ?	319	t
320	f	cras mi pede malesuada in imperdiet	62 769,00 ?	320	f
321	t	nec euismod scelerisque quam turpis adipiscing	72 825,00 ?	321	f
322	t	a ipsum integer a nibh in quis	17 736,00 ?	322	f
323	t	integer a nibh in quis	55 790,00 ?	323	f
324	f	ultricies eu nibh quisque id justo sit	30 767,00 ?	324	f
325	f	et eros vestibulum ac est lacinia	53 623,00 ?	325	f
326	f	donec pharetra magna vestibulum aliquet	63 264,00 ?	326	t
327	t	non ligula pellentesque ultrices phasellus	62 270,00 ?	327	f
328	t	nec molestie sed justo pellentesque viverra	72 284,00 ?	328	f
329	f	erat vestibulum sed magna at nunc commodo	14 541,00 ?	329	t
330	t	ut blandit non interdum in	58 259,00 ?	330	t
331	t	sed nisl nunc rhoncus dui vel sem	69 078,00 ?	331	t
332	f	ut mauris eget massa tempor convallis nulla	94 052,00 ?	332	t
333	f	dolor vel est donec odio justo sollicitudin	70 898,00 ?	333	t
334	t	justo in blandit ultrices enim lorem ipsum	45 306,00 ?	334	t
335	t	quam pede lobortis ligula sit amet	18 513,00 ?	335	t
336	t	nisl nunc rhoncus dui vel sem sed	21 314,00 ?	336	t
337	f	accumsan odio curabitur convallis duis consequat dui	67 991,00 ?	337	t
338	f	felis ut at dolor quis odio consequat	57 982,00 ?	338	f
339	f	sapien iaculis congue vivamus metus arcu adipiscing	59 051,00 ?	339	f
340	f	turpis nec euismod scelerisque quam turpis	58 036,00 ?	340	t
341	f	consequat metus sapien ut nunc vestibulum	83 487,00 ?	341	t
342	f	ante ipsum primis in faucibus	77 078,00 ?	342	t
343	t	vivamus in felis eu sapien cursus	13 240,00 ?	343	f
344	f	nisi volutpat eleifend donec ut dolor	79 216,00 ?	344	t
345	t	nulla integer pede justo lacinia eget	50 988,00 ?	345	t
346	t	metus arcu adipiscing molestie hendrerit at	47 786,00 ?	346	f
347	t	eros vestibulum ac est lacinia nisi venenatis	14 984,00 ?	347	t
348	t	leo maecenas pulvinar lobortis est phasellus	18 590,00 ?	348	t
349	t	diam cras pellentesque volutpat dui maecenas	98 968,00 ?	349	t
350	t	vitae ipsum aliquam non mauris morbi	14 943,00 ?	350	f
351	t	ligula suspendisse ornare consequat lectus in	15 266,00 ?	351	t
352	t	consequat dui nec nisi volutpat eleifend donec	53 022,00 ?	352	f
353	f	ut suscipit a feugiat et eros vestibulum	65 329,00 ?	353	f
354	f	consequat metus sapien ut nunc vestibulum ante	70 978,00 ?	354	f
355	f	metus vitae ipsum aliquam non mauris morbi	13 915,00 ?	355	t
356	f	sit amet erat nulla tempus vivamus	48 415,00 ?	356	t
357	f	lacinia aenean sit amet justo morbi	18 662,00 ?	357	f
358	f	integer non velit donec diam neque	65 606,00 ?	358	f
359	t	ornare imperdiet sapien urna pretium nisl ut	86 059,00 ?	359	t
360	f	purus eu magna vulputate luctus cum	68 269,00 ?	360	t
361	f	vestibulum eget vulputate ut ultrices	64 093,00 ?	361	f
362	t	enim sit amet nunc viverra dapibus nulla	64 660,00 ?	362	f
363	f	fermentum justo nec condimentum neque sapien	46 008,00 ?	363	f
364	t	ornare consequat lectus in est risus auctor	24 903,00 ?	364	t
365	t	non ligula pellentesque ultrices phasellus id sapien	42 690,00 ?	365	f
366	f	convallis eget eleifend luctus ultricies	16 474,00 ?	366	t
367	t	pede justo eu massa donec	10 680,00 ?	367	t
368	t	nulla pede ullamcorper augue a	11 263,00 ?	368	f
369	t	sapien quis libero nullam sit amet turpis	76 410,00 ?	369	t
370	f	vestibulum aliquet ultrices erat tortor	18 160,00 ?	370	f
371	f	lorem ipsum dolor sit amet consectetuer	98 677,00 ?	371	f
372	f	vestibulum ante ipsum primis in faucibus orci	26 481,00 ?	372	t
373	t	at turpis donec posuere metus	60 299,00 ?	373	t
374	t	adipiscing elit proin risus praesent lectus vestibulum	48 614,00 ?	374	f
375	f	nullam varius nulla facilisi cras	15 194,00 ?	375	t
376	t	ligula pellentesque ultrices phasellus id sapien in	97 891,00 ?	376	t
377	t	ullamcorper purus sit amet nulla quisque	13 323,00 ?	377	f
378	f	a suscipit nulla elit ac nulla sed	46 148,00 ?	378	t
379	t	felis ut at dolor quis odio consequat	92 690,00 ?	379	f
380	f	at lorem integer tincidunt ante vel	50 229,00 ?	380	f
381	f	suspendisse potenti cras in purus eu magna	65 484,00 ?	381	f
382	f	a pede posuere nonummy integer non velit	82 317,00 ?	382	f
383	t	augue a suscipit nulla elit	41 715,00 ?	383	t
384	t	purus sit amet nulla quisque arcu libero	57 461,00 ?	384	f
385	t	sem sed sagittis nam congue	30 669,00 ?	385	f
386	f	justo pellentesque viverra pede ac diam	94 367,00 ?	386	t
387	f	justo sollicitudin ut suscipit a feugiat	18 146,00 ?	387	t
388	f	lobortis ligula sit amet eleifend pede	64 416,00 ?	388	f
389	f	purus phasellus in felis donec semper	42 224,00 ?	389	t
390	t	tristique est et tempus semper est	55 631,00 ?	390	f
391	t	rhoncus dui vel sem sed sagittis	41 321,00 ?	391	t
392	f	tristique in tempus sit amet	79 413,00 ?	392	f
393	f	justo eu massa donec dapibus duis	37 059,00 ?	393	f
394	t	in lectus pellentesque at nulla suspendisse	45 103,00 ?	394	t
395	t	elementum ligula vehicula consequat morbi	55 104,00 ?	395	t
396	t	in hac habitasse platea dictumst etiam	28 907,00 ?	396	f
397	f	quis augue luctus tincidunt nulla mollis molestie	64 969,00 ?	397	f
398	f	sit amet nulla quisque arcu libero rutrum	80 618,00 ?	398	f
399	f	tellus nisi eu orci mauris lacinia	42 064,00 ?	399	t
400	t	libero non mattis pulvinar nulla pede	93 998,00 ?	400	t
401	f	tortor risus dapibus augue vel accumsan tellus	17 102,00 ?	401	t
402	t	lacus morbi quis tortor id nulla ultrices	31 876,00 ?	402	f
403	f	vestibulum ante ipsum primis in faucibus orci	19 293,00 ?	403	f
404	t	nulla quisque arcu libero rutrum ac lobortis	72 708,00 ?	404	t
405	f	sed lacus morbi sem mauris laoreet ut	86 732,00 ?	405	f
406	f	integer non velit donec diam neque	58 982,00 ?	406	f
407	t	sollicitudin ut suscipit a feugiat et	20 534,00 ?	407	f
408	t	non mattis pulvinar nulla pede	71 375,00 ?	408	f
409	t	in tempor turpis nec euismod scelerisque quam	93 911,00 ?	409	f
410	f	quisque id justo sit amet	15 497,00 ?	410	f
411	t	lorem quisque ut erat curabitur gravida	93 106,00 ?	411	t
412	t	tempor convallis nulla neque libero	95 443,00 ?	412	f
413	f	elementum pellentesque quisque porta volutpat erat quisque	43 728,00 ?	413	t
414	t	amet justo morbi ut odio cras mi	84 132,00 ?	414	t
415	f	felis sed interdum venenatis turpis	39 403,00 ?	415	t
416	f	gravida sem praesent id massa id nisl	34 826,00 ?	416	f
417	f	sagittis dui vel nisl duis ac nibh	56 327,00 ?	417	f
418	t	sed sagittis nam congue risus semper porta	22 386,00 ?	418	f
419	f	diam erat fermentum justo nec	72 919,00 ?	419	t
420	f	nec nisi volutpat eleifend donec	79 478,00 ?	420	t
421	t	quis augue luctus tincidunt nulla	35 147,00 ?	421	t
422	t	blandit ultrices enim lorem ipsum dolor	85 267,00 ?	422	f
423	f	natoque penatibus et magnis dis parturient montes	98 942,00 ?	423	f
424	f	et eros vestibulum ac est	64 308,00 ?	424	f
425	f	pharetra magna vestibulum aliquet ultrices	45 732,00 ?	425	t
426	f	blandit mi in porttitor pede	52 435,00 ?	426	f
427	f	pellentesque volutpat dui maecenas tristique	57 473,00 ?	427	f
428	f	diam in magna bibendum imperdiet nullam orci	43 351,00 ?	428	f
429	f	enim blandit mi in porttitor pede	50 818,00 ?	429	t
430	f	elit proin risus praesent lectus	39 122,00 ?	430	f
431	t	justo in blandit ultrices enim	84 966,00 ?	431	f
432	f	ultrices libero non mattis pulvinar	29 919,00 ?	432	t
433	t	etiam faucibus cursus urna ut tellus nulla	25 841,00 ?	433	f
434	t	ac lobortis vel dapibus at diam	14 214,00 ?	434	t
435	t	erat nulla tempus vivamus in felis	59 790,00 ?	435	f
436	f	malesuada in imperdiet et commodo vulputate justo	98 503,00 ?	436	t
437	f	quis libero nullam sit amet	47 346,00 ?	437	t
438	f	habitasse platea dictumst etiam faucibus	67 855,00 ?	438	t
439	t	eget rutrum at lorem integer	21 135,00 ?	439	f
440	t	ante nulla justo aliquam quis turpis	20 188,00 ?	440	t
441	f	maecenas tincidunt lacus at velit vivamus vel	85 137,00 ?	441	t
442	f	lacus morbi sem mauris laoreet	11 264,00 ?	442	t
443	f	praesent blandit nam nulla integer	56 808,00 ?	443	t
444	f	augue a suscipit nulla elit	31 186,00 ?	444	t
445	t	pretium iaculis diam erat fermentum	53 289,00 ?	445	t
446	f	non quam nec dui luctus rutrum nulla	88 153,00 ?	446	t
447	f	eget congue eget semper rutrum nulla	79 364,00 ?	447	f
448	f	lacus at velit vivamus vel	78 902,00 ?	448	t
449	t	vel dapibus at diam nam tristique tortor	53 572,00 ?	449	t
450	t	vulputate vitae nisl aenean lectus	66 873,00 ?	450	f
451	f	volutpat sapien arcu sed augue	60 013,00 ?	451	f
452	f	justo sollicitudin ut suscipit a feugiat	82 013,00 ?	452	t
453	t	metus vitae ipsum aliquam non mauris	24 727,00 ?	453	f
454	f	in faucibus orci luctus et	57 401,00 ?	454	t
455	t	ut massa volutpat convallis morbi odio	41 653,00 ?	455	f
456	t	eget orci vehicula condimentum curabitur	19 811,00 ?	456	t
457	f	posuere cubilia curae duis faucibus	31 619,00 ?	457	t
458	t	potenti nullam porttitor lacus at turpis	80 222,00 ?	458	t
459	t	diam id ornare imperdiet sapien urna	81 421,00 ?	459	t
460	t	diam id ornare imperdiet sapien	89 282,00 ?	460	f
461	f	eros elementum pellentesque quisque porta volutpat erat	92 030,00 ?	461	t
462	f	viverra eget congue eget semper rutrum	17 044,00 ?	462	f
463	f	dapibus nulla suscipit ligula in lacus	48 672,00 ?	463	f
464	f	odio in hac habitasse platea dictumst	20 746,00 ?	464	f
465	t	convallis nunc proin at turpis a pede	31 545,00 ?	465	t
466	t	nibh in hac habitasse platea dictumst aliquam	65 745,00 ?	466	t
467	f	tortor risus dapibus augue vel accumsan	47 557,00 ?	467	f
468	t	mauris morbi non lectus aliquam sit amet	62 481,00 ?	468	f
469	t	pharetra magna ac consequat metus sapien ut	13 457,00 ?	469	t
470	f	vehicula condimentum curabitur in libero ut	51 173,00 ?	470	t
471	f	interdum mauris ullamcorper purus sit	18 832,00 ?	471	f
472	t	pede justo eu massa donec dapibus	65 541,00 ?	472	f
473	t	amet justo morbi ut odio	78 762,00 ?	473	f
474	t	non mauris morbi non lectus aliquam	59 209,00 ?	474	t
475	t	lectus pellentesque eget nunc donec quis	22 974,00 ?	475	t
476	f	nonummy maecenas tincidunt lacus at	43 813,00 ?	476	f
477	f	luctus et ultrices posuere cubilia	64 958,00 ?	477	f
478	f	magna vulputate luctus cum sociis natoque	12 530,00 ?	478	t
479	f	orci mauris lacinia sapien quis libero	93 765,00 ?	479	f
480	t	nullam porttitor lacus at turpis donec posuere	65 877,00 ?	480	f
481	f	vestibulum ante ipsum primis in faucibus orci	33 373,00 ?	481	f
482	t	pede malesuada in imperdiet et commodo vulputate	51 437,00 ?	482	t
483	f	magnis dis parturient montes nascetur ridiculus	48 637,00 ?	483	t
484	f	vestibulum rutrum rutrum neque aenean auctor gravida	68 598,00 ?	484	f
485	f	nascetur ridiculus mus etiam vel augue vestibulum	86 128,00 ?	485	t
486	f	blandit mi in porttitor pede	35 735,00 ?	486	t
487	f	venenatis tristique fusce congue diam id	88 573,00 ?	487	t
488	f	nulla pede ullamcorper augue a suscipit	37 392,00 ?	488	f
489	t	et commodo vulputate justo in blandit	90 838,00 ?	489	f
490	f	mattis pulvinar nulla pede ullamcorper augue	73 462,00 ?	490	t
491	f	amet diam in magna bibendum	49 399,00 ?	491	t
492	f	rhoncus mauris enim leo rhoncus	83 514,00 ?	492	f
493	t	at vulputate vitae nisl aenean lectus pellentesque	55 223,00 ?	493	t
494	f	sapien ut nunc vestibulum ante ipsum primis	28 819,00 ?	494	f
495	t	non mauris morbi non lectus	69 077,00 ?	495	f
496	f	id nisl venenatis lacinia aenean sit	76 240,00 ?	496	f
497	t	et commodo vulputate justo in	90 044,00 ?	497	f
498	t	id justo sit amet sapien dignissim	60 846,00 ?	498	f
499	f	proin interdum mauris non ligula pellentesque ultrices	48 485,00 ?	499	f
500	t	vel sem sed sagittis nam congue risus	76 416,00 ?	500	f
501	t	orci nullam molestie nibh in lectus pellentesque	91 795,00 ?	501	f
502	t	nunc purus phasellus in felis	77 616,00 ?	502	t
503	t	at vulputate vitae nisl aenean	33 700,00 ?	503	f
504	f	nam dui proin leo odio porttitor id	43 348,00 ?	504	f
505	t	id lobortis convallis tortor risus	68 925,00 ?	505	f
506	f	dictumst morbi vestibulum velit id	60 271,00 ?	506	t
507	t	vestibulum vestibulum ante ipsum primis in faucibus	86 828,00 ?	507	f
508	f	volutpat dui maecenas tristique est et tempus	37 888,00 ?	508	t
509	t	justo morbi ut odio cras mi	50 061,00 ?	509	f
510	t	morbi a ipsum integer a nibh in	91 538,00 ?	510	f
511	t	libero quis orci nullam molestie nibh in	59 712,00 ?	511	f
512	f	dictumst maecenas ut massa quis augue luctus	97 368,00 ?	512	t
513	t	sed vel enim sit amet	81 678,00 ?	513	f
514	f	hac habitasse platea dictumst aliquam augue	32 184,00 ?	514	t
515	f	justo eu massa donec dapibus duis	77 217,00 ?	515	t
516	t	pellentesque volutpat dui maecenas tristique est	83 933,00 ?	516	f
517	t	pellentesque at nulla suspendisse potenti	36 961,00 ?	517	t
518	f	dapibus duis at velit eu	85 669,00 ?	518	f
519	t	ligula sit amet eleifend pede	99 052,00 ?	519	t
520	t	aenean lectus pellentesque eget nunc donec	13 892,00 ?	520	t
521	t	sed nisl nunc rhoncus dui vel	32 553,00 ?	521	t
522	f	aliquam sit amet diam in magna	73 284,00 ?	522	t
523	f	massa donec dapibus duis at velit	88 749,00 ?	523	t
524	t	aliquam convallis nunc proin at turpis	28 461,00 ?	524	t
525	t	donec quis orci eget orci	91 938,00 ?	525	f
526	f	et ultrices posuere cubilia curae duis	64 404,00 ?	526	t
527	f	ut suscipit a feugiat et	15 447,00 ?	527	t
528	t	quisque id justo sit amet sapien dignissim	30 515,00 ?	528	t
529	t	nulla quisque arcu libero rutrum ac lobortis	29 309,00 ?	529	t
530	t	lectus in est risus auctor sed tristique	19 922,00 ?	530	f
531	t	sit amet eleifend pede libero quis	15 907,00 ?	531	f
532	t	blandit mi in porttitor pede	33 148,00 ?	532	f
533	f	adipiscing molestie hendrerit at vulputate vitae nisl	15 125,00 ?	533	t
534	t	morbi non quam nec dui	66 619,00 ?	534	t
535	t	in eleifend quam a odio in	12 372,00 ?	535	t
536	t	sit amet cursus id turpis	28 898,00 ?	536	t
537	t	id pretium iaculis diam erat fermentum justo	16 831,00 ?	537	t
538	f	primis in faucibus orci luctus et ultrices	79 375,00 ?	538	t
539	f	viverra eget congue eget semper rutrum nulla	45 197,00 ?	539	t
540	f	mollis molestie lorem quisque ut	90 147,00 ?	540	f
541	f	rhoncus mauris enim leo rhoncus	72 289,00 ?	541	f
542	f	posuere cubilia curae duis faucibus accumsan odio	29 980,00 ?	542	f
543	t	mattis odio donec vitae nisi nam	43 587,00 ?	543	f
544	f	proin leo odio porttitor id	34 835,00 ?	544	f
545	t	velit nec nisi vulputate nonummy maecenas tincidunt	36 588,00 ?	545	t
546	f	suspendisse ornare consequat lectus in est risus	75 899,00 ?	546	t
547	t	accumsan tellus nisi eu orci	14 103,00 ?	547	f
548	t	integer pede justo lacinia eget	16 135,00 ?	548	t
549	f	tincidunt in leo maecenas pulvinar lobortis est	17 208,00 ?	549	f
550	t	erat quisque erat eros viverra eget congue	22 654,00 ?	550	f
551	t	ut tellus nulla ut erat id mauris	74 333,00 ?	551	f
552	f	consequat dui nec nisi volutpat	69 677,00 ?	552	t
553	f	sapien dignissim vestibulum vestibulum ante	92 729,00 ?	553	t
554	f	tincidunt ante vel ipsum praesent blandit lacinia	86 751,00 ?	554	f
555	t	pellentesque viverra pede ac diam cras	63 092,00 ?	555	f
556	t	consequat ut nulla sed accumsan felis	62 709,00 ?	556	f
557	f	convallis eget eleifend luctus ultricies eu nibh	18 851,00 ?	557	f
558	t	elit proin risus praesent lectus vestibulum quam	88 563,00 ?	558	t
559	t	vulputate justo in blandit ultrices	52 936,00 ?	559	t
560	f	eget rutrum at lorem integer	70 882,00 ?	560	f
561	t	felis sed lacus morbi sem mauris laoreet	70 512,00 ?	561	f
562	f	ligula suspendisse ornare consequat lectus in	38 192,00 ?	562	f
563	f	libero ut massa volutpat convallis morbi	56 551,00 ?	563	f
564	f	nulla facilisi cras non velit nec nisi	68 102,00 ?	564	t
565	t	nulla integer pede justo lacinia	27 682,00 ?	565	f
566	t	vestibulum ante ipsum primis in faucibus orci	34 825,00 ?	566	t
567	f	aliquam quis turpis eget elit sodales scelerisque	70 559,00 ?	567	t
568	t	purus phasellus in felis donec semper sapien	89 193,00 ?	568	t
569	f	lacus purus aliquet at feugiat non	95 686,00 ?	569	t
570	t	ultrices aliquet maecenas leo odio	98 295,00 ?	570	t
571	f	ut odio cras mi pede	82 564,00 ?	571	f
572	f	quam pharetra magna ac consequat	27 729,00 ?	572	t
573	t	sem mauris laoreet ut rhoncus aliquet	28 783,00 ?	573	f
574	f	pretium quis lectus suspendisse potenti	67 213,00 ?	574	f
575	f	nisl aenean lectus pellentesque eget	80 449,00 ?	575	f
576	f	rhoncus aliquam lacus morbi quis tortor	75 433,00 ?	576	t
577	f	id sapien in sapien iaculis congue vivamus	68 027,00 ?	577	f
578	f	potenti in eleifend quam a odio	31 516,00 ?	578	f
579	t	nullam orci pede venenatis non sodales sed	15 029,00 ?	579	f
580	t	congue eget semper rutrum nulla nunc purus	32 414,00 ?	580	f
581	t	mollis molestie lorem quisque ut erat curabitur	90 260,00 ?	581	t
582	t	eu orci mauris lacinia sapien quis	30 460,00 ?	582	f
583	f	imperdiet nullam orci pede venenatis	50 758,00 ?	583	t
584	t	auctor gravida sem praesent id massa id	63 944,00 ?	584	f
585	f	nec sem duis aliquam convallis	27 804,00 ?	585	t
586	t	sapien in sapien iaculis congue vivamus metus	97 846,00 ?	586	f
587	f	sed nisl nunc rhoncus dui vel sem	78 798,00 ?	587	t
588	f	lobortis sapien sapien non mi	80 558,00 ?	588	f
589	t	eu mi nulla ac enim in tempor	37 800,00 ?	589	f
590	f	aliquam augue quam sollicitudin vitae consectetuer	84 355,00 ?	590	f
591	t	curabitur convallis duis consequat dui nec	55 179,00 ?	591	f
592	t	quam turpis adipiscing lorem vitae	36 771,00 ?	592	f
593	t	lorem quisque ut erat curabitur gravida nisi	63 604,00 ?	593	f
594	f	elementum in hac habitasse platea	44 695,00 ?	594	f
595	t	semper porta volutpat quam pede lobortis ligula	71 031,00 ?	595	f
596	f	sem sed sagittis nam congue risus	22 335,00 ?	596	f
597	f	eu tincidunt in leo maecenas	73 121,00 ?	597	t
598	t	blandit nam nulla integer pede justo	25 309,00 ?	598	f
599	t	praesent blandit nam nulla integer	58 983,00 ?	599	f
600	t	turpis a pede posuere nonummy	69 951,00 ?	600	f
601	t	eu interdum eu tincidunt in leo	91 187,00 ?	601	t
602	f	luctus et ultrices posuere cubilia curae duis	22 384,00 ?	602	t
603	f	nulla sed vel enim sit amet nunc	35 622,00 ?	603	t
604	f	erat tortor sollicitudin mi sit amet lobortis	82 096,00 ?	604	f
605	f	sit amet justo morbi ut	70 826,00 ?	605	f
606	t	nulla tempus vivamus in felis eu sapien	95 512,00 ?	606	f
607	f	risus dapibus augue vel accumsan	70 016,00 ?	607	t
608	f	amet justo morbi ut odio cras	92 410,00 ?	608	f
609	t	sed interdum venenatis turpis enim	43 137,00 ?	609	f
610	f	rhoncus sed vestibulum sit amet cursus	10 844,00 ?	610	t
611	t	ante ipsum primis in faucibus	83 234,00 ?	611	f
612	f	consequat varius integer ac leo pellentesque ultrices	51 009,00 ?	612	t
613	t	odio condimentum id luctus nec	57 425,00 ?	613	t
614	t	viverra eget congue eget semper rutrum	33 703,00 ?	614	t
615	t	aenean auctor gravida sem praesent id	64 559,00 ?	615	f
616	t	praesent id massa id nisl venenatis lacinia	96 871,00 ?	616	t
617	t	tellus nisi eu orci mauris	65 262,00 ?	617	f
618	t	amet erat nulla tempus vivamus in felis	54 203,00 ?	618	f
619	f	ut nulla sed accumsan felis ut	82 758,00 ?	619	t
620	f	nulla ac enim in tempor	36 754,00 ?	620	f
621	t	vivamus vel nulla eget eros elementum	75 818,00 ?	621	t
622	t	pede venenatis non sodales sed	27 948,00 ?	622	f
623	t	nulla suscipit ligula in lacus	80 215,00 ?	623	t
624	t	augue luctus tincidunt nulla mollis molestie lorem	46 401,00 ?	624	t
625	t	nibh ligula nec sem duis	66 146,00 ?	625	f
626	t	vestibulum quam sapien varius ut blandit non	98 279,00 ?	626	f
627	t	cursus urna ut tellus nulla ut erat	51 373,00 ?	627	t
628	f	duis faucibus accumsan odio curabitur convallis	83 542,00 ?	628	f
629	t	aliquam erat volutpat in congue etiam	33 222,00 ?	629	f
630	t	nunc viverra dapibus nulla suscipit ligula	77 930,00 ?	630	f
631	t	enim sit amet nunc viverra dapibus nulla	23 526,00 ?	631	f
632	f	eget elit sodales scelerisque mauris sit amet	37 687,00 ?	632	f
633	f	nec euismod scelerisque quam turpis adipiscing	85 042,00 ?	633	f
634	f	et ultrices posuere cubilia curae	61 910,00 ?	634	f
635	f	amet erat nulla tempus vivamus in	90 683,00 ?	635	f
636	t	mauris lacinia sapien quis libero nullam	31 144,00 ?	636	t
637	t	vel nisl duis ac nibh	18 531,00 ?	637	f
638	f	donec ut mauris eget massa tempor	17 143,00 ?	638	f
639	t	quam pharetra magna ac consequat	11 872,00 ?	639	f
640	f	enim lorem ipsum dolor sit amet consectetuer	89 532,00 ?	640	f
641	f	nulla integer pede justo lacinia eget tincidunt	90 163,00 ?	641	t
642	f	eu interdum eu tincidunt in leo maecenas	62 747,00 ?	642	t
643	t	sapien iaculis congue vivamus metus arcu adipiscing	31 715,00 ?	643	f
644	t	suscipit ligula in lacus curabitur at	69 003,00 ?	644	f
645	f	justo eu massa donec dapibus duis	67 217,00 ?	645	t
646	t	nec sem duis aliquam convallis nunc	73 399,00 ?	646	t
647	f	sociis natoque penatibus et magnis dis	41 170,00 ?	647	f
648	f	id nulla ultrices aliquet maecenas	94 180,00 ?	648	f
649	t	est quam pharetra magna ac consequat metus	52 917,00 ?	649	t
650	f	faucibus orci luctus et ultrices posuere cubilia	66 275,00 ?	650	f
651	f	sapien sapien non mi integer ac neque	42 684,00 ?	651	f
652	t	ut massa quis augue luctus tincidunt nulla	35 631,00 ?	652	f
653	t	rutrum rutrum neque aenean auctor gravida sem	80 467,00 ?	653	t
654	f	sed nisl nunc rhoncus dui vel sem	26 294,00 ?	654	f
655	t	adipiscing lorem vitae mattis nibh	59 480,00 ?	655	f
656	f	tristique fusce congue diam id	80 306,00 ?	656	t
657	t	molestie lorem quisque ut erat curabitur gravida	60 815,00 ?	657	f
658	t	interdum eu tincidunt in leo maecenas	12 813,00 ?	658	f
659	f	amet eros suspendisse accumsan tortor	26 128,00 ?	659	t
660	t	vulputate elementum nullam varius nulla facilisi	67 163,00 ?	660	t
661	t	est quam pharetra magna ac consequat	13 032,00 ?	661	t
662	t	nec nisi vulputate nonummy maecenas	22 221,00 ?	662	f
663	t	sapien varius ut blandit non interdum	58 318,00 ?	663	f
664	t	magna vulputate luctus cum sociis natoque penatibus	64 934,00 ?	664	f
665	t	eget elit sodales scelerisque mauris	39 706,00 ?	665	f
666	t	quam suspendisse potenti nullam porttitor lacus at	71 414,00 ?	666	f
667	t	libero ut massa volutpat convallis	51 347,00 ?	667	t
668	t	ullamcorper purus sit amet nulla	87 205,00 ?	668	t
669	t	suspendisse ornare consequat lectus in est	36 353,00 ?	669	t
670	f	semper porta volutpat quam pede	27 259,00 ?	670	f
671	f	lectus pellentesque eget nunc donec quis orci	55 141,00 ?	671	f
672	f	consequat lectus in est risus auctor	38 909,00 ?	672	t
673	t	pretium iaculis justo in hac habitasse	19 776,00 ?	673	t
674	f	nulla sed vel enim sit amet nunc	18 325,00 ?	674	f
675	t	ac lobortis vel dapibus at diam	40 213,00 ?	675	f
676	f	eget orci vehicula condimentum curabitur	86 097,00 ?	676	f
677	t	vel pede morbi porttitor lorem	43 035,00 ?	677	t
678	f	in faucibus orci luctus et	47 823,00 ?	678	t
679	f	diam nam tristique tortor eu pede	19 777,00 ?	679	t
680	t	convallis tortor risus dapibus augue vel accumsan	43 624,00 ?	680	f
681	t	et tempus semper est quam pharetra magna	94 924,00 ?	681	t
682	t	ac leo pellentesque ultrices mattis odio donec	82 953,00 ?	682	f
683	t	consectetuer eget rutrum at lorem integer tincidunt	87 952,00 ?	683	t
684	t	aliquam non mauris morbi non lectus	72 767,00 ?	684	t
685	t	volutpat eleifend donec ut dolor	87 723,00 ?	685	t
686	f	sed vestibulum sit amet cursus id turpis	12 161,00 ?	686	f
687	f	amet eleifend pede libero quis	29 785,00 ?	687	t
688	t	vel sem sed sagittis nam congue	48 510,00 ?	688	f
689	t	facilisi cras non velit nec nisi vulputate	12 969,00 ?	689	t
690	t	aliquam non mauris morbi non lectus aliquam	26 110,00 ?	690	f
691	t	sollicitudin ut suscipit a feugiat et	98 947,00 ?	691	t
692	f	vitae mattis nibh ligula nec sem duis	83 665,00 ?	692	t
693	t	felis donec semper sapien a libero	36 372,00 ?	693	t
694	t	metus sapien ut nunc vestibulum	94 657,00 ?	694	f
695	f	malesuada in imperdiet et commodo	59 378,00 ?	695	f
696	t	lectus in quam fringilla rhoncus	20 556,00 ?	696	f
697	f	rutrum nulla nunc purus phasellus in felis	11 001,00 ?	697	t
698	f	orci luctus et ultrices posuere cubilia curae	81 075,00 ?	698	f
699	t	nulla facilisi cras non velit nec	31 679,00 ?	699	t
700	t	eros elementum pellentesque quisque porta volutpat erat	84 791,00 ?	700	t
701	f	sociis natoque penatibus et magnis	79 479,00 ?	701	f
702	f	quisque porta volutpat erat quisque	64 161,00 ?	702	t
703	f	vel nisl duis ac nibh fusce	10 770,00 ?	703	t
704	f	odio odio elementum eu interdum eu	84 828,00 ?	704	t
705	f	libero quis orci nullam molestie nibh	75 912,00 ?	705	t
706	f	lobortis est phasellus sit amet	40 680,00 ?	706	t
707	f	pretium nisl ut volutpat sapien	89 053,00 ?	707	t
708	f	ipsum aliquam non mauris morbi non	53 564,00 ?	708	f
709	f	scelerisque mauris sit amet eros suspendisse	94 992,00 ?	709	f
710	t	sed nisl nunc rhoncus dui vel	97 071,00 ?	710	t
711	t	platea dictumst morbi vestibulum velit	39 427,00 ?	711	t
712	f	mauris ullamcorper purus sit amet nulla quisque	40 162,00 ?	712	t
713	t	rutrum nulla tellus in sagittis dui vel	61 829,00 ?	713	t
714	f	elementum nullam varius nulla facilisi cras	45 369,00 ?	714	t
715	f	ultrices phasellus id sapien in sapien	86 255,00 ?	715	f
716	t	posuere cubilia curae nulla dapibus dolor	80 753,00 ?	716	t
717	t	a ipsum integer a nibh in quis	32 870,00 ?	717	f
718	t	massa quis augue luctus tincidunt nulla mollis	78 583,00 ?	718	f
719	f	parturient montes nascetur ridiculus mus etiam	84 970,00 ?	719	t
720	t	nulla suscipit ligula in lacus curabitur at	37 842,00 ?	720	t
721	f	consequat varius integer ac leo pellentesque ultrices	66 859,00 ?	721	t
722	f	quam a odio in hac habitasse platea	49 218,00 ?	722	t
723	t	est donec odio justo sollicitudin ut suscipit	18 887,00 ?	723	f
724	f	sapien varius ut blandit non interdum in	56 653,00 ?	724	f
725	f	pretium nisl ut volutpat sapien arcu	20 580,00 ?	725	f
726	f	pede venenatis non sodales sed	96 717,00 ?	726	f
727	t	nulla elit ac nulla sed	40 609,00 ?	727	t
728	t	lacus at velit vivamus vel	99 086,00 ?	728	f
729	t	vehicula consequat morbi a ipsum	89 648,00 ?	729	f
730	t	eros suspendisse accumsan tortor quis turpis sed	75 500,00 ?	730	t
731	f	eu interdum eu tincidunt in	63 585,00 ?	731	f
732	f	luctus ultricies eu nibh quisque id justo	60 581,00 ?	732	f
733	f	ipsum primis in faucibus orci luctus	72 161,00 ?	733	f
734	f	lectus in est risus auctor sed	57 146,00 ?	734	t
735	t	felis eu sapien cursus vestibulum	27 209,00 ?	735	t
736	f	viverra pede ac diam cras pellentesque	30 309,00 ?	736	f
737	f	primis in faucibus orci luctus et ultrices	96 111,00 ?	737	t
738	f	aliquam sit amet diam in magna	21 669,00 ?	738	f
739	t	faucibus orci luctus et ultrices	54 507,00 ?	739	t
740	t	mi integer ac neque duis bibendum	32 124,00 ?	740	f
741	t	consectetuer eget rutrum at lorem integer tincidunt	71 687,00 ?	741	t
742	f	ac nibh fusce lacus purus aliquet at	76 810,00 ?	742	f
743	t	sit amet nunc viverra dapibus nulla	37 310,00 ?	743	t
744	t	ultrices posuere cubilia curae mauris viverra	34 029,00 ?	744	t
745	f	nonummy integer non velit donec diam	49 808,00 ?	745	t
746	f	in lectus pellentesque at nulla	69 802,00 ?	746	f
747	f	eget semper rutrum nulla nunc	38 029,00 ?	747	f
748	f	consequat in consequat ut nulla sed	79 778,00 ?	748	t
749	t	varius ut blandit non interdum	41 741,00 ?	749	f
750	t	suspendisse potenti in eleifend quam a odio	23 552,00 ?	750	t
751	f	luctus tincidunt nulla mollis molestie	45 115,00 ?	751	t
752	t	magna at nunc commodo placerat praesent	89 932,00 ?	752	f
753	t	luctus rutrum nulla tellus in sagittis	15 515,00 ?	753	f
754	f	iaculis justo in hac habitasse platea	61 456,00 ?	754	f
755	f	nulla sed vel enim sit amet nunc	73 919,00 ?	755	t
756	f	nulla suspendisse potenti cras in purus	54 283,00 ?	756	t
757	t	dapibus duis at velit eu est	65 765,00 ?	757	f
758	f	purus sit amet nulla quisque	57 890,00 ?	758	f
759	f	lorem vitae mattis nibh ligula nec sem	92 388,00 ?	759	t
760	f	euismod scelerisque quam turpis adipiscing lorem vitae	27 240,00 ?	760	t
761	f	auctor sed tristique in tempus sit	28 149,00 ?	761	f
762	t	ipsum primis in faucibus orci	15 838,00 ?	762	t
763	f	vestibulum quam sapien varius ut blandit non	81 861,00 ?	763	f
764	f	sed sagittis nam congue risus	94 392,00 ?	764	t
765	t	pede malesuada in imperdiet et commodo vulputate	88 698,00 ?	765	t
766	f	sagittis dui vel nisl duis ac	21 937,00 ?	766	f
767	t	interdum venenatis turpis enim blandit mi in	55 491,00 ?	767	t
768	t	tincidunt in leo maecenas pulvinar lobortis	25 813,00 ?	768	t
769	f	sem fusce consequat nulla nisl nunc nisl	40 267,00 ?	769	t
770	f	vitae nisl aenean lectus pellentesque eget nunc	20 262,00 ?	770	f
771	f	integer non velit donec diam neque vestibulum	36 419,00 ?	771	f
772	f	cubilia curae nulla dapibus dolor	81 297,00 ?	772	t
773	f	amet sem fusce consequat nulla	75 273,00 ?	773	f
774	t	volutpat convallis morbi odio odio	95 667,00 ?	774	t
775	t	eleifend luctus ultricies eu nibh quisque	31 488,00 ?	775	f
776	t	morbi vestibulum velit id pretium	27 365,00 ?	776	t
777	t	risus semper porta volutpat quam pede	29 034,00 ?	777	t
778	f	montes nascetur ridiculus mus vivamus vestibulum	69 006,00 ?	778	f
779	f	erat eros viverra eget congue eget	16 273,00 ?	779	f
780	t	sed ante vivamus tortor duis	92 531,00 ?	780	f
781	f	suspendisse ornare consequat lectus in est risus	32 706,00 ?	781	t
782	f	sociis natoque penatibus et magnis dis parturient	73 869,00 ?	782	f
783	t	risus semper porta volutpat quam pede lobortis	64 941,00 ?	783	f
784	f	integer pede justo lacinia eget tincidunt eget	72 811,00 ?	784	t
785	t	in sapien iaculis congue vivamus	90 390,00 ?	785	f
786	f	at vulputate vitae nisl aenean lectus pellentesque	85 647,00 ?	786	f
787	t	in faucibus orci luctus et ultrices	61 774,00 ?	787	t
788	t	enim leo rhoncus sed vestibulum sit amet	23 463,00 ?	788	t
789	t	justo nec condimentum neque sapien placerat	70 429,00 ?	789	f
790	t	ipsum praesent blandit lacinia erat vestibulum sed	91 699,00 ?	790	t
791	t	consequat dui nec nisi volutpat eleifend donec	97 100,00 ?	791	f
792	t	eros viverra eget congue eget	79 150,00 ?	792	t
793	t	amet consectetuer adipiscing elit proin risus	27 302,00 ?	793	t
794	f	hac habitasse platea dictumst etiam faucibus	55 910,00 ?	794	t
795	t	vestibulum ante ipsum primis in faucibus	95 603,00 ?	795	f
796	t	a pede posuere nonummy integer non	92 928,00 ?	796	f
797	f	tristique est et tempus semper est	78 506,00 ?	797	f
798	t	luctus et ultrices posuere cubilia curae	75 808,00 ?	798	t
799	f	magnis dis parturient montes nascetur ridiculus	40 831,00 ?	799	t
800	f	curae nulla dapibus dolor vel	35 409,00 ?	800	f
801	f	consequat varius integer ac leo	68 455,00 ?	801	t
802	t	eu nibh quisque id justo sit amet	13 764,00 ?	802	f
803	t	cubilia curae duis faucibus accumsan odio curabitur	52 232,00 ?	803	f
804	t	eu mi nulla ac enim	88 717,00 ?	804	t
805	f	consectetuer adipiscing elit proin risus praesent lectus	85 501,00 ?	805	f
806	f	ipsum primis in faucibus orci luctus	17 375,00 ?	806	t
807	f	aenean auctor gravida sem praesent id	11 014,00 ?	807	t
808	f	luctus et ultrices posuere cubilia curae	40 232,00 ?	808	f
809	t	magna ac consequat metus sapien ut nunc	76 933,00 ?	809	f
810	t	dis parturient montes nascetur ridiculus mus	28 144,00 ?	810	t
811	f	quam nec dui luctus rutrum	86 094,00 ?	811	f
812	f	nec nisi volutpat eleifend donec	55 914,00 ?	812	f
813	t	interdum mauris ullamcorper purus sit amet	18 164,00 ?	813	f
814	f	tempus sit amet sem fusce consequat nulla	32 421,00 ?	814	t
815	t	laoreet ut rhoncus aliquet pulvinar sed nisl	37 559,00 ?	815	t
816	t	ipsum praesent blandit lacinia erat vestibulum sed	68 276,00 ?	816	f
817	t	porta volutpat erat quisque erat	64 572,00 ?	817	f
818	t	sit amet consectetuer adipiscing elit proin risus	68 087,00 ?	818	t
819	f	posuere felis sed lacus morbi sem mauris	69 396,00 ?	819	t
820	f	sed augue aliquam erat volutpat	50 396,00 ?	820	t
821	f	vehicula consequat morbi a ipsum	53 127,00 ?	821	t
822	t	diam nam tristique tortor eu	86 939,00 ?	822	t
823	t	vel nulla eget eros elementum pellentesque	59 377,00 ?	823	t
824	t	vestibulum ante ipsum primis in	89 971,00 ?	824	t
825	t	ultricies eu nibh quisque id	36 423,00 ?	825	t
826	t	nisi eu orci mauris lacinia	88 679,00 ?	826	t
827	f	porta volutpat quam pede lobortis ligula sit	63 021,00 ?	827	t
828	t	leo pellentesque ultrices mattis odio donec vitae	97 378,00 ?	828	f
829	f	posuere nonummy integer non velit	24 319,00 ?	829	f
830	t	felis fusce posuere felis sed lacus	46 553,00 ?	830	f
831	t	leo odio condimentum id luctus	44 752,00 ?	831	f
832	f	nulla suscipit ligula in lacus curabitur	43 232,00 ?	832	f
833	t	enim in tempor turpis nec euismod scelerisque	60 020,00 ?	833	t
834	t	at nunc commodo placerat praesent	33 300,00 ?	834	f
835	f	turpis donec posuere metus vitae ipsum	51 753,00 ?	835	f
836	t	est quam pharetra magna ac	18 984,00 ?	836	f
837	f	velit nec nisi vulputate nonummy	68 429,00 ?	837	f
838	f	vestibulum ante ipsum primis in faucibus orci	18 681,00 ?	838	f
839	t	tincidunt lacus at velit vivamus vel	63 526,00 ?	839	f
840	t	mauris laoreet ut rhoncus aliquet pulvinar	74 183,00 ?	840	f
841	f	duis faucibus accumsan odio curabitur convallis duis	80 215,00 ?	841	f
842	t	non pretium quis lectus suspendisse potenti	25 086,00 ?	842	t
843	f	nullam sit amet turpis elementum ligula vehicula	25 744,00 ?	843	f
844	t	dui luctus rutrum nulla tellus in	44 708,00 ?	844	t
845	t	accumsan tortor quis turpis sed ante vivamus	22 665,00 ?	845	t
846	t	nunc commodo placerat praesent blandit nam	65 904,00 ?	846	t
847	f	consequat in consequat ut nulla sed	58 408,00 ?	847	f
848	t	ac consequat metus sapien ut nunc	30 648,00 ?	848	t
849	t	pharetra magna ac consequat metus sapien ut	91 148,00 ?	849	f
850	t	proin risus praesent lectus vestibulum quam sapien	72 599,00 ?	850	f
851	t	turpis donec posuere metus vitae ipsum	77 803,00 ?	851	f
852	t	luctus et ultrices posuere cubilia curae nulla	37 835,00 ?	852	f
853	t	et commodo vulputate justo in	66 096,00 ?	853	f
854	t	eros vestibulum ac est lacinia	58 242,00 ?	854	f
855	f	mi sit amet lobortis sapien sapien	42 616,00 ?	855	f
856	t	enim lorem ipsum dolor sit amet	72 185,00 ?	856	f
857	f	amet nulla quisque arcu libero rutrum ac	90 262,00 ?	857	t
858	f	erat volutpat in congue etiam justo etiam	95 510,00 ?	858	t
859	f	quis augue luctus tincidunt nulla mollis	33 580,00 ?	859	t
860	t	nibh ligula nec sem duis aliquam convallis	30 958,00 ?	860	f
861	f	cum sociis natoque penatibus et	79 059,00 ?	861	f
862	f	tellus nulla ut erat id mauris vulputate	94 225,00 ?	862	f
863	t	vivamus metus arcu adipiscing molestie	57 898,00 ?	863	t
864	f	non lectus aliquam sit amet diam	65 160,00 ?	864	f
865	t	maecenas ut massa quis augue luctus tincidunt	42 246,00 ?	865	t
866	f	dapibus nulla suscipit ligula in lacus curabitur	82 440,00 ?	866	t
867	f	quam fringilla rhoncus mauris enim leo rhoncus	67 528,00 ?	867	t
868	t	vehicula consequat morbi a ipsum	32 790,00 ?	868	t
869	f	at ipsum ac tellus semper interdum	75 923,00 ?	869	t
870	t	auctor sed tristique in tempus	76 529,00 ?	870	f
871	t	viverra pede ac diam cras pellentesque volutpat	87 708,00 ?	871	f
872	f	amet diam in magna bibendum imperdiet	69 600,00 ?	872	t
873	f	lacus purus aliquet at feugiat non pretium	32 519,00 ?	873	t
874	f	diam in magna bibendum imperdiet nullam orci	18 751,00 ?	874	t
875	t	faucibus orci luctus et ultrices posuere cubilia	36 410,00 ?	875	t
876	t	cursus urna ut tellus nulla ut erat	92 497,00 ?	876	f
877	t	eget elit sodales scelerisque mauris sit amet	45 183,00 ?	877	t
878	t	odio odio elementum eu interdum	86 317,00 ?	878	f
879	t	mattis odio donec vitae nisi nam	16 576,00 ?	879	t
880	f	in hac habitasse platea dictumst	18 626,00 ?	880	t
881	t	amet sem fusce consequat nulla nisl	90 124,00 ?	881	t
882	t	pretium iaculis diam erat fermentum justo nec	55 579,00 ?	882	f
883	t	curae nulla dapibus dolor vel est	11 220,00 ?	883	t
884	f	lobortis convallis tortor risus dapibus augue vel	37 875,00 ?	884	t
885	t	id massa id nisl venenatis lacinia aenean	33 499,00 ?	885	t
886	f	nullam molestie nibh in lectus	46 204,00 ?	886	f
887	f	primis in faucibus orci luctus et ultrices	91 801,00 ?	887	f
888	f	nulla sed accumsan felis ut	73 823,00 ?	888	t
889	t	blandit non interdum in ante	88 895,00 ?	889	t
890	t	lectus in est risus auctor sed tristique	15 132,00 ?	890	t
891	t	accumsan tortor quis turpis sed	23 033,00 ?	891	f
892	t	risus semper porta volutpat quam pede	78 206,00 ?	892	f
893	t	velit id pretium iaculis diam	12 074,00 ?	893	f
894	f	rutrum ac lobortis vel dapibus at	25 944,00 ?	894	t
895	t	morbi sem mauris laoreet ut rhoncus aliquet	72 810,00 ?	895	t
896	t	morbi sem mauris laoreet ut rhoncus	65 313,00 ?	896	t
897	t	suscipit ligula in lacus curabitur at	60 573,00 ?	897	t
898	f	purus sit amet nulla quisque arcu libero	84 800,00 ?	898	t
899	t	posuere cubilia curae nulla dapibus dolor vel	43 326,00 ?	899	f
900	f	pharetra magna ac consequat metus sapien	72 803,00 ?	900	f
901	t	vel nulla eget eros elementum pellentesque	64 475,00 ?	901	t
902	f	egestas metus aenean fermentum donec ut mauris	24 420,00 ?	902	f
903	t	quis odio consequat varius integer	60 677,00 ?	903	t
904	t	suspendisse potenti in eleifend quam a	40 124,00 ?	904	t
905	f	tempus vivamus in felis eu sapien cursus	23 193,00 ?	905	t
906	t	vitae consectetuer eget rutrum at lorem	22 715,00 ?	906	f
907	t	condimentum curabitur in libero ut	10 365,00 ?	907	f
908	t	proin risus praesent lectus vestibulum quam	64 110,00 ?	908	f
909	t	volutpat in congue etiam justo	22 276,00 ?	909	t
910	f	luctus tincidunt nulla mollis molestie lorem	10 958,00 ?	910	f
911	f	odio curabitur convallis duis consequat dui	54 754,00 ?	911	t
912	t	in tempor turpis nec euismod scelerisque quam	44 448,00 ?	912	f
913	f	cursus id turpis integer aliquet massa	55 803,00 ?	913	f
914	f	rutrum ac lobortis vel dapibus	42 170,00 ?	914	f
915	t	est phasellus sit amet erat nulla	99 963,00 ?	915	t
916	f	tempus vel pede morbi porttitor lorem	36 830,00 ?	916	t
917	t	sapien non mi integer ac	58 369,00 ?	917	f
918	f	sapien arcu sed augue aliquam	86 456,00 ?	918	t
919	f	sed ante vivamus tortor duis mattis egestas	19 358,00 ?	919	f
920	t	et ultrices posuere cubilia curae duis faucibus	13 811,00 ?	920	f
921	f	dui luctus rutrum nulla tellus	40 322,00 ?	921	f
922	f	libero rutrum ac lobortis vel dapibus	77 784,00 ?	922	t
923	t	aenean auctor gravida sem praesent	44 956,00 ?	923	f
924	f	nullam molestie nibh in lectus	22 994,00 ?	924	f
925	f	consequat nulla nisl nunc nisl	75 781,00 ?	925	f
926	t	augue quam sollicitudin vitae consectetuer eget	41 657,00 ?	926	t
927	f	est congue elementum in hac habitasse	30 174,00 ?	927	f
928	t	ac tellus semper interdum mauris	96 791,00 ?	928	t
929	t	vel lectus in quam fringilla	95 351,00 ?	929	f
930	t	accumsan odio curabitur convallis duis consequat	85 511,00 ?	930	f
931	f	iaculis justo in hac habitasse platea dictumst	98 746,00 ?	931	t
932	f	est quam pharetra magna ac consequat	58 078,00 ?	932	t
933	f	quam pharetra magna ac consequat metus sapien	21 182,00 ?	933	f
934	t	viverra eget congue eget semper	63 900,00 ?	934	t
935	t	mauris enim leo rhoncus sed vestibulum	55 078,00 ?	935	f
936	f	tortor duis mattis egestas metus aenean	26 043,00 ?	936	f
937	f	felis eu sapien cursus vestibulum	62 746,00 ?	937	f
938	f	nec nisi volutpat eleifend donec ut dolor	48 760,00 ?	938	t
939	t	pede justo eu massa donec dapibus duis	46 375,00 ?	939	f
940	f	dapibus duis at velit eu est	14 418,00 ?	940	f
941	f	morbi vel lectus in quam fringilla	16 216,00 ?	941	f
942	t	parturient montes nascetur ridiculus mus vivamus vestibulum	16 391,00 ?	942	t
943	f	nullam varius nulla facilisi cras	25 326,00 ?	943	t
944	t	pretium quis lectus suspendisse potenti	20 203,00 ?	944	t
945	f	libero convallis eget eleifend luctus	33 098,00 ?	945	f
946	t	amet eleifend pede libero quis	95 323,00 ?	946	t
947	t	blandit ultrices enim lorem ipsum dolor sit	28 020,00 ?	947	f
948	f	nulla facilisi cras non velit	49 441,00 ?	948	t
949	t	sit amet nunc viverra dapibus	31 051,00 ?	949	f
950	t	nam congue risus semper porta volutpat quam	59 442,00 ?	950	f
951	f	suscipit nulla elit ac nulla sed vel	72 006,00 ?	951	t
952	t	a odio in hac habitasse platea	44 264,00 ?	952	t
953	f	et commodo vulputate justo in	59 155,00 ?	953	t
954	f	dolor quis odio consequat varius integer ac	72 932,00 ?	954	t
955	f	luctus et ultrices posuere cubilia	38 595,00 ?	955	t
956	t	nisi nam ultrices libero non mattis pulvinar	55 358,00 ?	956	f
957	t	volutpat eleifend donec ut dolor	95 395,00 ?	957	t
958	f	et ultrices posuere cubilia curae	55 196,00 ?	958	f
959	f	varius nulla facilisi cras non velit	12 346,00 ?	959	t
960	t	duis aliquam convallis nunc proin at turpis	88 640,00 ?	960	t
961	f	sit amet justo morbi ut	76 070,00 ?	961	f
962	t	pellentesque eget nunc donec quis orci	87 443,00 ?	962	f
963	f	eget vulputate ut ultrices vel augue	23 681,00 ?	963	t
964	t	erat volutpat in congue etiam justo	82 349,00 ?	964	t
965	t	metus aenean fermentum donec ut	99 265,00 ?	965	f
966	t	penatibus et magnis dis parturient montes nascetur	79 981,00 ?	966	f
967	f	nunc vestibulum ante ipsum primis in	79 937,00 ?	967	f
968	f	hac habitasse platea dictumst aliquam	34 555,00 ?	968	t
969	t	lacus purus aliquet at feugiat non	78 415,00 ?	969	f
970	t	aenean fermentum donec ut mauris eget massa	88 395,00 ?	970	f
971	t	congue elementum in hac habitasse	52 423,00 ?	971	f
972	t	luctus et ultrices posuere cubilia curae duis	68 449,00 ?	972	t
973	f	diam erat fermentum justo nec condimentum	89 757,00 ?	973	f
974	t	at dolor quis odio consequat varius integer	58 308,00 ?	974	f
975	f	vestibulum rutrum rutrum neque aenean auctor	89 370,00 ?	975	t
976	t	odio condimentum id luctus nec molestie	72 339,00 ?	976	t
977	f	porta volutpat erat quisque erat eros	27 277,00 ?	977	f
978	t	venenatis tristique fusce congue diam	32 820,00 ?	978	t
979	f	venenatis turpis enim blandit mi in	49 711,00 ?	979	f
980	t	libero non mattis pulvinar nulla pede ullamcorper	81 768,00 ?	980	f
981	t	eros viverra eget congue eget	70 812,00 ?	981	t
982	f	suspendisse accumsan tortor quis turpis sed	17 233,00 ?	982	t
983	t	rutrum ac lobortis vel dapibus at diam	16 033,00 ?	983	t
984	f	eros viverra eget congue eget semper	20 620,00 ?	984	t
985	t	donec vitae nisi nam ultrices libero	39 420,00 ?	985	t
986	f	aliquam sit amet diam in magna bibendum	36 019,00 ?	986	f
987	f	turpis enim blandit mi in porttitor	14 108,00 ?	987	t
988	t	dui maecenas tristique est et tempus	16 624,00 ?	988	t
989	t	nulla justo aliquam quis turpis eget	18 519,00 ?	989	f
990	f	magna vestibulum aliquet ultrices erat	13 470,00 ?	990	t
991	f	eget semper rutrum nulla nunc purus phasellus	92 834,00 ?	991	t
992	t	ut massa quis augue luctus tincidunt nulla	20 090,00 ?	992	f
993	t	hendrerit at vulputate vitae nisl	46 823,00 ?	993	t
994	t	vulputate vitae nisl aenean lectus pellentesque eget	39 380,00 ?	994	f
995	f	interdum in ante vestibulum ante	27 800,00 ?	995	f
996	t	ut dolor morbi vel lectus in	60 600,00 ?	996	t
997	f	amet lobortis sapien sapien non	82 428,00 ?	997	t
998	t	dui luctus rutrum nulla tellus	28 133,00 ?	998	f
999	f	ipsum primis in faucibus orci luctus	38 619,00 ?	999	t
1000	t	magna vulputate luctus cum sociis natoque	69 076,00 ?	1000	f
203	f	lacinia nisi venenatis tristique fusce	78 512,00 ?	203	t
\.


--
-- TOC entry 3176 (class 0 OID 16513)
-- Dependencies: 214
-- Data for Name: department_stores_medicine; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.department_stores_medicine (id_medicine, id_storage_department, number) FROM stdin;
1	4	100
3	3	40
4	3	60
5	5	65
6	5	90
7	3	106
8	4	113
9	4	120
10	5	96
13	13	214
14	14	183
15	15	147
16	16	55
17	17	106
18	18	82
19	19	198
20	20	94
21	21	191
22	22	120
23	23	101
24	24	109
25	25	155
26	26	221
27	27	214
28	28	31
29	29	129
30	30	95
31	31	188
32	32	196
33	33	186
34	34	121
35	35	73
36	36	172
37	37	150
38	38	222
39	39	114
40	40	113
41	41	227
42	42	31
43	43	138
44	44	134
45	45	32
46	46	50
47	47	52
48	48	139
49	49	214
50	50	162
51	51	72
52	52	153
11	1	40
12	1	30
2	1	30
53	53	88
54	54	52
55	55	109
56	56	27
57	57	70
58	58	163
59	59	134
60	60	61
61	61	28
62	62	124
63	63	145
64	64	109
65	65	170
66	66	117
67	67	171
68	68	160
69	69	187
70	70	218
71	71	189
72	72	227
73	73	74
74	74	122
75	75	29
76	76	40
77	77	212
78	78	75
79	79	31
80	80	217
81	81	16
82	82	42
83	83	86
84	84	63
85	85	133
86	86	111
87	87	130
88	88	85
89	89	20
90	90	140
91	91	102
92	92	199
93	93	132
94	94	179
95	95	200
96	96	88
97	97	73
98	98	84
99	99	92
100	100	230
101	101	11
102	102	228
103	103	219
104	104	64
105	105	145
106	106	104
107	107	144
108	108	27
109	109	161
110	110	17
111	111	160
112	112	220
113	113	100
114	114	48
115	115	59
116	116	48
117	117	130
118	118	86
119	119	76
120	120	190
121	121	229
122	122	106
123	123	177
124	124	220
125	125	216
126	126	108
127	127	53
128	128	87
129	129	52
130	130	12
131	131	125
132	132	49
133	133	149
134	134	206
135	135	180
136	136	52
137	137	111
138	138	109
139	139	126
140	140	68
141	141	207
142	142	151
143	143	86
144	144	157
145	145	62
146	146	124
147	147	37
148	148	69
149	149	132
150	150	58
151	151	157
152	152	81
153	153	215
154	154	53
155	155	172
156	156	170
157	157	183
158	158	88
159	159	109
160	160	140
161	161	141
162	162	33
163	163	130
164	164	131
165	165	196
166	166	82
167	167	208
168	168	141
169	169	198
170	170	168
171	171	167
172	172	59
173	173	177
174	174	31
175	175	32
176	176	146
177	177	107
178	178	142
179	179	110
180	180	101
181	181	24
182	182	23
183	183	146
184	184	58
185	185	163
186	186	44
187	187	177
188	188	22
189	189	10
190	190	38
191	191	227
192	192	132
193	193	64
194	194	120
195	195	83
196	196	225
197	197	227
198	198	87
199	199	165
200	200	149
201	201	88
202	202	166
203	203	195
204	204	77
205	205	194
206	206	177
207	207	170
208	208	203
209	209	12
210	210	223
211	211	107
212	212	224
213	213	78
214	214	126
215	215	26
216	216	144
217	217	12
218	218	152
219	219	199
220	220	16
221	221	142
222	222	95
223	223	166
224	224	112
225	225	186
226	226	170
227	227	34
228	228	149
229	229	151
230	230	27
231	231	115
232	232	141
233	233	32
234	234	163
235	235	145
236	236	35
237	237	146
238	238	121
239	239	33
240	240	102
241	241	105
242	242	229
243	243	133
244	244	83
245	245	220
246	246	211
247	247	34
248	248	142
249	249	202
250	250	221
251	251	202
252	252	74
253	253	83
254	254	181
255	255	160
256	256	101
257	257	59
258	258	77
259	259	204
260	260	199
261	261	91
262	262	199
263	263	106
264	264	175
265	265	14
266	266	54
267	267	52
268	268	67
269	269	16
270	270	217
271	271	50
272	272	48
273	273	217
274	274	75
275	275	97
276	276	97
277	277	154
278	278	225
279	279	202
280	280	112
281	281	210
282	282	55
283	283	70
284	284	14
285	285	208
286	286	139
287	287	78
288	288	196
289	289	10
290	290	170
291	291	37
292	292	207
293	293	158
294	294	69
295	295	178
296	296	192
297	297	116
298	298	108
299	299	54
300	300	195
301	301	79
302	302	199
303	303	126
304	304	39
305	305	74
306	306	14
307	307	161
308	308	59
309	309	86
310	310	186
311	311	142
312	312	82
313	313	217
314	314	64
315	315	220
316	316	55
317	317	57
318	318	200
319	319	113
320	320	43
321	321	206
322	322	152
323	323	45
324	324	145
325	325	163
326	326	125
327	327	190
328	328	187
329	329	225
330	330	105
331	331	139
332	332	70
333	333	125
334	334	162
335	335	22
336	336	98
337	337	229
338	338	124
339	339	30
340	340	70
341	341	160
342	342	62
343	343	23
344	344	38
345	345	142
346	346	186
347	347	200
348	348	21
349	349	147
350	350	146
351	351	190
352	352	16
353	353	129
354	354	36
355	355	224
356	356	117
357	357	83
358	358	149
359	359	213
360	360	37
361	361	197
362	362	187
363	363	87
364	364	151
365	365	135
366	366	193
367	367	152
368	368	93
369	369	97
370	370	30
371	371	168
372	372	162
373	373	49
374	374	218
375	375	226
376	376	62
377	377	230
378	378	65
379	379	167
380	380	159
381	381	103
382	382	74
383	383	100
384	384	25
385	385	15
386	386	140
387	387	15
388	388	152
389	389	49
390	390	57
391	391	85
392	392	48
393	393	163
394	394	37
395	395	142
396	396	132
397	397	172
398	398	197
399	399	173
400	400	181
401	401	10
402	402	38
403	403	175
404	404	203
405	405	12
406	406	18
407	407	107
408	408	201
409	409	60
410	410	203
411	411	64
412	412	125
413	413	49
414	414	38
415	415	81
416	416	126
417	417	37
418	418	141
419	419	169
420	420	208
421	421	227
422	422	204
423	423	229
424	424	228
425	425	121
426	426	146
427	427	97
428	428	55
429	429	159
430	430	101
431	431	27
432	432	169
433	433	44
434	434	15
435	435	195
436	436	37
437	437	105
438	438	24
439	439	133
440	440	90
441	441	88
442	442	158
443	443	22
444	444	156
445	445	205
446	446	150
447	447	127
448	448	132
449	449	186
450	450	192
451	451	46
452	452	173
453	453	77
454	454	189
455	455	104
456	456	47
457	457	121
458	458	218
459	459	40
460	460	227
461	461	54
462	462	112
463	463	122
464	464	209
465	465	93
466	466	146
467	467	68
468	468	97
469	469	41
470	470	132
471	471	64
472	472	80
473	473	18
474	474	186
475	475	118
476	476	44
477	477	24
478	478	179
479	479	66
480	480	121
481	481	52
482	482	159
483	483	95
484	484	15
485	485	136
486	486	52
487	487	45
488	488	137
489	489	116
490	490	168
491	491	185
492	492	205
493	493	153
494	494	213
495	495	214
496	496	58
497	497	202
498	498	50
499	499	214
500	500	45
501	501	63
502	502	89
503	503	165
504	504	49
505	505	72
506	506	165
507	507	211
508	508	64
509	509	208
510	510	114
511	511	156
512	512	26
513	513	22
514	514	96
515	515	157
516	516	189
517	517	162
518	518	227
519	519	111
520	520	172
521	521	86
522	522	114
523	523	101
524	524	103
525	525	49
526	526	37
527	527	200
528	528	99
529	529	27
530	530	223
531	531	53
532	532	38
533	533	29
534	534	50
535	535	57
536	536	28
537	537	153
538	538	17
539	539	155
540	540	79
541	541	67
542	542	154
543	543	135
544	544	181
545	545	25
546	546	116
547	547	228
548	548	150
549	549	89
550	550	215
551	551	199
552	552	223
553	553	10
554	554	22
555	555	81
556	556	188
557	557	152
558	558	42
559	559	29
560	560	25
561	561	79
562	562	37
563	563	30
564	564	175
565	565	226
566	566	75
567	567	229
568	568	11
569	569	176
570	570	127
571	571	123
572	572	195
573	573	208
574	574	173
575	575	93
576	576	196
577	577	192
578	578	141
579	579	150
580	580	54
581	581	49
582	582	34
583	583	113
584	584	64
585	585	192
586	586	131
587	587	98
588	588	56
589	589	60
590	590	117
591	591	48
592	592	111
593	593	154
594	594	190
595	595	115
596	596	46
597	597	113
598	598	144
599	599	172
600	600	85
601	601	211
602	602	164
603	603	14
604	604	153
605	605	178
606	606	59
607	607	118
608	608	140
609	609	204
610	610	47
611	611	214
612	612	88
613	613	207
614	614	134
615	615	34
616	616	112
617	617	194
618	618	71
619	619	51
620	620	95
621	621	194
622	622	109
623	623	76
624	624	104
625	625	68
626	626	131
627	627	174
628	628	164
629	629	220
630	630	46
631	631	40
632	632	88
633	633	65
634	634	208
635	635	81
636	636	222
637	637	87
638	638	80
639	639	201
640	640	26
641	641	20
642	642	63
643	643	203
644	644	105
645	645	192
646	646	139
647	647	28
648	648	81
649	649	50
650	650	118
651	651	26
652	652	46
653	653	109
654	654	154
655	655	216
656	656	188
657	657	156
658	658	30
659	659	67
660	660	175
661	661	180
662	662	61
663	663	192
664	664	164
665	665	206
666	666	205
667	667	73
668	668	185
669	669	52
670	670	97
671	671	147
672	672	176
673	673	125
674	674	104
675	675	214
676	676	37
677	677	38
678	678	101
679	679	119
680	680	83
681	681	215
682	682	24
683	683	46
684	684	87
685	685	35
686	686	121
687	687	133
688	688	219
689	689	120
690	690	50
691	691	42
692	692	126
693	693	222
694	694	98
695	695	48
696	696	75
697	697	93
698	698	130
699	699	229
700	700	24
701	701	173
702	702	210
703	703	230
704	704	222
705	705	107
706	706	99
707	707	192
708	708	202
709	709	37
710	710	153
711	711	188
712	712	182
713	713	56
714	714	65
715	715	82
716	716	95
717	717	179
718	718	47
719	719	70
720	720	120
721	721	155
722	722	84
723	723	117
724	724	82
725	725	85
726	726	37
727	727	75
728	728	116
729	729	135
730	730	158
731	731	185
732	732	204
733	733	215
734	734	79
735	735	142
736	736	181
737	737	115
738	738	169
739	739	15
740	740	142
741	741	125
742	742	15
743	743	190
744	744	117
745	745	58
746	746	190
747	747	158
748	748	183
749	749	59
750	750	33
751	751	165
752	752	49
753	753	20
754	754	22
755	755	181
756	756	186
757	757	32
758	758	144
759	759	58
760	760	202
761	761	225
762	762	37
763	763	222
764	764	188
765	765	145
766	766	154
767	767	93
768	768	201
769	769	48
770	770	92
771	771	89
772	772	111
773	773	61
774	774	124
775	775	79
776	776	11
777	777	94
778	778	122
779	779	92
780	780	113
781	781	141
782	782	150
783	783	190
784	784	62
785	785	210
786	786	206
787	787	38
788	788	187
789	789	131
790	790	122
791	791	150
792	792	45
793	793	190
794	794	143
795	795	88
796	796	81
797	797	86
798	798	143
799	799	26
800	800	158
801	801	98
802	802	131
803	803	96
804	804	150
805	805	107
806	806	24
807	807	44
808	808	44
809	809	165
810	810	42
811	811	160
812	812	222
813	813	155
814	814	45
815	815	84
816	816	156
817	817	10
818	818	228
819	819	214
820	820	184
821	821	54
822	822	195
823	823	148
824	824	190
825	825	148
826	826	111
827	827	82
828	828	226
829	829	43
830	830	73
831	831	95
832	832	61
833	833	199
834	834	85
835	835	39
836	836	221
837	837	54
838	838	84
839	839	146
840	840	44
841	841	42
842	842	173
843	843	224
844	844	182
845	845	41
846	846	109
847	847	192
848	848	73
849	849	149
850	850	49
851	851	115
852	852	101
853	853	212
854	854	19
855	855	177
856	856	68
857	857	53
858	858	20
859	859	143
860	860	97
861	861	115
862	862	110
863	863	206
864	864	121
865	865	166
866	866	188
867	867	225
868	868	45
869	869	131
870	870	201
871	871	216
872	872	219
873	873	23
874	874	53
875	875	181
876	876	161
877	877	117
878	878	182
879	879	163
880	880	105
881	881	134
882	882	147
883	883	18
884	884	119
885	885	66
886	886	46
887	887	184
888	888	38
889	889	108
890	890	124
891	891	54
892	892	214
893	893	99
894	894	26
895	895	16
896	896	27
897	897	224
898	898	157
899	899	91
900	900	73
901	901	216
902	902	117
903	903	226
904	904	41
905	905	213
906	906	70
907	907	15
908	908	132
909	909	224
910	910	77
911	911	84
912	912	187
913	913	63
914	914	33
915	915	33
916	916	74
917	917	174
918	918	210
919	919	193
920	920	49
921	921	140
922	922	173
923	923	138
924	924	28
925	925	107
926	926	11
927	927	42
928	928	78
929	929	88
930	930	184
931	931	69
932	932	61
933	933	230
934	934	120
935	935	60
936	936	179
937	937	200
938	938	82
939	939	216
940	940	53
941	941	153
942	942	11
943	943	78
944	944	10
945	945	21
946	946	16
947	947	57
948	948	152
949	949	44
950	950	113
951	951	77
952	952	189
953	953	210
954	954	100
955	955	24
956	956	181
957	957	135
958	958	13
959	959	150
960	960	40
961	961	177
962	962	74
963	963	212
964	964	179
965	965	184
966	966	76
967	967	77
968	968	19
969	969	91
970	970	74
971	971	37
972	972	163
973	973	222
974	974	49
975	975	79
976	976	47
977	977	186
978	978	212
979	979	199
980	980	50
981	981	33
982	982	200
983	983	128
984	984	18
985	985	192
986	986	48
987	987	52
988	988	87
989	989	206
990	990	154
991	991	181
992	992	74
993	993	97
994	994	170
995	995	12
996	996	76
997	997	97
998	998	71
999	999	130
1000	1000	32
\.


--
-- TOC entry 3169 (class 0 OID 16463)
-- Dependencies: 207
-- Data for Name: manufacturer_firm; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.manufacturer_firm (id, name, address) FROM stdin;
1	РосМедПрод	Тверь, Россия
2	GerMedProd	Берлин, Германия
3	ChinaMedicine	Пекин, Китай
4	USABestMedicine	Техас, США
5	AntiIllnes	Афины, Греция
6	GRUMD	Париж, Франция
7	Panacea	Рим, Италия
8	AntiViruses	Ванкувер, Канада
9	QuartusMedicine	Волгоград, Россия
10	HealthResearch	Портленд, США
\.


--
-- TOC entry 3175 (class 0 OID 16487)
-- Dependencies: 213
-- Data for Name: medicine; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.medicine (id, price, name, expiration_date, series, date_quarantine_zone, return_distruction_date, gross_weight, id_medicine_form, id_manufacturer_firm, id_storage_method, id_pharmacological_group) FROM stdin;
2	100,00 ?	Анальгин	2022-01-01	ER231	\N	\N	31	1	2	3	2
3	90,00 ?	Пенецилин	2022-02-23	TS129	2021-01-21	2021-01-29	50	2	3	2	3
4	320,00 ?	Каптоприл	2024-06-04	MY632	2021-02-13	\N	130	2	3	1	1
6	210,00 ?	Милдронат	2026-03-15	GA813	\N	\N	50	3	6	3	7
7	140,00 ?	Кодеин	2022-01-01	GW725	2021-03-31	\N	40	2	7	1	12
8	100,00 ?	Ламизин	2023-04-21	FQ048	\N	\N	15	3	1	3	10
9	600,00 ?	Гептрал	2022-06-25	JQ941	\N	\N	40	3	9	2	8
11	150,00 ?	Рыбий жир	2023-11-23	JQ413	\N	\N	70	3	4	1	3
10	40,00 ?	Ибупрофен	2024-07-13	LP614	2021-06-13	2021-06-15	25	3	10	2	11
5	810,00 ?	Импликор	2022-02-12	FA416	\N	\N	34	3	5	2	1
12	300,00 ?	Имудон	2023-04-13	NA194	2021-04-28	\N	20	3	5	1	1
13	147,00 ?	est	2020-09-04	JD812	2020-11-29	\N	52	4	7	4	3
14	180,00 ?	nulla	2020-08-05	JD812	\N	\N	86	5	5	1	7
15	453,00 ?	in	2021-05-02	JD812	2020-10-17	\N	93	2	6	4	8
16	843,00 ?	convallis morbi	2020-09-18	JD812	2021-03-29	\N	47	3	10	1	9
17	570,00 ?	lacinia erat	2020-09-08	JD812	2021-05-03	\N	79	6	4	4	9
18	97,00 ?	proin leo	2020-08-22	JD812	2020-05-25	\N	36	3	4	4	12
19	222,00 ?	tristique	2020-06-13	JD812	2020-06-11	\N	12	2	4	4	6
20	907,00 ?	commodo placerat	2020-12-16	JD812	2020-10-06	2021-06-08	39	5	2	4	2
21	81,00 ?	nunc vestibulum	2021-04-27	JD812	2020-10-21	\N	91	2	5	4	2
22	316,00 ?	purus	2021-03-13	JD812	2021-01-23	\N	23	2	5	3	3
23	372,00 ?	eu	2020-12-06	JD812	\N	\N	15	1	1	2	12
24	545,00 ?	dui nec	2021-04-28	JD812	2020-11-05	\N	40	6	7	3	11
25	335,00 ?	luctus	2020-08-19	JD812	\N	\N	50	3	10	3	1
26	232,00 ?	id	2021-04-12	JD812	2020-08-16	2021-11-28	27	4	7	1	5
27	402,00 ?	vestibulum proin	2021-04-20	JD812	\N	\N	37	6	7	3	3
28	732,00 ?	quam	2020-06-29	JD812	2020-09-17	\N	80	1	5	2	12
29	193,00 ?	fermentum	2021-04-01	JD812	2021-01-30	\N	87	5	6	3	3
30	645,00 ?	magnis	2020-10-19	JD812	\N	\N	50	3	5	2	7
31	901,00 ?	aliquet	2020-10-09	JD812	\N	\N	30	7	5	1	10
32	274,00 ?	nam	2021-04-28	JD812	2021-05-01	\N	61	5	7	1	5
33	229,00 ?	id	2021-04-02	JD812	\N	\N	70	5	9	1	12
34	401,00 ?	in	2020-06-10	JD812	2021-01-13	\N	32	7	4	1	6
35	338,00 ?	congue	2020-11-13	JD812	\N	2021-08-19	8	5	9	1	12
1	20,00 ?	Аспирин	2023-01-01	HA581	2021-05-25	2021-05-27	26	3	1	2	11
36	883,00 ?	mauris	2021-04-05	JD812	\N	2021-09-08	10	7	6	3	5
37	69,00 ?	lectus	2021-05-11	JD812	\N	\N	30	2	5	3	8
38	56,00 ?	eget	2021-02-12	JD812	2020-09-29	\N	91	2	8	4	9
39	165,00 ?	potenti cras	2020-05-24	JD812	\N	\N	13	6	9	4	2
40	864,00 ?	adipiscing	2021-03-10	JD812	\N	\N	83	2	2	2	2
41	937,00 ?	volutpat	2021-04-12	JD812	2021-03-01	2021-07-10	39	6	7	4	4
42	263,00 ?	risus	2020-06-20	JD812	2020-08-27	\N	69	6	7	3	2
43	700,00 ?	phasellus in	2020-08-22	JD812	\N	\N	91	3	6	4	10
44	355,00 ?	pretium iaculis	2020-07-06	JD812	\N	\N	69	5	1	1	12
45	189,00 ?	quam	2020-07-14	JD812	2021-04-02	2021-10-28	94	7	2	1	3
46	189,00 ?	dapibus dolor	2021-03-29	JD812	2020-12-25	\N	29	3	2	1	7
47	801,00 ?	vel augue	2021-04-24	JD812	2020-08-09	\N	43	7	8	4	9
48	902,00 ?	platea	2020-11-21	JD812	2020-10-28	2021-10-11	9	4	1	3	6
49	992,00 ?	non	2020-06-19	JD812	2020-11-21	2021-06-30	15	5	10	1	1
50	541,00 ?	sit amet	2020-05-30	JD812	2020-12-01	2021-09-22	81	1	8	2	2
51	92,00 ?	sem mauris	2020-11-15	JD812	2021-04-16	\N	6	6	8	4	6
52	965,00 ?	id	2020-06-24	JD812	2021-01-18	\N	65	7	4	4	10
53	242,00 ?	interdum	2020-07-24	JD812	\N	\N	63	6	3	4	2
54	84,00 ?	justo pellentesque	2020-09-28	JD812	2020-07-28	2021-09-18	99	6	3	1	2
55	968,00 ?	curabitur	2020-12-22	JD812	\N	\N	31	4	2	2	8
56	993,00 ?	leo maecenas	2020-11-19	JD812	2021-03-27	2021-06-25	56	3	5	2	12
57	460,00 ?	est	2020-12-20	JD812	2021-03-07	\N	29	3	9	1	6
58	839,00 ?	porta volutpat	2020-07-03	JD812	\N	\N	82	2	1	3	7
59	328,00 ?	blandit non	2021-04-09	JD812	2020-06-16	\N	64	4	6	4	3
60	254,00 ?	elit proin	2020-07-10	JD812	\N	2021-06-26	21	3	3	2	1
61	481,00 ?	dictumst morbi	2020-05-31	JD812	2021-01-08	\N	26	4	1	4	3
62	154,00 ?	in imperdiet	2020-06-24	JD812	2020-11-10	2021-07-14	13	2	10	2	6
63	588,00 ?	leo maecenas	2021-01-31	JD812	2020-09-28	\N	62	3	10	1	2
64	769,00 ?	sagittis nam	2020-09-15	JD812	2020-07-10	2021-06-29	71	1	10	2	5
65	463,00 ?	viverra	2021-05-03	JD812	\N	2021-12-09	41	7	2	2	3
66	681,00 ?	turpis integer	2021-04-09	JD812	2021-03-02	\N	22	3	5	4	9
67	662,00 ?	aliquam erat	2021-05-18	JD812	\N	2021-06-23	7	4	10	3	5
68	55,00 ?	duis bibendum	2020-07-10	JD812	\N	\N	98	1	3	4	12
69	414,00 ?	nam	2020-06-21	JD812	2021-04-21	2021-10-13	76	1	1	3	10
70	721,00 ?	erat	2021-04-02	JD812	2020-07-04	2021-06-29	11	5	5	3	8
71	910,00 ?	turpis	2020-08-20	JD812	2020-07-01	\N	76	1	10	3	12
72	313,00 ?	parturient	2021-01-01	JD812	\N	2021-12-16	53	4	8	2	10
73	451,00 ?	ut massa	2021-01-27	JD812	\N	\N	69	7	5	1	2
74	825,00 ?	lorem	2021-01-02	JD812	\N	\N	74	6	1	4	1
75	638,00 ?	potenti nullam	2020-09-27	JD812	\N	\N	62	3	2	1	6
76	712,00 ?	sed	2021-03-08	JD812	2020-12-05	\N	94	5	3	3	3
77	487,00 ?	ornare imperdiet	2020-10-24	JD812	2021-03-10	2021-06-01	43	5	9	2	3
78	485,00 ?	et	2021-01-09	JD812	2020-09-13	\N	56	4	3	1	1
79	380,00 ?	in faucibus	2021-01-26	JD812	2020-11-03	\N	78	3	5	2	4
80	610,00 ?	pede	2020-07-20	JD812	\N	2021-11-22	83	5	9	4	9
81	892,00 ?	vestibulum	2021-03-15	JD812	\N	\N	73	7	10	4	5
82	772,00 ?	blandit	2021-01-29	JD812	2021-02-07	\N	61	6	2	1	3
83	592,00 ?	sem	2021-03-02	JD812	2020-11-08	\N	49	5	4	1	1
84	227,00 ?	dictumst aliquam	2021-04-05	JD812	2021-05-14	\N	68	1	2	2	9
85	89,00 ?	sollicitudin mi	2021-04-19	JD812	2020-11-15	2021-06-30	84	3	9	4	7
86	472,00 ?	in felis	2020-09-16	JD812	2021-05-03	\N	93	2	7	4	1
87	450,00 ?	sagittis nam	2020-10-12	JD812	2020-09-02	\N	50	6	9	2	8
88	452,00 ?	vivamus metus	2021-05-12	JD812	2020-12-31	\N	97	4	4	4	10
89	865,00 ?	nulla	2020-11-12	JD812	2020-09-05	\N	82	5	7	3	3
90	800,00 ?	vestibulum sagittis	2020-10-04	JD812	2020-11-12	\N	60	1	4	4	6
91	841,00 ?	faucibus	2020-08-04	JD812	\N	\N	43	7	4	2	8
92	189,00 ?	vel sem	2021-02-19	JD812	2020-10-28	\N	75	2	6	4	2
93	550,00 ?	donec diam	2020-07-05	JD812	2020-06-26	\N	26	6	7	1	9
94	515,00 ?	amet	2020-09-06	JD812	2021-02-01	\N	19	7	8	3	1
95	172,00 ?	orci	2021-03-17	JD812	2021-04-07	\N	67	5	5	1	4
96	943,00 ?	at	2020-06-02	JD812	2020-10-17	\N	74	1	1	3	5
97	931,00 ?	nisi	2021-01-26	JD812	2021-02-13	2021-07-01	76	1	9	2	3
98	374,00 ?	bibendum	2021-03-29	JD812	\N	2021-11-27	59	2	6	3	1
99	402,00 ?	risus praesent	2020-06-02	JD812	2020-08-04	\N	81	2	1	2	10
100	255,00 ?	non pretium	2020-06-01	JD812	\N	\N	92	2	1	1	8
101	476,00 ?	vestibulum ante	2021-02-12	JD812	2021-04-01	\N	95	6	4	1	12
102	764,00 ?	turpis donec	2020-09-12	JD812	\N	\N	16	2	5	1	8
103	170,00 ?	convallis morbi	2020-07-01	JD812	2020-12-31	\N	33	6	1	2	9
104	444,00 ?	nibh in	2021-03-30	JD812	\N	\N	29	1	7	2	12
105	774,00 ?	venenatis turpis	2021-02-08	JD812	\N	\N	64	6	3	4	2
106	930,00 ?	tempor convallis	2021-03-03	JD812	2020-05-27	\N	74	4	9	1	8
107	192,00 ?	cras	2021-03-20	JD812	\N	\N	10	1	2	3	10
108	525,00 ?	quis	2021-04-17	JD812	2020-07-14	2021-10-15	38	6	3	3	12
109	796,00 ?	felis	2021-02-11	JD812	2021-03-21	2021-08-30	93	3	3	3	2
110	413,00 ?	ultrices	2020-06-30	JD812	\N	\N	91	6	4	4	12
111	586,00 ?	ipsum primis	2020-12-18	JD812	2020-11-27	\N	25	4	10	3	8
112	973,00 ?	felis	2021-04-12	JD812	2020-11-28	\N	18	2	5	1	10
113	942,00 ?	morbi vestibulum	2020-12-22	JD812	2020-07-25	2021-10-17	83	4	1	3	11
114	988,00 ?	eget congue	2021-04-24	JD812	2020-12-24	2021-11-09	25	2	9	3	4
115	722,00 ?	rutrum at	2020-08-31	JD812	2020-06-23	2021-09-15	47	4	3	3	2
116	727,00 ?	in quam	2021-03-15	JD812	\N	\N	61	5	3	4	2
117	364,00 ?	consequat dui	2020-10-16	JD812	2020-10-12	2021-06-16	100	3	1	3	11
118	877,00 ?	amet	2020-09-23	JD812	2020-08-14	\N	95	2	10	2	1
119	302,00 ?	suspendisse accumsan	2020-06-26	JD812	2020-06-18	\N	38	5	8	4	12
120	137,00 ?	duis	2021-01-17	JD812	2020-09-26	\N	90	5	9	2	7
121	178,00 ?	accumsan tortor	2021-05-09	JD812	2020-06-25	\N	6	1	5	3	12
122	815,00 ?	in	2020-07-29	JD812	2021-05-01	\N	20	4	2	4	6
123	163,00 ?	elementum eu	2020-09-14	JD812	2020-09-28	2021-11-20	78	3	3	4	9
124	333,00 ?	semper porta	2020-07-30	JD812	\N	\N	9	4	1	2	3
125	590,00 ?	nam	2021-03-11	JD812	2020-10-21	\N	46	3	4	1	2
126	807,00 ?	cubilia	2020-11-22	JD812	\N	\N	50	6	5	3	12
127	898,00 ?	gravida	2020-08-11	JD812	\N	2021-11-09	52	5	8	1	7
128	847,00 ?	magna	2020-08-23	JD812	\N	\N	92	6	9	1	10
129	606,00 ?	leo	2020-11-30	JD812	\N	\N	60	1	2	4	3
130	283,00 ?	non	2021-04-24	JD812	2020-07-01	2021-08-21	23	6	9	1	10
131	586,00 ?	nunc	2020-11-18	JD812	2020-10-14	\N	80	2	6	1	4
132	786,00 ?	proin	2020-10-21	JD812	2021-05-14	\N	70	1	9	3	9
133	112,00 ?	morbi	2020-05-26	JD812	2021-04-10	2021-09-26	42	6	10	3	7
134	857,00 ?	nulla	2021-04-27	JD812	2020-12-22	\N	67	2	1	3	2
135	964,00 ?	blandit	2020-11-03	JD812	2020-10-27	\N	66	2	4	2	4
136	966,00 ?	nulla justo	2020-12-05	JD812	2020-09-18	\N	17	5	7	2	11
137	711,00 ?	blandit	2020-06-05	JD812	\N	\N	6	7	6	2	8
138	315,00 ?	curae	2020-10-01	JD812	2021-02-28	\N	41	4	6	2	10
139	745,00 ?	vel accumsan	2021-03-01	JD812	\N	\N	7	3	3	3	11
140	621,00 ?	id	2020-06-09	JD812	\N	\N	12	1	7	2	10
141	982,00 ?	tempus	2021-04-01	JD812	2020-06-16	\N	89	5	8	1	11
142	932,00 ?	aenean	2020-07-07	JD812	2021-03-29	\N	10	4	7	2	3
143	129,00 ?	sem praesent	2021-05-10	JD812	\N	2021-08-29	56	2	4	2	11
144	724,00 ?	lacus	2020-07-28	JD812	2020-12-22	\N	64	6	6	1	6
145	155,00 ?	dictumst	2020-08-11	JD812	\N	\N	80	4	7	4	2
146	350,00 ?	eget massa	2020-09-18	JD812	2021-04-11	2021-12-12	33	7	6	4	5
147	881,00 ?	elit	2021-03-30	JD812	2020-10-16	\N	92	7	7	1	4
148	91,00 ?	eros suspendisse	2021-02-25	JD812	2020-10-29	\N	91	7	2	4	7
149	166,00 ?	platea dictumst	2021-04-01	JD812	2020-10-14	\N	69	7	3	4	4
150	69,00 ?	ipsum	2020-07-23	JD812	2020-07-13	2021-10-17	62	1	6	4	11
151	811,00 ?	ante	2020-08-26	JD812	\N	2021-07-20	57	4	8	3	11
152	949,00 ?	massa quis	2021-05-19	JD812	2020-08-25	2021-07-24	61	2	8	3	1
153	891,00 ?	elementum	2021-01-30	JD812	\N	\N	86	2	5	2	11
154	855,00 ?	a	2020-11-30	JD812	2021-02-26	2021-09-27	27	7	10	4	3
155	519,00 ?	justo in	2021-04-16	JD812	2021-01-20	\N	75	3	8	2	2
156	691,00 ?	sapien	2021-02-12	JD812	\N	\N	55	6	1	3	12
157	920,00 ?	consectetuer adipiscing	2021-05-23	JD812	\N	\N	69	2	5	2	1
158	962,00 ?	dictumst	2020-06-05	JD812	2020-06-27	\N	91	5	2	3	11
159	796,00 ?	cursus vestibulum	2021-04-07	JD812	\N	2021-07-24	89	1	8	4	4
160	730,00 ?	id luctus	2021-05-17	JD812	2021-05-22	\N	23	1	2	4	2
161	215,00 ?	integer non	2020-07-05	JD812	\N	\N	26	1	10	1	5
162	476,00 ?	vestibulum ante	2020-09-30	JD812	\N	\N	9	4	8	1	11
163	557,00 ?	non	2020-10-01	JD812	2021-02-23	\N	55	3	9	3	2
164	681,00 ?	velit	2020-11-04	JD812	2021-03-24	2021-06-20	66	6	7	4	11
165	464,00 ?	et	2020-07-23	JD812	2021-05-02	\N	87	2	4	2	4
166	837,00 ?	diam erat	2020-11-14	JD812	\N	\N	21	4	2	1	4
167	967,00 ?	ut	2020-07-12	JD812	\N	2021-12-06	97	5	4	2	6
168	126,00 ?	nulla sed	2020-08-31	JD812	\N	2021-10-29	72	3	9	3	2
169	277,00 ?	turpis	2021-01-30	JD812	\N	2021-12-12	32	2	8	4	10
170	451,00 ?	amet	2020-11-26	JD812	\N	\N	51	5	7	1	1
171	778,00 ?	felis	2021-01-03	JD812	2021-05-18	\N	87	7	6	3	3
172	115,00 ?	cubilia curae	2020-12-21	JD812	\N	\N	70	6	8	1	10
173	378,00 ?	nisi	2020-11-03	JD812	2021-02-15	2021-10-18	88	1	1	2	2
174	905,00 ?	primis	2021-03-12	JD812	\N	\N	24	3	1	4	3
175	957,00 ?	sapien	2021-05-22	JD812	2020-11-06	\N	73	4	8	2	6
176	491,00 ?	primis	2021-04-04	JD812	\N	\N	47	1	10	1	8
177	146,00 ?	vitae ipsum	2020-12-21	JD812	2020-06-21	\N	6	1	5	3	11
178	63,00 ?	eros viverra	2020-10-06	JD812	2020-09-16	\N	57	5	1	2	2
179	739,00 ?	non	2020-06-24	JD812	\N	\N	57	5	7	3	10
180	260,00 ?	eget	2021-04-07	JD812	2020-10-20	2021-10-31	11	3	6	4	6
181	581,00 ?	quis orci	2021-03-05	JD812	\N	2021-10-13	23	2	6	1	1
182	217,00 ?	purus	2020-08-04	JD812	2021-03-30	\N	42	5	1	2	6
183	695,00 ?	sed	2021-05-05	JD812	2020-10-21	\N	47	2	6	4	1
184	298,00 ?	eu nibh	2020-10-04	JD812	2020-08-25	\N	50	1	7	2	9
185	169,00 ?	parturient	2021-03-20	JD812	\N	\N	15	1	4	3	10
186	533,00 ?	nulla	2020-07-03	JD812	2021-05-17	\N	74	4	2	2	3
187	914,00 ?	lectus	2021-02-15	JD812	\N	\N	31	5	6	3	10
188	563,00 ?	pellentesque	2021-03-16	JD812	\N	2021-08-13	98	1	1	4	7
189	550,00 ?	nec dui	2021-01-03	JD812	2020-10-12	2021-07-23	15	3	7	3	1
190	65,00 ?	consequat ut	2021-05-03	JD812	2021-04-17	\N	34	6	1	1	6
191	422,00 ?	ante	2020-06-03	JD812	2021-05-15	\N	10	2	9	3	5
192	812,00 ?	nibh	2020-08-18	JD812	2020-08-20	2021-05-27	99	7	5	3	11
193	485,00 ?	et	2020-08-28	JD812	2020-05-29	\N	45	2	8	4	3
194	213,00 ?	rutrum ac	2021-03-03	JD812	2020-10-06	\N	83	6	4	1	1
195	845,00 ?	nisi	2021-03-05	JD812	2021-01-12	2021-07-17	14	2	5	3	10
196	678,00 ?	varius ut	2021-03-12	JD812	\N	2021-10-03	19	5	9	4	7
197	280,00 ?	odio elementum	2020-06-17	JD812	\N	\N	7	4	5	2	6
198	571,00 ?	amet eros	2021-01-15	JD812	2021-03-04	2021-12-08	28	4	8	3	4
199	624,00 ?	ac consequat	2020-11-10	JD812	2021-02-19	\N	15	5	3	4	3
200	228,00 ?	est	2020-09-27	JD812	\N	\N	69	1	5	4	1
201	854,00 ?	pretium	2020-06-01	JD812	\N	\N	29	1	10	4	5
202	355,00 ?	odio	2020-10-30	JD812	2021-01-20	2021-11-18	18	3	1	2	8
203	996,00 ?	suspendisse	2020-07-06	JD812	\N	\N	74	2	4	4	10
204	98,00 ?	aliquam lacus	2020-08-26	JD812	2021-02-28	2021-06-23	97	1	5	4	4
205	628,00 ?	morbi	2021-03-08	JD812	2020-06-13	2021-08-12	85	5	5	1	2
206	813,00 ?	imperdiet sapien	2020-07-06	JD812	\N	\N	90	4	9	3	11
207	492,00 ?	faucibus cursus	2021-02-11	JD812	\N	2021-07-15	63	4	9	3	1
208	973,00 ?	erat vestibulum	2020-07-11	JD812	2020-10-12	\N	25	4	6	2	5
209	60,00 ?	metus	2021-05-09	JD812	2020-11-30	2021-06-11	52	3	2	1	8
210	835,00 ?	in lectus	2020-07-25	JD812	2021-02-16	\N	41	5	4	4	5
211	378,00 ?	eu	2021-02-28	JD812	2021-01-01	2021-10-03	6	5	2	3	2
212	159,00 ?	nulla	2020-11-21	JD812	2020-08-14	\N	95	7	7	2	10
213	809,00 ?	ut	2020-07-15	JD812	2021-03-07	\N	67	7	6	4	8
214	988,00 ?	libero	2020-07-03	JD812	2020-11-26	2021-11-27	17	5	9	1	7
215	360,00 ?	pulvinar	2020-12-15	JD812	2020-05-25	\N	63	6	2	1	2
216	131,00 ?	lobortis est	2021-01-03	JD812	2021-05-14	\N	46	5	7	4	12
217	839,00 ?	felis	2020-05-31	JD812	2021-03-14	2021-07-31	70	2	2	3	6
218	639,00 ?	quisque	2020-10-25	JD812	2020-10-13	\N	88	2	3	1	12
219	791,00 ?	at	2020-11-11	JD812	2020-07-27	\N	76	4	4	3	7
220	542,00 ?	pellentesque at	2020-06-19	JD812	2020-07-23	2021-12-12	66	7	8	4	5
221	869,00 ?	et	2020-11-06	JD812	2021-02-14	2021-11-27	7	6	2	1	6
222	147,00 ?	dapibus at	2021-05-06	JD812	2021-03-21	\N	32	7	3	3	7
223	270,00 ?	dui	2021-03-06	JD812	\N	\N	63	2	10	1	3
224	310,00 ?	mauris	2021-01-06	JD812	2020-11-10	\N	28	6	7	3	12
225	496,00 ?	sit amet	2020-09-02	JD812	2021-04-18	\N	69	2	3	1	3
226	987,00 ?	nam ultrices	2020-06-08	JD812	2021-03-25	2021-12-18	60	2	2	1	9
227	978,00 ?	sem mauris	2020-08-28	JD812	\N	\N	57	6	5	3	10
228	270,00 ?	pede	2020-11-08	JD812	2021-05-04	\N	52	2	1	4	6
229	940,00 ?	elementum	2021-01-07	JD812	2021-01-28	\N	7	4	6	4	7
230	493,00 ?	ornare consequat	2020-07-20	JD812	\N	2021-06-20	83	1	7	2	1
231	792,00 ?	justo aliquam	2020-06-19	JD812	\N	2021-07-14	95	6	8	2	1
232	859,00 ?	purus sit	2020-07-17	JD812	\N	\N	13	2	10	3	12
233	97,00 ?	consectetuer adipiscing	2020-10-10	JD812	2020-12-04	\N	82	2	5	1	3
234	519,00 ?	pulvinar nulla	2021-03-05	JD812	\N	\N	6	2	2	3	6
235	160,00 ?	sed	2020-08-18	JD812	\N	\N	44	3	2	2	5
236	867,00 ?	eu interdum	2020-09-22	JD812	2020-10-14	\N	44	6	8	2	6
237	399,00 ?	imperdiet	2021-04-22	JD812	\N	\N	95	7	2	1	6
238	145,00 ?	lacus	2021-02-28	JD812	2020-10-08	\N	72	5	10	3	11
239	693,00 ?	donec	2021-03-01	JD812	2020-10-16	\N	69	7	3	2	6
240	445,00 ?	feugiat et	2021-02-01	JD812	2020-11-11	\N	71	3	2	2	1
241	629,00 ?	dolor sit	2020-06-21	JD812	\N	\N	34	4	7	1	4
242	704,00 ?	pharetra magna	2021-01-06	JD812	\N	\N	62	4	10	1	5
243	800,00 ?	in porttitor	2021-05-23	JD812	2020-09-11	2021-09-18	100	6	10	3	12
244	569,00 ?	eu pede	2020-06-19	JD812	\N	2021-08-04	79	7	3	4	5
245	679,00 ?	aliquam non	2021-01-07	JD812	2020-07-11	\N	53	3	10	2	6
246	166,00 ?	urna	2020-11-04	JD812	2021-02-02	2021-07-06	83	3	7	1	11
247	574,00 ?	suspendisse	2020-09-10	JD812	\N	\N	47	7	5	3	8
248	97,00 ?	mi	2020-06-29	JD812	\N	\N	22	7	7	4	8
249	936,00 ?	in faucibus	2021-04-17	JD812	2021-05-06	2021-11-14	55	1	3	4	5
250	945,00 ?	donec odio	2020-08-16	JD812	2020-11-11	\N	54	7	2	4	4
251	523,00 ?	orci mauris	2020-12-03	JD812	2021-03-30	2021-10-05	70	6	9	1	9
252	269,00 ?	ut	2020-10-29	JD812	2020-12-23	\N	49	2	6	3	10
253	426,00 ?	primis in	2020-09-21	JD812	\N	2021-07-04	79	2	2	4	3
254	358,00 ?	ac	2020-12-16	JD812	\N	2021-10-27	35	7	6	3	3
255	170,00 ?	augue	2020-12-30	JD812	2021-04-23	\N	100	3	4	1	10
256	64,00 ?	eros	2020-07-12	JD812	2020-10-27	2021-05-28	39	5	9	1	9
257	389,00 ?	sed tincidunt	2020-08-05	JD812	2020-10-05	\N	42	2	8	1	2
258	206,00 ?	maecenas	2021-05-17	JD812	2020-09-27	\N	77	7	8	2	6
259	645,00 ?	sem	2020-06-26	JD812	\N	2021-10-16	13	6	4	4	6
260	769,00 ?	cras non	2021-04-20	JD812	\N	\N	73	4	5	4	12
261	875,00 ?	orci	2021-04-28	JD812	2021-01-03	\N	51	6	1	4	2
262	972,00 ?	turpis	2020-12-18	JD812	2021-03-12	\N	30	6	1	3	10
263	958,00 ?	erat id	2020-11-20	JD812	2020-07-18	2021-06-03	34	6	3	4	7
264	518,00 ?	tortor quis	2020-09-11	JD812	2020-07-03	\N	60	2	1	2	5
265	528,00 ?	aenean lectus	2021-03-11	JD812	\N	2021-07-12	49	3	6	4	4
266	351,00 ?	fusce	2020-10-01	JD812	\N	\N	37	3	4	2	5
267	887,00 ?	mauris eget	2021-02-19	JD812	\N	\N	69	6	1	1	4
268	299,00 ?	nulla	2021-04-21	JD812	2021-04-28	\N	71	5	2	2	2
269	647,00 ?	diam neque	2021-01-27	JD812	2020-12-06	\N	69	7	6	4	11
270	429,00 ?	massa quis	2021-03-31	JD812	2020-07-23	\N	66	6	10	4	9
271	154,00 ?	amet cursus	2021-03-24	JD812	2021-03-08	\N	72	1	4	1	4
272	456,00 ?	sapien	2020-11-11	JD812	2021-05-06	2021-08-07	50	2	2	3	5
273	121,00 ?	vestibulum eget	2020-05-24	JD812	2020-08-17	\N	8	6	7	4	7
274	563,00 ?	tincidunt lacus	2020-08-26	JD812	2020-08-10	\N	82	2	4	2	12
275	987,00 ?	viverra pede	2020-05-31	JD812	2020-11-09	\N	93	5	6	3	5
276	104,00 ?	suspendisse potenti	2020-09-23	JD812	\N	2021-06-15	36	2	6	4	4
277	733,00 ?	dictumst	2020-10-03	JD812	2021-04-26	\N	62	6	9	3	3
278	923,00 ?	duis	2020-08-21	JD812	2021-03-23	\N	69	4	8	2	2
279	203,00 ?	amet	2021-01-20	JD812	\N	2021-07-27	12	5	5	3	3
280	498,00 ?	pulvinar sed	2021-04-13	JD812	\N	\N	58	2	8	1	10
281	155,00 ?	varius	2020-10-06	JD812	2020-05-24	\N	95	4	5	3	6
282	699,00 ?	ultrices	2020-10-29	JD812	2021-01-01	2021-06-07	80	7	9	4	9
283	230,00 ?	mattis	2020-09-02	JD812	2020-09-09	2021-08-31	100	5	2	1	5
284	544,00 ?	nulla sed	2021-03-06	JD812	\N	\N	31	3	6	2	1
285	558,00 ?	odio	2020-05-26	JD812	\N	\N	91	4	4	2	6
286	665,00 ?	orci luctus	2020-11-20	JD812	\N	2021-08-15	64	1	3	3	6
287	644,00 ?	non mauris	2021-03-04	JD812	\N	\N	66	5	2	3	12
288	921,00 ?	sapien	2020-11-10	JD812	2021-04-02	\N	45	6	8	1	2
289	675,00 ?	ut	2021-02-13	JD812	2020-06-22	2021-11-26	43	3	2	1	12
290	219,00 ?	nulla nunc	2020-12-15	JD812	2021-04-05	\N	44	6	2	2	5
291	186,00 ?	ante vivamus	2020-09-29	JD812	2020-12-28	\N	6	1	9	3	8
292	857,00 ?	interdum	2020-07-25	JD812	2020-05-28	\N	16	7	1	3	3
293	664,00 ?	penatibus et	2021-02-17	JD812	2020-11-12	\N	72	5	8	3	9
294	69,00 ?	quam	2020-11-07	JD812	2021-05-02	\N	17	6	6	4	4
295	660,00 ?	etiam	2020-06-20	JD812	2021-05-05	\N	6	5	5	4	7
296	695,00 ?	libero rutrum	2020-06-25	JD812	\N	\N	70	7	9	4	2
297	333,00 ?	adipiscing molestie	2020-12-23	JD812	2021-03-19	2021-06-10	26	1	4	4	12
298	173,00 ?	nullam	2021-02-27	JD812	\N	\N	40	1	5	1	10
299	721,00 ?	primis in	2020-06-20	JD812	2020-06-04	\N	42	1	4	4	2
300	728,00 ?	vel augue	2021-02-25	JD812	2021-04-06	\N	33	6	4	2	4
301	520,00 ?	vivamus	2021-04-04	JD812	2021-04-27	\N	95	3	3	3	4
302	839,00 ?	justo nec	2021-02-16	JD812	\N	\N	82	4	3	3	6
303	327,00 ?	dolor sit	2021-04-09	JD812	\N	\N	87	1	4	1	1
304	892,00 ?	montes nascetur	2020-09-09	JD812	2021-04-03	\N	62	1	10	2	1
305	595,00 ?	quam	2020-12-20	JD812	2020-09-15	2021-10-24	12	3	8	4	7
306	643,00 ?	faucibus	2021-03-27	JD812	\N	\N	12	4	7	2	7
307	169,00 ?	convallis eget	2021-01-09	JD812	2021-03-08	2021-12-01	68	4	5	2	6
308	917,00 ?	quam sapien	2020-09-15	JD812	\N	\N	31	7	1	4	8
309	938,00 ?	sapien	2021-01-18	JD812	2020-06-11	\N	46	1	10	3	10
310	738,00 ?	aenean sit	2020-10-03	JD812	2020-11-29	2021-08-01	28	2	7	1	5
311	66,00 ?	pellentesque ultrices	2021-05-15	JD812	2020-10-13	\N	52	1	7	4	6
312	264,00 ?	pharetra magna	2021-03-31	JD812	2021-01-29	2021-05-30	44	3	7	4	12
313	859,00 ?	neque	2020-10-30	JD812	2020-10-20	\N	52	1	10	2	5
314	901,00 ?	nam congue	2021-01-20	JD812	\N	2021-05-26	23	5	5	3	9
315	541,00 ?	at dolor	2020-07-26	JD812	2021-04-12	\N	32	4	2	3	6
316	271,00 ?	nec euismod	2020-10-17	JD812	\N	2021-11-05	19	4	7	1	10
317	98,00 ?	accumsan	2021-02-09	JD812	\N	2021-07-07	26	4	5	1	3
318	817,00 ?	duis	2020-10-07	JD812	2020-06-17	\N	58	6	7	1	3
319	230,00 ?	maecenas leo	2021-05-05	JD812	2020-07-10	\N	70	6	8	2	1
320	94,00 ?	quisque	2021-04-14	JD812	\N	\N	86	1	1	4	8
321	995,00 ?	nunc	2020-12-27	JD812	2021-02-23	2021-06-17	12	5	9	4	9
322	314,00 ?	sapien sapien	2020-06-03	JD812	2021-04-05	\N	58	6	5	1	3
323	938,00 ?	duis consequat	2020-11-30	JD812	2020-12-12	\N	13	5	5	3	6
324	321,00 ?	quam	2020-08-24	JD812	2021-05-23	\N	19	1	4	4	9
325	219,00 ?	dui	2021-05-01	JD812	\N	2021-10-06	51	7	8	1	4
326	873,00 ?	pellentesque	2020-09-03	JD812	\N	\N	35	3	10	1	12
327	717,00 ?	augue	2021-05-12	JD812	\N	\N	74	1	6	3	7
328	935,00 ?	non quam	2020-08-27	JD812	2021-04-07	2021-09-02	26	4	7	1	3
329	693,00 ?	id justo	2020-12-03	JD812	\N	\N	59	4	6	4	8
330	817,00 ?	odio	2020-07-28	JD812	\N	2021-10-26	43	2	7	2	6
331	943,00 ?	risus	2021-01-11	JD812	2020-08-22	2021-09-14	83	4	3	2	3
332	85,00 ?	posuere	2020-07-13	JD812	2020-07-05	\N	40	1	8	3	8
333	86,00 ?	consequat dui	2021-03-25	JD812	2020-10-20	\N	7	5	3	4	3
334	110,00 ?	facilisi cras	2021-04-18	JD812	2021-03-28	\N	96	2	5	3	2
335	182,00 ?	bibendum morbi	2021-01-01	JD812	2021-05-12	2021-12-04	17	3	10	4	6
336	130,00 ?	at lorem	2021-04-18	JD812	2020-06-27	\N	82	2	5	2	8
337	713,00 ?	rhoncus dui	2020-07-05	JD812	\N	\N	88	1	7	1	2
338	284,00 ?	at feugiat	2020-08-28	JD812	2020-08-24	\N	64	6	6	4	2
339	864,00 ?	venenatis	2021-02-05	JD812	2020-06-06	\N	78	7	3	4	9
340	128,00 ?	ac	2021-05-07	JD812	2020-07-09	\N	75	7	6	3	5
341	127,00 ?	sed	2020-08-08	JD812	\N	\N	52	5	10	3	1
342	918,00 ?	libero	2020-08-15	JD812	2020-07-10	\N	46	1	4	4	9
343	547,00 ?	pede libero	2020-12-25	JD812	2021-04-01	2021-09-30	63	1	3	4	11
344	931,00 ?	a odio	2020-12-06	JD812	2021-03-18	2021-12-23	45	2	3	4	12
345	873,00 ?	iaculis	2021-04-15	JD812	2020-09-16	\N	59	3	3	1	7
346	223,00 ?	nec molestie	2020-08-11	JD812	2021-01-10	\N	32	4	4	1	9
347	642,00 ?	nisl	2021-02-25	JD812	2020-07-27	\N	55	4	6	2	12
348	478,00 ?	nisl ut	2021-01-23	JD812	\N	2021-06-15	12	2	6	3	6
349	655,00 ?	volutpat quam	2020-06-01	JD812	2021-02-03	\N	21	4	8	4	3
350	599,00 ?	in hac	2021-05-09	JD812	2020-10-24	\N	17	2	1	1	10
351	887,00 ?	diam	2020-12-29	JD812	2021-05-14	2021-07-31	19	4	7	2	5
352	781,00 ?	porttitor	2021-02-02	JD812	\N	2021-08-24	86	6	1	2	3
353	589,00 ?	convallis morbi	2021-03-07	JD812	2021-02-14	\N	81	1	5	2	9
354	984,00 ?	posuere	2021-05-02	JD812	\N	2021-09-03	33	5	7	1	12
355	996,00 ?	luctus cum	2020-08-22	JD812	2020-11-12	\N	59	1	9	3	8
356	927,00 ?	amet nulla	2020-12-09	JD812	2020-09-24	\N	64	1	9	3	5
357	373,00 ?	faucibus	2021-04-21	JD812	\N	\N	76	7	8	1	8
358	307,00 ?	molestie	2020-07-26	JD812	2021-01-26	\N	51	3	5	1	11
359	429,00 ?	dapibus dolor	2020-12-02	JD812	\N	2021-10-06	93	4	9	4	7
360	685,00 ?	facilisi	2021-04-24	JD812	2021-02-22	\N	22	2	5	3	12
361	120,00 ?	nullam varius	2020-06-15	JD812	\N	2021-06-08	62	1	8	2	12
362	764,00 ?	morbi porttitor	2021-01-10	JD812	2020-10-02	\N	12	3	5	3	3
363	511,00 ?	quis turpis	2021-03-26	JD812	2020-07-07	\N	50	6	10	1	11
364	489,00 ?	diam	2020-07-28	JD812	\N	\N	20	7	3	4	2
365	293,00 ?	amet	2020-07-29	JD812	\N	2021-05-29	84	6	3	2	10
366	802,00 ?	in	2020-09-08	JD812	\N	\N	67	2	6	4	3
367	215,00 ?	dui	2021-03-02	JD812	2021-02-01	\N	42	3	2	1	4
368	284,00 ?	elit proin	2021-03-30	JD812	2021-05-09	\N	79	5	7	4	7
369	645,00 ?	sit	2021-01-02	JD812	2020-08-08	2021-06-13	45	5	10	4	12
370	266,00 ?	montes	2021-02-04	JD812	2020-07-12	\N	71	1	4	1	6
371	595,00 ?	lobortis ligula	2020-09-25	JD812	\N	\N	32	5	6	3	1
372	194,00 ?	commodo	2020-07-28	JD812	2021-04-21	\N	35	6	3	4	12
373	764,00 ?	nisi venenatis	2021-01-15	JD812	2021-04-01	2021-09-09	97	2	8	3	4
374	638,00 ?	hac habitasse	2021-04-30	JD812	2020-07-01	\N	34	4	5	4	5
375	983,00 ?	pellentesque	2020-06-11	JD812	\N	2021-07-14	19	3	1	1	9
376	349,00 ?	sapien	2020-08-03	JD812	2021-05-20	2021-11-11	83	1	6	3	5
377	571,00 ?	ligula	2020-12-10	JD812	2021-01-26	\N	67	5	7	3	5
378	938,00 ?	risus dapibus	2020-06-24	JD812	\N	2021-10-24	99	2	10	1	10
379	620,00 ?	turpis nec	2020-07-24	JD812	2021-02-28	\N	17	1	8	3	12
380	645,00 ?	euismod	2021-01-20	JD812	\N	2021-07-10	86	3	9	1	4
381	235,00 ?	nulla	2021-05-19	JD812	2020-12-17	\N	88	4	6	2	11
382	926,00 ?	sed tincidunt	2021-04-09	JD812	\N	\N	82	2	6	2	2
383	382,00 ?	imperdiet sapien	2021-01-10	JD812	\N	2021-09-12	89	4	6	1	10
384	278,00 ?	curabitur in	2020-09-27	JD812	2020-09-24	\N	22	2	8	1	11
385	492,00 ?	hac habitasse	2020-06-27	JD812	\N	\N	31	2	2	4	6
386	482,00 ?	purus phasellus	2021-01-28	JD812	2021-03-26	\N	15	3	2	3	1
387	515,00 ?	dictumst aliquam	2021-05-06	JD812	\N	\N	98	5	4	1	10
388	106,00 ?	id	2021-02-22	JD812	\N	\N	90	5	2	2	3
389	409,00 ?	luctus	2020-07-07	JD812	2020-10-18	\N	53	2	5	1	8
390	404,00 ?	consequat	2020-11-19	JD812	2020-06-17	\N	29	4	4	2	5
391	350,00 ?	massa id	2020-07-05	JD812	2020-09-16	2021-05-28	36	1	9	4	9
392	521,00 ?	donec	2021-01-06	JD812	\N	2021-09-30	15	1	3	1	5
393	490,00 ?	pretium iaculis	2020-05-31	JD812	2020-09-21	\N	38	6	1	2	2
394	868,00 ?	suspendisse	2020-07-25	JD812	2020-08-26	2021-08-20	39	2	2	1	5
395	926,00 ?	lectus	2021-02-17	JD812	2020-09-19	2021-08-08	64	1	3	4	9
396	504,00 ?	sed vestibulum	2020-06-29	JD812	2021-02-28	\N	33	2	5	3	4
397	395,00 ?	risus dapibus	2021-01-02	JD812	2021-02-05	\N	19	5	7	3	7
398	714,00 ?	ante vel	2021-03-22	JD812	2021-05-01	\N	57	5	1	2	6
399	575,00 ?	libero non	2021-01-12	JD812	2021-02-04	2021-08-07	25	2	3	3	9
400	727,00 ?	mauris viverra	2021-04-19	JD812	2020-09-16	2021-10-13	52	6	2	4	11
401	220,00 ?	duis bibendum	2020-05-29	JD812	\N	\N	93	5	3	3	2
402	421,00 ?	turpis	2021-01-26	JD812	2020-08-06	2021-06-06	8	5	3	2	12
403	664,00 ?	justo sollicitudin	2021-01-08	JD812	2020-12-11	2021-11-29	100	5	3	2	6
404	146,00 ?	vitae	2021-01-21	JD812	2020-12-11	\N	10	1	4	4	2
405	190,00 ?	turpis	2020-06-29	JD812	\N	\N	60	2	3	2	11
406	383,00 ?	amet	2021-04-18	JD812	2021-01-10	\N	12	5	6	1	1
407	707,00 ?	augue	2020-09-06	JD812	2020-08-24	\N	16	6	1	1	12
408	260,00 ?	penatibus	2021-02-01	JD812	\N	2021-12-16	16	3	7	1	11
409	113,00 ?	integer	2020-09-24	JD812	2020-09-14	\N	65	1	2	2	9
410	744,00 ?	at	2021-05-19	JD812	\N	\N	29	4	6	3	11
411	390,00 ?	vulputate	2020-10-01	JD812	2020-11-18	\N	40	5	3	4	7
412	566,00 ?	at feugiat	2020-09-13	JD812	\N	\N	50	7	1	3	6
413	288,00 ?	suspendisse	2020-06-04	JD812	2021-03-30	\N	34	7	9	3	5
414	401,00 ?	sapien cursus	2021-04-20	JD812	2021-01-28	2021-05-27	26	1	7	3	7
415	595,00 ?	nulla elit	2020-11-22	JD812	2020-11-18	\N	66	1	2	2	3
416	781,00 ?	interdum eu	2020-10-07	JD812	2020-09-17	2021-06-24	24	2	5	4	4
417	260,00 ?	ac	2020-12-13	JD812	2021-04-12	\N	59	3	6	4	6
418	776,00 ?	eu	2020-07-19	JD812	\N	\N	100	5	5	1	4
419	933,00 ?	sit amet	2020-07-19	JD812	2020-10-02	2021-10-07	95	5	4	4	4
420	88,00 ?	elementum	2020-08-18	JD812	2020-07-21	\N	21	4	8	2	9
421	80,00 ?	vitae	2020-07-12	JD812	2020-08-27	2021-09-19	44	1	10	2	4
422	664,00 ?	at velit	2020-09-29	JD812	\N	\N	31	2	10	2	8
423	475,00 ?	vitae	2020-07-16	JD812	2020-08-20	\N	98	6	2	3	4
424	497,00 ?	vitae nisl	2021-01-08	JD812	2020-11-26	\N	41	7	5	4	7
425	466,00 ?	a	2020-05-24	JD812	2020-08-24	2021-06-07	87	4	10	3	8
426	52,00 ?	eleifend luctus	2020-09-13	JD812	2020-09-22	\N	98	7	7	2	2
427	725,00 ?	vivamus vestibulum	2021-05-05	JD812	2020-10-24	\N	20	4	3	4	6
428	941,00 ?	odio	2020-11-01	JD812	2021-03-28	2021-07-16	95	7	7	2	4
429	823,00 ?	mauris	2020-12-06	JD812	2021-03-26	\N	93	7	3	1	7
430	149,00 ?	curabitur	2020-09-29	JD812	2020-10-14	2021-10-12	67	4	10	3	1
431	944,00 ?	mi	2021-02-28	JD812	2020-08-23	\N	66	1	5	4	12
432	541,00 ?	amet consectetuer	2020-12-07	JD812	2020-10-07	\N	12	6	6	4	3
433	367,00 ?	orci luctus	2020-09-02	JD812	2021-03-22	\N	47	6	4	2	7
434	131,00 ?	nibh in	2021-04-23	JD812	2020-06-23	2021-10-27	23	3	9	1	8
435	613,00 ?	sit	2020-10-25	JD812	2020-10-28	\N	62	7	9	1	8
436	570,00 ?	ipsum integer	2020-12-29	JD812	\N	2021-11-06	32	5	8	4	7
437	922,00 ?	scelerisque mauris	2020-10-27	JD812	2020-10-28	\N	19	6	6	4	11
438	966,00 ?	tellus nulla	2020-09-30	JD812	2021-02-18	2021-11-01	18	6	7	1	2
439	718,00 ?	maecenas leo	2020-10-09	JD812	2020-12-29	2021-09-08	16	4	5	4	11
440	413,00 ?	sapien a	2021-04-30	JD812	\N	\N	97	7	5	3	10
441	405,00 ?	dolor morbi	2020-11-13	JD812	2020-10-21	\N	52	2	8	4	3
442	577,00 ?	et	2020-12-18	JD812	2021-05-08	\N	73	7	1	3	2
443	200,00 ?	tempus sit	2020-08-20	JD812	2020-12-12	\N	44	1	5	1	12
444	75,00 ?	in felis	2021-03-30	JD812	\N	2021-06-18	68	7	2	2	7
445	585,00 ?	dictumst	2021-04-12	JD812	2020-08-29	\N	100	5	5	1	6
446	186,00 ?	scelerisque	2021-01-26	JD812	2020-07-09	\N	40	6	3	4	3
447	544,00 ?	sed interdum	2020-10-03	JD812	\N	\N	76	6	10	3	11
448	67,00 ?	velit nec	2020-07-02	JD812	\N	\N	91	4	3	3	8
449	278,00 ?	gravida	2020-06-09	JD812	2020-12-10	\N	51	5	6	3	1
450	497,00 ?	phasellus	2021-02-03	JD812	\N	\N	51	6	2	3	10
451	307,00 ?	at	2021-02-17	JD812	2020-06-12	2021-10-22	64	1	5	1	4
452	215,00 ?	vel	2020-06-28	JD812	2021-01-09	\N	100	5	6	3	6
453	697,00 ?	dapibus nulla	2020-07-29	JD812	2021-02-28	\N	13	1	5	3	8
454	615,00 ?	lacinia erat	2020-05-26	JD812	2021-03-21	2021-08-31	81	3	9	3	6
455	250,00 ?	praesent	2020-07-06	JD812	2020-07-01	2021-11-02	52	4	1	4	8
456	391,00 ?	lorem vitae	2021-03-18	JD812	2020-11-02	\N	59	1	1	1	1
457	749,00 ?	rutrum nulla	2021-01-06	JD812	2021-05-08	\N	97	2	7	4	6
458	290,00 ?	magna vulputate	2020-12-09	JD812	\N	\N	50	7	3	4	7
459	728,00 ?	libero nullam	2020-08-31	JD812	\N	\N	8	1	2	2	2
460	70,00 ?	elit proin	2020-07-29	JD812	2020-07-09	2021-10-17	96	1	2	3	12
461	580,00 ?	justo maecenas	2020-11-20	JD812	2021-01-11	\N	77	5	6	3	3
462	877,00 ?	aliquam convallis	2020-06-03	JD812	\N	2021-07-16	83	7	1	4	5
463	954,00 ?	feugiat non	2021-04-01	JD812	\N	\N	37	6	10	4	9
464	832,00 ?	dapibus	2020-12-24	JD812	2021-02-19	\N	59	5	1	3	9
465	916,00 ?	dui vel	2020-09-19	JD812	2020-12-20	2021-06-22	64	4	7	4	6
466	130,00 ?	vestibulum sit	2020-12-22	JD812	\N	\N	77	7	8	3	5
467	563,00 ?	ac	2020-06-06	JD812	2021-03-02	\N	90	5	9	3	12
468	143,00 ?	amet	2020-11-23	JD812	2021-01-31	2021-10-25	70	1	7	2	2
469	406,00 ?	fermentum	2020-12-05	JD812	2020-10-13	\N	68	1	4	2	10
470	377,00 ?	consequat	2021-02-14	JD812	\N	\N	69	3	4	4	10
471	973,00 ?	felis sed	2021-03-07	JD812	2020-07-31	2021-12-05	14	3	5	4	6
472	179,00 ?	erat tortor	2020-06-24	JD812	\N	\N	59	7	2	4	2
473	230,00 ?	habitasse platea	2021-02-17	JD812	2020-10-05	\N	92	3	10	4	2
474	344,00 ?	nulla suscipit	2020-07-06	JD812	\N	\N	73	7	5	3	1
475	396,00 ?	morbi vestibulum	2020-06-27	JD812	2021-01-16	\N	76	1	3	3	7
476	191,00 ?	praesent	2020-12-17	JD812	2020-06-09	\N	30	5	3	1	12
477	930,00 ?	mauris ullamcorper	2020-12-05	JD812	2020-09-05	\N	68	7	10	4	4
478	163,00 ?	ipsum	2021-03-10	JD812	2020-07-26	2021-07-30	19	3	5	3	10
479	167,00 ?	ut	2020-12-13	JD812	2021-04-09	\N	25	7	7	2	9
480	97,00 ?	gravida	2020-09-19	JD812	2021-02-08	2021-09-26	10	7	7	4	7
481	948,00 ?	nulla	2020-09-28	JD812	2020-11-08	\N	15	2	6	1	8
482	540,00 ?	primis in	2021-03-08	JD812	\N	\N	37	3	4	1	8
483	261,00 ?	sit	2020-06-10	JD812	\N	\N	58	3	8	1	6
484	124,00 ?	justo	2021-03-21	JD812	2021-03-04	\N	73	5	2	1	1
485	78,00 ?	tempor	2020-07-08	JD812	2020-07-13	2021-08-14	17	4	6	1	7
486	367,00 ?	nisi	2020-11-28	JD812	2020-11-21	2021-09-26	78	4	7	1	5
487	95,00 ?	sodales	2021-01-22	JD812	\N	\N	88	5	1	1	5
488	524,00 ?	cubilia curae	2021-03-12	JD812	2020-09-10	2021-10-31	100	3	1	1	7
489	635,00 ?	ut erat	2020-12-24	JD812	2021-05-09	\N	99	7	2	3	10
490	344,00 ?	nulla	2021-02-08	JD812	\N	\N	67	1	10	2	2
491	272,00 ?	blandit ultrices	2020-07-17	JD812	2021-05-06	\N	16	4	9	4	12
492	960,00 ?	eget orci	2020-11-02	JD812	\N	2021-10-14	31	7	4	2	6
493	99,00 ?	orci luctus	2020-07-21	JD812	2020-11-30	2021-11-27	32	1	9	2	4
494	967,00 ?	sapien quis	2020-06-01	JD812	2020-06-30	2021-11-08	69	2	4	1	12
495	728,00 ?	nunc	2020-10-28	JD812	2020-06-04	2021-09-29	84	4	5	4	4
496	760,00 ?	risus dapibus	2020-10-12	JD812	2021-02-07	\N	20	2	1	1	7
497	82,00 ?	erat	2020-09-12	JD812	2021-01-07	2021-11-24	27	3	6	4	4
498	821,00 ?	vitae quam	2021-04-14	JD812	\N	\N	36	6	5	2	7
499	311,00 ?	sem mauris	2020-07-13	JD812	\N	\N	46	7	5	2	12
500	89,00 ?	eget	2021-02-10	JD812	\N	\N	38	7	5	1	10
501	541,00 ?	rutrum at	2020-11-02	JD812	2020-12-23	2021-09-21	33	2	4	1	8
502	958,00 ?	rhoncus	2020-06-30	JD812	2020-12-29	\N	18	6	5	1	11
503	142,00 ?	vel	2021-03-10	JD812	2021-04-29	\N	31	1	8	1	6
504	164,00 ?	justo morbi	2020-11-13	JD812	\N	\N	98	5	10	4	10
505	884,00 ?	primis	2021-04-14	JD812	2020-11-14	\N	55	7	4	3	11
506	187,00 ?	in	2021-05-02	JD812	2020-09-19	\N	81	3	2	2	7
507	752,00 ?	sed accumsan	2021-01-03	JD812	\N	\N	68	4	9	1	7
508	817,00 ?	tortor id	2020-11-11	JD812	2020-09-14	\N	46	2	10	1	11
509	229,00 ?	augue	2020-11-03	JD812	\N	\N	54	7	10	3	9
510	675,00 ?	rutrum rutrum	2021-03-19	JD812	2021-03-06	\N	49	3	6	3	12
511	424,00 ?	pellentesque ultrices	2020-11-12	JD812	2021-03-05	\N	22	2	2	4	7
512	630,00 ?	vestibulum ante	2021-05-15	JD812	\N	2021-11-15	42	3	2	4	4
513	401,00 ?	rutrum neque	2021-05-16	JD812	2021-04-20	2021-12-03	13	7	2	3	10
514	623,00 ?	mus vivamus	2021-05-05	JD812	2020-09-18	2021-09-24	73	5	9	2	12
515	287,00 ?	dictumst	2021-03-19	JD812	2021-02-14	2021-11-20	80	3	9	2	9
516	833,00 ?	sed	2021-03-10	JD812	2020-10-30	\N	99	4	1	2	6
517	332,00 ?	eu nibh	2021-05-20	JD812	2021-02-09	2021-08-27	75	6	9	3	3
518	705,00 ?	quisque porta	2021-05-01	JD812	\N	\N	56	6	3	3	8
519	415,00 ?	tincidunt nulla	2020-06-28	JD812	\N	\N	51	4	10	1	5
520	895,00 ?	primis in	2021-04-25	JD812	2020-09-07	2021-06-27	11	6	9	1	1
521	209,00 ?	non	2020-10-02	JD812	2020-08-12	2021-12-08	58	3	5	2	8
522	907,00 ?	et	2021-02-26	JD812	2021-04-30	2021-10-16	6	2	3	2	3
523	415,00 ?	dictumst	2021-01-14	JD812	\N	\N	65	5	6	4	3
524	363,00 ?	pellentesque eget	2021-01-15	JD812	\N	\N	16	7	9	4	6
525	536,00 ?	duis	2021-04-09	JD812	\N	\N	66	5	6	4	3
526	945,00 ?	id	2021-04-13	JD812	\N	\N	14	2	9	4	4
527	447,00 ?	aliquet pulvinar	2020-08-19	JD812	2021-03-24	2021-07-11	78	2	1	2	10
528	275,00 ?	nulla tempus	2020-12-10	JD812	2020-10-30	2021-09-07	88	4	8	3	10
529	753,00 ?	nibh in	2020-10-17	JD812	\N	\N	66	1	7	3	9
530	497,00 ?	nec sem	2021-03-14	JD812	2021-01-06	2021-08-20	15	2	4	4	4
531	797,00 ?	orci vehicula	2021-01-10	JD812	2021-02-08	\N	56	6	3	4	11
532	186,00 ?	sem	2020-06-02	JD812	\N	\N	60	2	3	2	9
533	650,00 ?	convallis tortor	2020-06-29	JD812	\N	\N	7	4	3	1	5
534	95,00 ?	suscipit nulla	2020-08-17	JD812	2021-02-11	2021-10-04	88	7	4	3	7
535	835,00 ?	morbi	2021-03-22	JD812	\N	\N	57	3	3	4	9
536	540,00 ?	praesent blandit	2020-06-17	JD812	\N	\N	24	6	5	3	4
537	363,00 ?	nec sem	2020-11-02	JD812	2021-04-23	\N	67	2	6	1	3
538	905,00 ?	quis justo	2020-09-17	JD812	2020-11-19	\N	52	3	8	3	2
539	450,00 ?	nulla	2021-01-31	JD812	2021-02-23	\N	12	2	6	4	10
540	768,00 ?	odio odio	2021-03-27	JD812	2020-12-17	\N	23	3	3	2	2
541	683,00 ?	mi nulla	2020-12-22	JD812	\N	\N	54	3	9	3	10
542	443,00 ?	dis parturient	2021-05-14	JD812	2020-11-21	2021-11-07	41	1	5	1	7
543	318,00 ?	vestibulum sagittis	2020-10-27	JD812	\N	\N	30	1	3	1	9
544	387,00 ?	risus	2021-01-30	JD812	\N	\N	30	7	7	4	5
545	867,00 ?	nulla neque	2021-03-05	JD812	2020-05-27	2021-12-17	69	1	6	3	6
546	440,00 ?	amet sem	2020-07-17	JD812	\N	2021-07-04	71	4	1	2	7
547	970,00 ?	volutpat	2020-06-06	JD812	2020-06-22	2021-08-09	37	6	9	2	7
548	407,00 ?	quam fringilla	2020-11-12	JD812	2020-08-23	\N	65	2	3	2	11
549	758,00 ?	nulla dapibus	2020-08-08	JD812	2021-05-01	\N	10	1	5	3	3
550	493,00 ?	morbi vestibulum	2020-10-28	JD812	\N	\N	23	5	2	2	11
551	500,00 ?	duis consequat	2021-04-24	JD812	2020-06-27	\N	47	1	4	3	4
552	193,00 ?	morbi vel	2020-11-24	JD812	2020-11-07	\N	26	4	10	1	6
553	710,00 ?	orci pede	2020-10-24	JD812	\N	\N	90	3	2	4	11
554	250,00 ?	ligula	2021-01-24	JD812	2020-10-19	\N	15	1	8	2	3
555	803,00 ?	felis ut	2020-11-26	JD812	\N	\N	68	2	4	1	12
556	123,00 ?	luctus et	2021-04-05	JD812	\N	\N	52	7	4	3	10
557	996,00 ?	sed	2020-07-26	JD812	\N	2021-10-10	68	6	6	1	7
558	918,00 ?	pretium	2020-08-23	JD812	2020-10-25	\N	83	2	10	1	1
559	288,00 ?	risus	2020-12-06	JD812	2021-03-10	2021-12-12	98	2	7	2	6
560	460,00 ?	quam	2020-06-03	JD812	2020-09-30	\N	22	1	7	3	11
561	488,00 ?	a feugiat	2021-04-15	JD812	2021-03-22	2021-12-06	35	2	6	2	6
562	804,00 ?	ligula	2021-05-08	JD812	\N	2021-10-25	91	4	1	4	11
563	232,00 ?	porttitor	2020-12-22	JD812	\N	2021-08-05	67	5	6	4	3
564	746,00 ?	luctus et	2020-08-20	JD812	2020-06-20	\N	9	7	8	3	2
565	549,00 ?	iaculis justo	2020-09-14	JD812	2020-09-26	\N	18	1	8	3	8
566	761,00 ?	odio odio	2021-05-08	JD812	2020-07-10	2021-06-30	69	2	4	3	5
567	547,00 ?	convallis	2020-08-06	JD812	2020-11-18	2021-08-02	17	5	8	1	3
568	507,00 ?	gravida sem	2020-12-11	JD812	2021-03-10	\N	93	1	1	2	5
569	848,00 ?	eu pede	2020-07-31	JD812	2021-01-08	\N	7	2	4	4	6
570	126,00 ?	et ultrices	2020-08-22	JD812	2021-05-11	\N	86	2	3	1	4
571	355,00 ?	quam sollicitudin	2021-02-14	JD812	2021-03-16	\N	90	7	3	1	2
572	144,00 ?	pede ac	2020-09-06	JD812	\N	2021-06-09	67	6	5	2	7
573	267,00 ?	orci eget	2020-08-22	JD812	2020-11-25	2021-06-28	14	7	10	2	9
574	836,00 ?	at	2020-12-16	JD812	2020-09-29	\N	7	1	2	3	10
575	158,00 ?	fermentum donec	2021-01-01	JD812	\N	2021-06-13	6	6	4	2	12
576	715,00 ?	ultrices	2020-08-30	JD812	2021-05-10	2021-11-07	74	1	10	1	12
577	338,00 ?	nulla	2020-08-31	JD812	2021-03-28	2021-10-03	51	1	9	4	9
578	514,00 ?	aenean	2020-07-21	JD812	\N	\N	13	2	5	2	4
579	379,00 ?	in faucibus	2021-01-12	JD812	2020-06-05	2021-09-26	14	5	8	4	2
580	184,00 ?	duis consequat	2020-10-10	JD812	2021-02-08	\N	88	6	1	3	5
581	667,00 ?	vulputate justo	2021-01-09	JD812	2021-02-05	\N	72	2	2	1	8
582	740,00 ?	praesent	2020-08-29	JD812	2020-10-20	2021-10-15	31	7	10	3	3
583	452,00 ?	tristique in	2020-06-21	JD812	\N	\N	18	7	1	4	3
584	874,00 ?	et ultrices	2020-07-28	JD812	\N	\N	42	7	10	2	12
585	805,00 ?	nascetur ridiculus	2020-10-05	JD812	\N	\N	33	6	1	1	2
586	66,00 ?	mus vivamus	2021-03-01	JD812	\N	\N	49	4	9	4	10
587	436,00 ?	nunc	2020-08-12	JD812	2021-03-14	\N	78	7	5	4	12
588	962,00 ?	non	2020-08-18	JD812	2021-02-27	2021-11-20	80	5	9	1	4
589	71,00 ?	elementum	2021-03-13	JD812	2020-10-17	2021-09-28	79	6	2	3	7
590	115,00 ?	vitae nisi	2020-11-19	JD812	2020-11-02	\N	62	7	6	4	2
591	597,00 ?	ante nulla	2021-01-01	JD812	2021-01-26	\N	16	4	1	3	2
592	453,00 ?	mi	2020-08-22	JD812	2020-10-03	\N	36	4	1	1	12
593	809,00 ?	sit amet	2020-12-18	JD812	\N	2021-06-09	43	2	5	4	3
594	572,00 ?	luctus ultricies	2021-03-03	JD812	\N	\N	52	4	1	1	5
595	871,00 ?	vestibulum sagittis	2020-12-30	JD812	\N	\N	26	2	4	4	7
596	498,00 ?	aenean	2020-06-27	JD812	2021-03-10	\N	42	7	9	3	7
597	819,00 ?	justo	2020-07-11	JD812	2021-01-17	\N	96	1	4	4	11
598	825,00 ?	praesent lectus	2020-07-13	JD812	2020-12-16	2021-06-07	59	3	9	4	11
599	480,00 ?	in	2021-03-24	JD812	2020-09-25	\N	84	4	5	1	9
600	629,00 ?	nulla	2020-10-16	JD812	2020-12-10	\N	79	2	5	1	8
601	362,00 ?	blandit	2021-05-22	JD812	2021-03-20	2021-06-19	26	1	4	3	3
602	561,00 ?	dui	2020-05-31	JD812	\N	\N	36	4	8	3	6
603	805,00 ?	leo	2021-04-16	JD812	2020-11-08	2021-11-07	68	3	1	3	2
604	755,00 ?	cras	2020-10-08	JD812	\N	\N	47	5	9	3	11
605	804,00 ?	id ornare	2021-03-31	JD812	\N	\N	13	3	10	3	5
606	564,00 ?	integer	2021-03-24	JD812	2021-04-23	\N	73	7	4	3	9
607	680,00 ?	nulla	2020-07-21	JD812	2021-02-20	\N	87	6	5	1	7
608	880,00 ?	ut	2020-06-01	JD812	2021-01-13	2021-12-04	15	2	6	2	5
609	70,00 ?	non interdum	2020-12-09	JD812	2021-05-19	2021-12-12	34	4	4	1	2
610	693,00 ?	sit amet	2020-06-17	JD812	2020-12-13	2021-06-10	24	2	7	4	5
611	517,00 ?	maecenas	2020-10-07	JD812	2021-03-18	2021-06-01	93	5	8	3	1
612	526,00 ?	velit eu	2020-08-16	JD812	2021-03-13	\N	88	6	2	4	1
613	749,00 ?	vitae	2020-12-15	JD812	2020-09-09	\N	17	2	1	2	9
614	146,00 ?	interdum venenatis	2020-08-23	JD812	2021-05-14	2021-09-17	10	7	4	2	6
615	161,00 ?	sed ante	2020-10-05	JD812	2021-01-25	\N	66	6	2	1	7
616	591,00 ?	turpis elementum	2020-06-19	JD812	2020-09-29	\N	26	3	5	1	6
617	513,00 ?	eget elit	2020-08-15	JD812	2020-09-01	\N	17	4	8	1	3
618	112,00 ?	ligula	2021-04-18	JD812	\N	\N	8	3	10	3	4
619	854,00 ?	ultrices phasellus	2020-06-08	JD812	2020-10-03	2021-05-25	96	3	6	2	1
620	854,00 ?	mauris	2020-09-08	JD812	2020-10-20	\N	35	4	5	1	3
621	148,00 ?	quam	2020-12-15	JD812	2021-05-14	\N	43	3	6	2	2
622	951,00 ?	aliquet	2020-07-30	JD812	\N	\N	22	6	9	3	10
623	651,00 ?	aliquam	2020-07-10	JD812	2021-01-04	\N	94	2	2	1	2
624	857,00 ?	lacinia	2020-05-27	JD812	\N	\N	44	4	7	3	2
625	539,00 ?	suspendisse	2021-04-23	JD812	2020-06-29	2021-08-31	92	3	8	2	1
626	481,00 ?	nam	2021-05-08	JD812	\N	\N	88	7	6	4	9
627	494,00 ?	molestie	2020-10-17	JD812	\N	\N	39	6	6	3	11
628	92,00 ?	penatibus	2020-06-25	JD812	2020-07-01	2021-07-07	96	7	3	1	6
629	616,00 ?	neque	2021-02-17	JD812	2020-05-25	\N	62	7	7	4	1
630	261,00 ?	lacinia erat	2020-06-07	JD812	2020-09-12	\N	48	4	4	3	12
631	376,00 ?	luctus	2020-12-08	JD812	2020-06-18	\N	33	4	9	2	11
632	241,00 ?	proin at	2020-09-08	JD812	2020-10-30	\N	12	3	8	1	7
633	165,00 ?	leo odio	2020-08-03	JD812	2020-06-25	\N	22	4	5	1	2
634	386,00 ?	platea	2021-01-24	JD812	\N	\N	78	3	6	3	10
635	954,00 ?	ultrices enim	2020-09-20	JD812	2020-11-05	2021-12-09	26	2	6	1	1
636	697,00 ?	odio	2020-09-01	JD812	2020-06-01	\N	73	1	7	2	8
637	732,00 ?	nonummy	2021-03-07	JD812	2020-11-30	\N	7	1	10	3	2
638	499,00 ?	in	2020-12-01	JD812	\N	\N	7	2	1	1	1
639	957,00 ?	eros	2020-12-23	JD812	2021-05-22	\N	64	6	1	3	12
640	870,00 ?	curae	2020-06-03	JD812	2021-04-02	2021-09-13	57	6	3	4	1
641	981,00 ?	lorem id	2021-04-10	JD812	\N	\N	49	1	6	4	6
642	667,00 ?	felis eu	2021-04-10	JD812	2020-11-22	\N	12	6	7	2	3
643	486,00 ?	donec vitae	2020-05-29	JD812	\N	2021-10-31	55	5	8	1	12
644	343,00 ?	at nulla	2020-11-05	JD812	2020-08-07	\N	80	1	6	4	3
645	172,00 ?	tincidunt	2020-08-23	JD812	2020-09-03	\N	73	2	7	1	3
646	980,00 ?	faucibus	2020-07-22	JD812	2020-10-28	2021-10-11	28	3	2	4	1
647	961,00 ?	ut ultrices	2021-05-17	JD812	2020-08-27	2021-11-22	88	5	8	1	7
648	536,00 ?	imperdiet sapien	2020-10-31	JD812	2021-03-29	\N	51	6	10	4	3
649	186,00 ?	curabitur	2020-12-24	JD812	\N	2021-12-09	81	2	8	3	10
650	471,00 ?	etiam	2021-03-18	JD812	2020-12-03	\N	49	1	5	2	6
651	729,00 ?	dignissim vestibulum	2020-12-21	JD812	2020-08-16	\N	52	2	9	2	8
652	532,00 ?	nulla quisque	2020-06-27	JD812	2021-02-06	\N	46	2	7	3	2
653	706,00 ?	sit	2020-06-07	JD812	2020-07-04	2021-07-06	15	7	3	3	1
654	313,00 ?	sem duis	2021-05-18	JD812	2021-02-02	\N	50	2	3	3	4
655	583,00 ?	vestibulum ante	2020-09-20	JD812	2021-02-21	\N	53	3	10	1	5
656	267,00 ?	sapien non	2020-12-22	JD812	2020-08-12	\N	54	3	2	2	5
657	574,00 ?	at velit	2021-02-07	JD812	\N	\N	73	4	2	3	2
658	836,00 ?	velit	2020-11-03	JD812	\N	\N	16	7	3	3	5
659	641,00 ?	maecenas ut	2020-06-14	JD812	2020-12-09	\N	96	4	5	3	4
660	752,00 ?	pharetra magna	2020-08-26	JD812	2020-08-28	2021-10-27	58	5	8	1	2
661	344,00 ?	cursus	2021-04-16	JD812	2020-12-14	\N	64	2	6	4	2
662	575,00 ?	morbi non	2020-07-28	JD812	2021-01-13	\N	28	4	10	4	4
663	808,00 ?	leo	2020-06-18	JD812	2020-12-30	\N	32	3	9	1	11
664	851,00 ?	quam sollicitudin	2021-02-22	JD812	2020-06-06	2021-09-23	18	5	5	3	4
665	987,00 ?	diam neque	2020-11-11	JD812	2021-01-17	\N	10	4	1	4	5
666	500,00 ?	platea dictumst	2020-10-31	JD812	2020-12-14	\N	45	6	8	3	7
667	351,00 ?	ridiculus mus	2021-04-25	JD812	2020-10-19	2021-07-16	53	5	2	2	11
668	986,00 ?	sollicitudin vitae	2021-03-30	JD812	2021-02-05	2021-11-17	13	4	10	4	9
669	480,00 ?	aliquet pulvinar	2020-09-08	JD812	2020-07-05	\N	48	6	6	1	5
670	414,00 ?	ut	2020-10-30	JD812	\N	\N	38	7	2	1	5
671	498,00 ?	dis	2020-10-22	JD812	2021-01-18	\N	69	3	4	2	11
672	178,00 ?	rutrum	2021-03-01	JD812	2020-10-08	\N	14	7	4	3	2
673	636,00 ?	donec	2020-08-02	JD812	\N	\N	40	3	6	2	12
674	391,00 ?	mauris	2021-01-11	JD812	2020-05-26	\N	6	3	1	3	10
675	939,00 ?	tristique est	2021-01-16	JD812	2020-07-15	\N	50	4	6	1	10
676	996,00 ?	integer ac	2021-01-16	JD812	2021-02-25	\N	28	2	1	3	7
677	392,00 ?	rutrum nulla	2020-10-30	JD812	\N	\N	46	6	6	1	8
678	481,00 ?	duis	2021-03-07	JD812	2020-06-04	2021-12-05	60	2	10	4	12
679	69,00 ?	at	2020-12-12	JD812	\N	2021-08-12	70	1	8	3	4
680	856,00 ?	orci	2021-01-13	JD812	2020-11-17	2021-08-23	83	4	4	1	5
681	847,00 ?	lorem	2020-12-09	JD812	\N	\N	95	1	4	3	7
682	644,00 ?	magna	2020-12-31	JD812	2021-04-18	\N	29	6	2	2	7
683	520,00 ?	quis tortor	2020-06-04	JD812	2020-12-02	\N	13	7	1	4	11
684	807,00 ?	non sodales	2021-02-18	JD812	2020-07-26	\N	61	5	6	3	7
685	783,00 ?	morbi	2021-02-13	JD812	\N	\N	91	2	8	3	2
686	289,00 ?	morbi	2020-06-01	JD812	2020-08-03	\N	42	4	6	4	8
687	327,00 ?	cum	2020-07-14	JD812	2020-10-05	2021-06-20	23	5	6	4	9
688	882,00 ?	nisl venenatis	2020-06-11	JD812	\N	\N	62	2	2	3	2
689	118,00 ?	vestibulum	2020-12-25	JD812	2020-06-01	\N	98	3	7	2	8
690	356,00 ?	turpis	2021-04-02	JD812	2020-09-09	\N	36	1	5	3	5
691	196,00 ?	mi integer	2021-05-18	JD812	\N	\N	58	1	9	1	4
692	138,00 ?	mauris vulputate	2021-05-07	JD812	2020-07-17	\N	39	4	9	2	3
693	725,00 ?	varius nulla	2020-08-27	JD812	2020-09-07	\N	72	6	8	2	7
694	145,00 ?	tellus nulla	2021-01-05	JD812	2020-07-16	\N	93	7	6	4	2
695	336,00 ?	leo	2020-06-17	JD812	2021-04-09	\N	70	4	6	3	12
696	380,00 ?	turpis	2021-01-12	JD812	2020-08-29	\N	68	1	4	2	3
697	324,00 ?	morbi porttitor	2021-05-13	JD812	2020-12-27	\N	64	4	4	4	4
698	715,00 ?	lectus	2020-11-26	JD812	2020-09-07	\N	24	1	1	1	6
699	653,00 ?	ligula sit	2020-06-24	JD812	2020-12-01	\N	81	4	9	3	3
700	66,00 ?	morbi quis	2020-07-01	JD812	\N	\N	52	1	6	3	11
701	95,00 ?	augue	2020-09-29	JD812	2020-11-27	\N	44	1	4	4	7
702	127,00 ?	venenatis tristique	2020-08-12	JD812	2020-06-16	2021-10-15	21	5	7	3	7
703	263,00 ?	varius	2020-06-28	JD812	2020-10-22	\N	8	7	5	2	3
704	324,00 ?	bibendum	2021-04-07	JD812	\N	\N	82	7	7	3	11
705	267,00 ?	id	2020-11-24	JD812	2020-12-23	2021-09-18	8	6	7	4	3
706	559,00 ?	posuere felis	2020-09-03	JD812	2020-09-09	2021-07-02	61	6	6	3	5
707	794,00 ?	orci	2020-07-20	JD812	2020-08-17	\N	39	5	9	2	4
708	959,00 ?	nunc nisl	2021-03-18	JD812	2020-11-30	\N	21	6	6	3	3
709	614,00 ?	diam erat	2021-02-23	JD812	\N	2021-10-02	10	5	1	1	3
710	409,00 ?	id nulla	2021-01-26	JD812	2021-04-21	\N	72	7	9	1	2
711	539,00 ?	volutpat dui	2020-12-20	JD812	2021-04-15	\N	70	6	3	1	7
712	942,00 ?	augue vel	2021-05-05	JD812	2020-08-11	\N	98	7	5	3	9
713	382,00 ?	aliquam	2020-05-24	JD812	2020-07-12	\N	74	5	9	1	5
714	709,00 ?	congue	2021-01-13	JD812	\N	\N	37	1	5	3	1
715	608,00 ?	in	2021-01-27	JD812	2021-03-27	\N	85	7	2	3	8
716	641,00 ?	mi	2021-04-17	JD812	2020-11-03	2021-07-17	82	6	2	2	3
717	198,00 ?	vitae mattis	2020-08-14	JD812	2021-04-04	\N	73	5	6	4	9
718	55,00 ?	cubilia	2021-03-12	JD812	\N	2021-10-09	11	4	6	3	4
719	644,00 ?	nam	2020-09-05	JD812	2020-12-12	\N	98	1	4	2	11
720	358,00 ?	lacinia	2021-03-21	JD812	\N	2021-11-22	29	4	6	3	7
721	812,00 ?	justo pellentesque	2020-09-06	JD812	2021-03-14	\N	44	2	6	4	1
722	825,00 ?	libero convallis	2021-03-25	JD812	2020-12-17	\N	52	4	9	4	9
723	80,00 ?	neque	2021-04-27	JD812	2020-10-27	2021-09-19	14	2	7	2	12
724	525,00 ?	tincidunt ante	2020-12-02	JD812	2020-10-15	2021-09-04	50	4	6	3	5
725	773,00 ?	etiam faucibus	2020-05-29	JD812	2021-01-18	\N	94	6	10	2	2
726	620,00 ?	consequat	2020-07-26	JD812	\N	\N	68	3	2	1	3
727	952,00 ?	convallis duis	2020-06-20	JD812	\N	\N	46	4	2	1	12
728	628,00 ?	sem	2021-03-29	JD812	2020-06-28	\N	31	1	1	4	1
729	576,00 ?	et ultrices	2021-04-13	JD812	2021-05-05	\N	80	2	4	1	5
730	785,00 ?	habitasse platea	2020-06-29	JD812	2020-11-30	\N	96	6	9	3	1
731	349,00 ?	nec	2021-01-02	JD812	\N	\N	10	3	7	2	11
732	373,00 ?	justo	2021-05-15	JD812	2020-10-07	2021-09-02	14	1	2	4	7
733	195,00 ?	donec	2021-02-18	JD812	2021-01-28	2021-08-02	86	1	10	1	2
734	753,00 ?	volutpat	2020-11-11	JD812	2021-04-17	2021-06-15	28	3	7	4	4
735	474,00 ?	hac	2020-10-11	JD812	2020-10-11	2021-07-30	45	1	7	1	9
736	649,00 ?	tempus vel	2020-10-07	JD812	2020-10-16	\N	78	4	6	1	5
737	190,00 ?	lacinia eget	2021-04-19	JD812	2020-10-30	\N	47	6	8	1	10
738	909,00 ?	primis	2020-11-11	JD812	2021-02-03	2021-06-02	13	7	3	2	2
739	314,00 ?	in hac	2020-06-02	JD812	2020-07-31	2021-05-30	83	7	7	4	8
740	142,00 ?	augue quam	2020-06-02	JD812	2021-05-10	\N	94	4	6	3	12
741	309,00 ?	nulla sed	2020-07-25	JD812	2020-12-18	\N	36	4	9	1	6
742	473,00 ?	tortor	2020-12-12	JD812	2020-10-17	2021-06-23	56	6	7	1	11
743	707,00 ?	eget	2021-02-11	JD812	\N	2021-07-17	59	5	7	3	5
744	779,00 ?	nulla justo	2021-01-19	JD812	2021-02-14	\N	39	4	3	3	11
745	764,00 ?	turpis integer	2020-10-12	JD812	\N	\N	59	6	6	3	4
746	314,00 ?	hac	2020-08-24	JD812	2021-01-01	2021-06-19	24	1	2	3	7
747	507,00 ?	porttitor	2021-03-02	JD812	2020-05-25	\N	29	5	1	3	2
748	648,00 ?	odio	2021-04-21	JD812	\N	2021-06-05	57	5	2	4	9
749	211,00 ?	eget	2021-01-19	JD812	\N	\N	61	2	6	3	12
750	333,00 ?	turpis	2020-10-02	JD812	2020-11-27	\N	52	3	6	3	10
751	861,00 ?	ac	2020-06-02	JD812	2020-12-21	\N	57	6	7	1	9
752	788,00 ?	non quam	2021-01-24	JD812	2021-01-14	\N	97	6	5	3	3
753	244,00 ?	eget	2021-02-15	JD812	\N	\N	28	7	7	1	2
754	983,00 ?	donec	2020-07-05	JD812	\N	\N	51	4	2	2	6
755	439,00 ?	nullam	2020-11-27	JD812	\N	\N	53	4	3	4	1
756	508,00 ?	condimentum	2020-08-13	JD812	2020-06-03	2021-07-01	17	6	3	1	1
757	109,00 ?	in tempor	2021-02-22	JD812	2020-05-28	\N	30	3	2	4	9
758	840,00 ?	nullam porttitor	2020-10-31	JD812	\N	\N	23	4	2	3	1
759	766,00 ?	congue eget	2021-02-07	JD812	2021-02-12	2021-11-24	70	5	10	4	2
760	473,00 ?	amet	2021-03-10	JD812	\N	\N	47	3	4	2	9
761	248,00 ?	donec	2020-06-27	JD812	2020-10-29	\N	91	2	4	3	4
762	236,00 ?	vivamus tortor	2021-01-26	JD812	\N	2021-07-16	57	7	3	3	9
763	187,00 ?	hac	2020-11-20	JD812	2021-03-14	\N	93	7	10	1	5
764	126,00 ?	faucibus orci	2021-02-03	JD812	2020-09-14	2021-05-24	87	2	8	3	5
765	448,00 ?	vestibulum	2020-12-14	JD812	2020-12-20	\N	24	6	10	1	5
766	986,00 ?	turpis enim	2020-12-16	JD812	\N	\N	36	7	1	4	7
767	298,00 ?	tristique	2021-05-08	JD812	2020-08-04	\N	34	6	2	3	9
768	905,00 ?	hendrerit at	2020-07-12	JD812	2020-11-24	\N	25	4	3	4	7
769	591,00 ?	arcu	2021-02-14	JD812	\N	\N	74	4	6	2	8
770	890,00 ?	habitasse platea	2020-07-10	JD812	2020-05-28	2021-06-29	64	5	3	4	9
771	343,00 ?	in	2020-07-31	JD812	2020-07-19	\N	31	7	10	2	6
772	422,00 ?	cubilia curae	2020-07-29	JD812	2020-10-04	\N	69	3	5	2	10
773	370,00 ?	velit	2021-03-03	JD812	2020-12-12	2021-08-02	28	6	5	4	1
774	955,00 ?	donec odio	2020-11-17	JD812	2021-02-25	\N	81	3	10	4	7
775	228,00 ?	odio donec	2021-05-18	JD812	2020-08-13	\N	90	4	6	3	3
776	415,00 ?	pellentesque quisque	2020-06-26	JD812	2020-11-01	\N	43	7	10	4	6
777	674,00 ?	pharetra	2021-03-10	JD812	2020-10-26	2021-12-18	41	2	3	4	11
778	402,00 ?	lorem	2020-08-12	JD812	\N	2021-08-24	15	2	6	1	6
779	888,00 ?	tellus nisi	2020-09-18	JD812	\N	\N	20	3	9	4	10
780	451,00 ?	sed	2021-04-16	JD812	\N	\N	69	5	8	2	7
781	743,00 ?	aliquet pulvinar	2020-09-25	JD812	2020-06-20	\N	56	7	4	1	8
782	330,00 ?	luctus	2020-06-02	JD812	2021-03-09	\N	38	3	2	4	11
783	173,00 ?	et	2020-05-29	JD812	\N	\N	45	1	6	2	10
784	121,00 ?	vehicula	2021-02-01	JD812	2020-10-01	2021-07-14	13	6	8	2	4
785	701,00 ?	blandit nam	2021-02-13	JD812	2020-06-23	\N	29	7	3	3	1
786	571,00 ?	eu	2020-06-24	JD812	\N	\N	42	6	9	1	3
787	603,00 ?	aliquam	2021-03-31	JD812	2020-05-29	\N	91	2	5	2	12
788	889,00 ?	dolor sit	2020-12-13	JD812	2021-04-13	\N	58	3	6	2	2
789	373,00 ?	interdum	2020-06-10	JD812	2021-05-23	2021-05-24	78	5	6	1	10
790	455,00 ?	eu orci	2020-10-13	JD812	2021-01-27	2021-09-07	71	4	6	1	3
791	914,00 ?	aliquam lacus	2021-01-13	JD812	2020-09-19	\N	44	2	5	4	2
792	904,00 ?	amet	2020-07-07	JD812	2021-03-21	\N	30	4	2	1	7
793	825,00 ?	sit	2021-02-26	JD812	2020-07-11	\N	70	2	10	4	2
794	542,00 ?	fusce	2020-06-06	JD812	\N	\N	52	5	3	1	12
795	58,00 ?	in hac	2020-10-24	JD812	\N	\N	36	2	4	2	7
796	540,00 ?	purus	2021-03-08	JD812	2021-05-08	2021-12-20	97	2	9	2	1
797	583,00 ?	diam vitae	2021-01-02	JD812	2020-10-05	\N	16	5	7	1	9
798	84,00 ?	mi sit	2021-05-17	JD812	\N	\N	87	1	7	1	2
799	920,00 ?	aenean sit	2021-02-19	JD812	\N	\N	84	2	8	2	2
800	1 000,00 ?	tortor quis	2021-02-08	JD812	2020-07-02	2021-08-14	28	4	1	2	6
801	146,00 ?	orci luctus	2020-10-05	JD812	\N	\N	16	5	1	1	7
802	524,00 ?	massa	2021-05-02	JD812	2020-06-11	\N	94	5	2	1	4
803	329,00 ?	dapibus	2020-06-12	JD812	\N	2021-10-11	28	2	8	4	7
804	573,00 ?	aliquam erat	2020-08-20	JD812	2020-06-19	2021-08-07	90	2	6	2	3
805	775,00 ?	urna	2021-01-06	JD812	\N	\N	77	6	5	1	4
806	666,00 ?	commodo vulputate	2021-05-04	JD812	2020-06-19	\N	12	4	5	1	8
807	210,00 ?	curae	2020-10-27	JD812	2021-03-22	2021-07-08	83	7	3	2	2
808	268,00 ?	ridiculus	2021-03-09	JD812	2021-01-13	\N	89	5	6	1	5
809	140,00 ?	nulla	2020-08-17	JD812	2020-06-17	\N	69	1	4	4	11
810	996,00 ?	ante	2020-06-01	JD812	2020-06-10	\N	21	7	9	4	7
811	258,00 ?	in	2021-03-30	JD812	2021-03-05	\N	51	4	6	4	9
812	844,00 ?	habitasse	2020-09-20	JD812	\N	\N	70	4	9	4	9
813	189,00 ?	leo	2021-01-07	JD812	\N	2021-08-31	21	1	10	3	12
814	156,00 ?	tincidunt in	2021-05-17	JD812	2020-09-07	\N	87	4	4	4	8
815	851,00 ?	aliquet	2021-04-15	JD812	2021-04-02	\N	99	3	8	3	9
816	811,00 ?	dolor	2020-11-19	JD812	2020-07-28	\N	21	3	6	3	12
817	770,00 ?	hac	2020-07-12	JD812	2020-10-04	\N	95	7	9	1	3
818	153,00 ?	ac	2021-04-03	JD812	\N	\N	92	5	9	2	10
819	888,00 ?	nascetur ridiculus	2021-04-01	JD812	\N	\N	86	3	7	1	7
820	787,00 ?	nullam varius	2020-08-04	JD812	\N	\N	54	1	5	1	4
821	883,00 ?	lorem	2021-01-16	JD812	2020-06-11	\N	84	1	4	2	9
822	806,00 ?	vel	2021-02-22	JD812	2020-11-17	\N	6	4	4	1	5
823	728,00 ?	congue	2020-12-19	JD812	\N	\N	11	4	7	1	5
824	253,00 ?	vestibulum	2020-09-26	JD812	2021-05-04	\N	98	7	2	1	10
825	771,00 ?	et	2020-09-12	JD812	2020-10-30	2021-12-02	67	6	2	1	1
826	629,00 ?	mauris non	2021-04-15	JD812	\N	\N	90	1	5	3	1
827	802,00 ?	velit	2020-07-12	JD812	2020-11-03	\N	8	3	7	2	8
828	818,00 ?	volutpat eleifend	2020-08-14	JD812	2020-10-01	\N	8	2	3	4	3
829	445,00 ?	velit nec	2021-03-15	JD812	\N	\N	92	4	3	4	4
830	790,00 ?	neque	2020-11-30	JD812	2021-05-23	\N	32	1	5	4	9
831	919,00 ?	ut	2021-03-28	JD812	\N	\N	33	1	1	2	6
832	720,00 ?	sed	2020-11-10	JD812	2020-08-21	2021-06-07	53	6	9	2	7
833	138,00 ?	magna bibendum	2020-11-19	JD812	2020-10-01	2021-11-27	80	3	2	2	1
834	836,00 ?	cras pellentesque	2020-07-05	JD812	2020-11-06	2021-08-04	81	1	2	4	2
835	101,00 ?	cum sociis	2021-05-14	JD812	2020-08-20	2021-11-29	76	4	8	1	8
836	191,00 ?	justo in	2020-11-17	JD812	\N	2021-11-07	96	5	8	2	12
837	70,00 ?	accumsan felis	2020-12-18	JD812	2020-06-29	2021-06-25	69	5	2	2	11
838	441,00 ?	ut	2020-07-03	JD812	2020-11-29	\N	36	4	6	4	11
839	690,00 ?	porttitor	2021-04-15	JD812	2020-08-14	2021-06-20	95	1	1	3	9
840	260,00 ?	nibh	2020-06-27	JD812	2021-04-20	\N	36	7	7	4	6
841	900,00 ?	dolor	2020-09-07	JD812	2020-05-29	2021-07-16	26	2	8	4	1
842	220,00 ?	elementum in	2020-08-05	JD812	2020-09-22	\N	33	6	3	4	10
843	262,00 ?	odio	2021-03-11	JD812	\N	2021-09-19	33	3	1	2	1
844	592,00 ?	sit amet	2020-05-29	JD812	2020-10-12	2021-10-08	79	3	6	4	5
845	810,00 ?	vel	2021-04-03	JD812	\N	\N	6	5	9	2	3
846	987,00 ?	id	2021-03-05	JD812	2021-03-29	\N	17	2	2	3	9
847	839,00 ?	mauris	2021-04-14	JD812	2021-01-02	\N	47	5	7	1	3
848	372,00 ?	nullam	2020-12-21	JD812	\N	\N	43	7	1	4	2
849	533,00 ?	in hac	2020-12-18	JD812	2021-04-09	\N	86	6	2	2	7
850	922,00 ?	mus	2021-03-16	JD812	\N	\N	91	7	9	1	12
851	372,00 ?	vulputate luctus	2020-12-19	JD812	2020-07-04	2021-07-12	27	4	6	4	10
852	673,00 ?	magnis dis	2020-12-25	JD812	2020-06-26	\N	73	7	6	3	5
853	105,00 ?	nisi venenatis	2021-01-23	JD812	\N	2021-11-30	55	4	4	3	1
854	123,00 ?	purus sit	2020-10-24	JD812	\N	\N	8	3	7	3	3
855	396,00 ?	vel	2021-01-14	JD812	\N	\N	62	1	6	3	8
856	374,00 ?	vulputate	2020-12-20	JD812	\N	2021-10-07	15	1	4	2	9
857	224,00 ?	massa	2021-03-17	JD812	2020-06-15	\N	90	6	6	3	10
858	438,00 ?	ultrices	2021-02-01	JD812	2020-06-26	\N	78	6	4	4	8
859	599,00 ?	dapibus	2021-04-25	JD812	2020-10-01	\N	70	5	9	3	11
860	994,00 ?	ut dolor	2020-06-08	JD812	\N	\N	7	4	4	2	10
861	540,00 ?	sem	2020-08-23	JD812	2020-12-07	\N	40	4	1	3	3
862	117,00 ?	consequat	2020-11-04	JD812	2020-08-06	2021-06-05	30	5	2	1	9
863	888,00 ?	id	2021-04-05	JD812	2021-01-19	2021-11-03	56	1	6	3	9
864	173,00 ?	pede justo	2020-10-29	JD812	\N	\N	78	6	10	1	3
865	895,00 ?	in	2021-04-28	JD812	\N	\N	73	3	4	3	1
866	69,00 ?	imperdiet nullam	2020-08-05	JD812	2020-07-03	\N	97	5	7	1	7
867	579,00 ?	nam	2020-11-25	JD812	2020-10-19	\N	45	6	5	2	5
868	214,00 ?	interdum mauris	2020-08-25	JD812	\N	\N	38	5	2	2	5
869	877,00 ?	ultricies eu	2020-06-04	JD812	2020-11-16	2021-10-23	66	5	7	1	12
870	844,00 ?	erat tortor	2021-05-11	JD812	2021-01-16	2021-08-06	28	1	8	4	12
871	926,00 ?	in	2020-06-04	JD812	2020-11-04	\N	99	7	1	4	2
872	618,00 ?	dictumst aliquam	2020-10-09	JD812	2020-07-28	\N	47	2	1	1	8
873	167,00 ?	fusce congue	2020-11-30	JD812	\N	\N	47	2	3	4	1
874	515,00 ?	suscipit	2020-11-04	JD812	2020-10-31	\N	39	7	6	4	10
875	472,00 ?	tempor turpis	2021-01-16	JD812	\N	\N	9	1	3	1	5
876	903,00 ?	orci	2020-09-26	JD812	2020-07-25	\N	45	1	3	2	11
877	725,00 ?	sed	2021-01-09	JD812	2020-09-25	\N	95	6	2	1	8
878	728,00 ?	feugiat et	2020-10-17	JD812	2020-06-19	\N	47	7	2	4	5
879	624,00 ?	libero convallis	2020-10-14	JD812	2020-08-08	\N	37	7	7	4	9
880	515,00 ?	tortor risus	2020-06-19	JD812	\N	\N	10	3	8	4	3
881	957,00 ?	diam cras	2020-08-08	JD812	2020-06-13	\N	41	5	10	2	3
882	540,00 ?	in faucibus	2020-11-24	JD812	2020-12-16	\N	91	1	2	1	10
883	208,00 ?	at	2020-11-24	JD812	\N	2021-11-05	79	6	6	3	10
884	395,00 ?	nisi	2021-01-30	JD812	2020-12-21	\N	99	3	5	1	12
885	474,00 ?	mauris non	2021-05-17	JD812	2021-02-13	\N	73	4	3	2	4
886	121,00 ?	suspendisse	2020-06-15	JD812	2020-09-01	\N	64	6	9	1	5
887	51,00 ?	congue elementum	2020-12-20	JD812	2020-06-01	\N	17	6	5	1	11
888	250,00 ?	nulla	2020-08-22	JD812	2021-03-21	\N	98	1	10	3	12
889	809,00 ?	ut	2020-12-31	JD812	\N	\N	93	6	10	3	1
890	825,00 ?	in	2021-02-19	JD812	2020-06-09	\N	27	4	5	4	4
891	324,00 ?	donec ut	2020-06-11	JD812	2020-08-26	\N	70	6	5	4	6
892	601,00 ?	morbi porttitor	2020-12-02	JD812	2020-06-08	2021-09-22	17	4	4	2	2
893	211,00 ?	aliquet at	2020-11-04	JD812	2020-12-25	\N	63	3	2	1	8
894	858,00 ?	quam pede	2021-03-30	JD812	\N	\N	44	2	2	4	7
895	360,00 ?	ipsum	2021-02-02	JD812	2020-11-17	\N	79	5	1	2	10
896	787,00 ?	nam	2020-11-15	JD812	\N	2021-08-29	73	7	8	3	3
897	914,00 ?	laoreet ut	2020-10-14	JD812	2021-05-01	\N	16	5	8	1	8
898	855,00 ?	dapibus nulla	2020-08-21	JD812	2020-11-10	\N	19	7	7	4	1
899	108,00 ?	quisque	2020-12-17	JD812	\N	\N	71	1	5	4	6
900	723,00 ?	molestie nibh	2021-03-07	JD812	2020-08-22	\N	75	7	3	1	5
901	623,00 ?	volutpat erat	2021-02-25	JD812	2021-03-05	\N	40	3	4	3	6
902	217,00 ?	tortor	2021-02-12	JD812	2021-01-10	2021-11-27	95	6	7	2	11
903	344,00 ?	quis turpis	2021-04-16	JD812	2020-10-16	\N	14	6	10	1	6
904	207,00 ?	elit sodales	2020-12-27	JD812	\N	\N	66	3	6	1	3
905	961,00 ?	iaculis	2021-01-07	JD812	2021-02-02	\N	62	7	1	1	4
906	821,00 ?	dictumst	2021-02-17	JD812	2020-12-29	\N	79	4	10	2	5
907	384,00 ?	tristique tortor	2020-09-27	JD812	2020-09-04	\N	56	1	7	2	5
908	747,00 ?	turpis donec	2021-01-13	JD812	2020-06-22	2021-10-26	40	6	3	1	5
909	568,00 ?	lobortis	2021-03-26	JD812	2021-01-10	\N	51	1	10	4	12
910	811,00 ?	sed	2020-12-23	JD812	2020-12-06	\N	95	1	5	4	5
911	643,00 ?	magna vulputate	2020-12-25	JD812	2021-02-25	\N	44	5	6	1	10
912	105,00 ?	tempor	2021-02-28	JD812	\N	\N	35	4	6	2	7
913	100,00 ?	sed	2020-10-07	JD812	2020-07-17	\N	95	7	8	1	11
914	74,00 ?	non ligula	2020-11-06	JD812	2020-09-18	\N	32	3	5	2	3
915	539,00 ?	volutpat	2020-06-12	JD812	2020-05-31	2021-12-22	84	6	10	1	4
916	477,00 ?	natoque	2020-09-03	JD812	2020-09-10	2021-08-09	74	1	9	2	5
917	872,00 ?	pellentesque	2020-10-24	JD812	2021-04-24	2021-06-22	100	4	4	3	1
918	574,00 ?	nonummy	2021-03-18	JD812	2020-08-01	\N	27	1	2	2	3
919	330,00 ?	amet	2020-06-20	JD812	2020-10-22	\N	43	3	1	2	11
920	628,00 ?	volutpat eleifend	2021-03-07	JD812	2020-12-27	2021-10-26	42	6	8	4	7
921	302,00 ?	habitasse	2020-06-22	JD812	2020-10-05	\N	82	3	2	1	9
922	223,00 ?	gravida	2020-07-14	JD812	2021-01-01	\N	18	6	4	1	9
923	676,00 ?	lobortis	2021-03-27	JD812	2021-01-23	2021-07-02	89	1	9	1	1
924	398,00 ?	ligula nec	2020-12-15	JD812	2020-06-08	\N	18	2	2	3	7
925	907,00 ?	volutpat sapien	2020-06-20	JD812	\N	\N	62	2	9	2	2
926	296,00 ?	nullam porttitor	2021-04-15	JD812	2021-05-19	\N	24	4	6	3	11
927	277,00 ?	amet	2020-05-26	JD812	2020-12-30	2021-12-07	31	2	6	4	2
928	679,00 ?	blandit	2020-10-29	JD812	2021-04-08	\N	48	3	3	4	4
929	80,00 ?	ligula	2020-09-25	JD812	\N	\N	70	2	2	4	11
930	351,00 ?	gravida sem	2021-01-06	JD812	2020-08-02	\N	39	2	6	3	7
931	702,00 ?	ac	2020-12-25	JD812	\N	2021-06-23	58	4	2	4	12
932	788,00 ?	volutpat	2021-05-02	JD812	\N	\N	84	7	6	3	12
933	510,00 ?	habitasse	2021-01-25	JD812	2020-12-13	\N	63	2	4	3	6
934	519,00 ?	proin	2020-09-18	JD812	2021-04-05	\N	74	7	7	4	1
935	295,00 ?	in purus	2020-11-26	JD812	2020-06-15	\N	71	2	4	4	3
936	75,00 ?	vestibulum	2020-08-15	JD812	2020-08-04	\N	8	7	4	4	4
937	289,00 ?	donec	2021-03-07	JD812	2020-06-06	2021-06-19	15	2	2	1	9
938	140,00 ?	aliquet	2020-11-27	JD812	2020-09-20	2021-06-04	61	4	4	4	4
939	369,00 ?	aliquam	2021-03-24	JD812	2021-01-10	\N	78	3	6	1	4
940	331,00 ?	sapien varius	2020-07-14	JD812	2020-06-24	\N	15	6	5	2	11
941	730,00 ?	tristique in	2021-02-19	JD812	\N	2021-07-20	8	5	9	4	6
942	405,00 ?	eget	2021-03-24	JD812	2021-04-13	\N	58	4	1	2	11
943	813,00 ?	platea	2021-04-01	JD812	2021-03-28	2021-07-15	97	4	4	1	1
944	929,00 ?	libero nam	2021-03-07	JD812	2021-02-26	\N	8	6	7	2	12
945	541,00 ?	justo	2021-05-20	JD812	\N	\N	16	1	6	1	12
946	897,00 ?	sapien	2020-08-19	JD812	2020-08-24	\N	81	1	6	2	2
947	487,00 ?	ut	2020-12-10	JD812	2020-11-01	2021-07-05	80	7	1	4	2
948	290,00 ?	lacus	2020-06-16	JD812	\N	\N	37	3	2	4	6
949	881,00 ?	est	2021-03-08	JD812	2020-06-14	2021-07-03	59	4	9	1	7
950	376,00 ?	hac habitasse	2021-04-26	JD812	2020-10-01	\N	92	5	5	4	12
951	112,00 ?	consequat	2020-09-22	JD812	\N	\N	91	1	8	2	3
952	729,00 ?	pede ullamcorper	2020-08-26	JD812	\N	\N	36	1	3	3	10
953	914,00 ?	vel	2021-04-22	JD812	2021-01-22	\N	33	6	10	4	4
954	192,00 ?	cum	2021-02-23	JD812	2021-04-04	\N	47	5	10	4	3
955	129,00 ?	cum	2021-04-10	JD812	2021-04-17	\N	75	2	4	3	8
956	460,00 ?	duis mattis	2020-11-23	JD812	2021-03-05	\N	98	6	6	2	2
957	725,00 ?	sed interdum	2020-12-04	JD812	2020-12-20	\N	41	6	4	1	11
958	626,00 ?	maecenas tincidunt	2021-01-28	JD812	2021-04-03	\N	6	5	5	3	4
959	558,00 ?	mattis pulvinar	2020-08-28	JD812	2021-01-25	2021-10-05	20	1	9	2	8
960	778,00 ?	justo nec	2020-09-29	JD812	2020-07-25	\N	60	2	3	1	6
961	199,00 ?	donec odio	2020-06-14	JD812	2020-10-25	\N	68	7	3	4	1
962	638,00 ?	morbi odio	2021-05-12	JD812	2021-01-13	\N	29	4	7	1	6
963	855,00 ?	amet	2021-02-24	JD812	2020-11-08	\N	49	4	7	4	4
964	60,00 ?	curae nulla	2021-01-19	JD812	2020-05-27	2021-07-27	38	3	6	3	12
965	350,00 ?	nulla	2020-12-29	JD812	2021-01-13	2021-11-03	32	5	9	1	6
966	697,00 ?	nisi	2020-10-16	JD812	\N	\N	22	6	4	2	1
967	764,00 ?	vestibulum velit	2020-09-15	JD812	2020-10-22	\N	44	5	1	1	5
968	807,00 ?	ut	2021-02-18	JD812	\N	2021-11-22	61	5	7	4	4
969	777,00 ?	semper	2020-08-08	JD812	\N	\N	6	4	1	4	3
970	70,00 ?	maecenas	2021-02-27	JD812	\N	2021-09-12	65	3	10	4	11
971	957,00 ?	velit	2021-04-21	JD812	2021-01-01	\N	55	4	4	3	10
972	210,00 ?	tortor quis	2020-12-11	JD812	2020-09-04	\N	65	4	9	2	12
973	368,00 ?	cum sociis	2020-06-25	JD812	2020-07-18	2021-07-04	29	7	4	2	2
974	154,00 ?	ligula vehicula	2020-11-15	JD812	2020-11-10	\N	43	1	4	3	2
975	963,00 ?	a suscipit	2020-08-30	JD812	2021-05-18	\N	80	1	10	2	3
976	458,00 ?	non mauris	2020-07-11	JD812	2020-07-07	\N	89	7	3	4	6
977	242,00 ?	tortor	2020-12-19	JD812	2020-07-09	\N	88	1	6	3	6
978	307,00 ?	nulla nisl	2021-02-04	JD812	\N	\N	79	7	6	1	1
979	380,00 ?	amet diam	2021-04-09	JD812	2020-06-23	2021-12-20	65	4	1	3	8
980	420,00 ?	pellentesque	2020-11-06	JD812	\N	\N	63	6	9	2	1
981	280,00 ?	sapien varius	2020-09-14	JD812	2020-11-21	\N	93	7	4	1	10
982	538,00 ?	libero	2020-12-16	JD812	\N	2021-11-01	56	4	3	4	6
983	183,00 ?	ullamcorper purus	2020-11-19	JD812	\N	\N	60	1	1	2	7
984	473,00 ?	mauris lacinia	2020-05-28	JD812	2020-09-23	2021-10-08	88	7	5	2	12
985	669,00 ?	etiam	2020-08-27	JD812	2020-08-19	2021-07-01	85	5	8	3	12
986	450,00 ?	felis	2020-09-07	JD812	\N	\N	32	2	7	4	4
987	148,00 ?	hendrerit at	2020-11-29	JD812	\N	\N	32	2	6	3	9
988	503,00 ?	sagittis dui	2021-04-15	JD812	\N	\N	9	7	2	1	12
989	219,00 ?	orci luctus	2021-04-28	JD812	2021-03-27	2021-08-30	47	1	4	1	9
990	626,00 ?	porttitor id	2020-07-19	JD812	2020-09-09	2021-06-17	19	5	10	3	3
991	898,00 ?	lorem	2020-07-23	JD812	2020-12-08	2021-11-24	24	7	7	1	5
992	427,00 ?	nec	2021-01-18	JD812	2020-09-02	\N	45	1	1	4	5
993	80,00 ?	neque sapien	2020-11-10	JD812	2021-01-19	\N	31	2	5	4	1
994	706,00 ?	nec dui	2020-11-26	JD812	\N	2021-12-11	17	7	2	2	5
995	928,00 ?	sodales scelerisque	2020-09-10	JD812	2021-02-23	\N	82	6	2	1	4
996	401,00 ?	felis ut	2021-05-03	JD812	2020-06-08	\N	82	3	6	4	8
997	167,00 ?	fusce consequat	2020-07-28	JD812	2020-07-28	\N	10	6	3	4	10
998	130,00 ?	nibh in	2021-02-26	JD812	\N	\N	62	6	4	1	10
999	241,00 ?	lacinia eget	2021-01-13	JD812	2020-12-10	2021-10-05	54	1	3	3	3
1000	580,00 ?	primis in	2020-08-16	JD812	2021-02-15	\N	22	5	6	4	8
\.


--
-- TOC entry 3178 (class 0 OID 16531)
-- Dependencies: 216
-- Data for Name: medicine_equipment; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.medicine_equipment (id, price, name) FROM stdin;
1	1 500,00 ?	Танометр
2	3 000,00 ?	Дезинфицирующие средства
3	23 000,00 ?	Приборы для регистрации воздуха
4	300 000,00 ?	Прибор для определения прочности таблетокна истирание ИС1
6	3 000,00 ?	Цетрефуга
7	5 000,00 ?	Холодильник
8	1 500,00 ?	Весы
9	500,00 ?	Штатив
10	7 000,00 ?	PH-метры
11	8 000,00 ?	Автоматический рефрактометр
5	10 000,00 ?	Иономер
12	18 933,00 ?	risus semper
13	9 177,00 ?	nunc
14	8 925,00 ?	primis
15	24 936,00 ?	interdum mauris
16	23 417,00 ?	duis
17	11 204,00 ?	phasellus
18	842,00 ?	rutrum
19	7 860,00 ?	at
20	34 515,00 ?	condimentum
21	36 135,00 ?	vulputate
22	19 127,00 ?	libero nullam
23	8 712,00 ?	nec
24	32 815,00 ?	aliquam
25	31 080,00 ?	vestibulum sagittis
26	17 759,00 ?	duis aliquam
27	21 041,00 ?	morbi
28	9 354,00 ?	aenean
29	38 334,00 ?	in quis
30	31 756,00 ?	vel
31	28 740,00 ?	quam sollicitudin
32	34 316,00 ?	accumsan tellus
33	29 524,00 ?	ultrices posuere
34	21 690,00 ?	sit amet
35	6 182,00 ?	luctus
36	34 675,00 ?	leo
37	31 200,00 ?	nullam
38	22 350,00 ?	sapien cum
39	27 466,00 ?	ullamcorper
40	27 441,00 ?	aliquam augue
41	7 579,00 ?	nullam
42	36 783,00 ?	sed
43	5 343,00 ?	tortor
44	211,00 ?	nisl
45	30 838,00 ?	in
46	32 176,00 ?	feugiat non
47	33 992,00 ?	vel
48	9 284,00 ?	nibh
49	2 266,00 ?	eu nibh
50	32 700,00 ?	nisi venenatis
51	377,00 ?	felis
52	28 583,00 ?	ultrices
53	17 943,00 ?	mattis
54	22 582,00 ?	lacus
55	30 123,00 ?	dapibus duis
56	22 689,00 ?	est
57	17 157,00 ?	aenean sit
58	39 923,00 ?	sapien
59	17 120,00 ?	volutpat
60	28 272,00 ?	ac leo
61	37 556,00 ?	justo sit
62	3 059,00 ?	a
63	28 446,00 ?	erat
64	30 090,00 ?	in
65	20 495,00 ?	elementum eu
66	13 328,00 ?	dolor sit
67	39 207,00 ?	praesent
68	22 514,00 ?	tincidunt
69	20 650,00 ?	dolor
70	26 656,00 ?	sed
71	24 546,00 ?	nulla sed
72	5 837,00 ?	ligula
73	15 660,00 ?	at diam
74	2 970,00 ?	eu
75	5 361,00 ?	ac
76	34 275,00 ?	suspendisse potenti
77	434,00 ?	molestie hendrerit
78	13 322,00 ?	in
79	20 143,00 ?	nulla
80	10 233,00 ?	id sapien
81	32 756,00 ?	eget congue
82	23 323,00 ?	semper
83	26 702,00 ?	orci
84	10 376,00 ?	a odio
85	25 657,00 ?	vitae
86	10 594,00 ?	in felis
87	25 590,00 ?	integer
88	5 154,00 ?	donec
89	16 559,00 ?	in felis
90	17 269,00 ?	sed
91	8 268,00 ?	et tempus
92	15 924,00 ?	cubilia curae
93	21 299,00 ?	vestibulum
94	20 408,00 ?	praesent blandit
95	11 954,00 ?	sapien quis
96	28 664,00 ?	quis orci
97	16 011,00 ?	donec dapibus
98	11 201,00 ?	vivamus metus
99	11 066,00 ?	aliquam sit
100	37 896,00 ?	rutrum
101	10 272,00 ?	vulputate nonummy
102	19 595,00 ?	sem
103	6 069,00 ?	quam pharetra
104	11 942,00 ?	mauris
105	12 323,00 ?	metus vitae
106	9 390,00 ?	elementum
107	21 916,00 ?	rhoncus
108	16 053,00 ?	dapibus duis
109	26 523,00 ?	proin at
110	17 968,00 ?	sagittis dui
111	36 578,00 ?	turpis
112	32 772,00 ?	metus
113	24 025,00 ?	condimentum
114	29 846,00 ?	curabitur at
115	5 969,00 ?	vivamus
116	17 865,00 ?	eleifend luctus
117	29 105,00 ?	amet
118	17 803,00 ?	duis faucibus
119	5 847,00 ?	tincidunt in
120	11 617,00 ?	vulputate
121	38 393,00 ?	quam
122	39 514,00 ?	morbi
123	39 846,00 ?	curae duis
124	18 942,00 ?	consequat
125	7 825,00 ?	venenatis turpis
126	11 145,00 ?	libero non
127	13 856,00 ?	urna
128	17 379,00 ?	odio
129	3 283,00 ?	vestibulum
130	4 415,00 ?	ut dolor
131	15 451,00 ?	quam suspendisse
132	34 364,00 ?	ut
133	36 203,00 ?	nulla
134	6 313,00 ?	lacus curabitur
135	8 746,00 ?	proin
136	24 980,00 ?	massa tempor
137	18 316,00 ?	nulla ultrices
138	32 947,00 ?	sit
139	11 982,00 ?	mollis
140	37 325,00 ?	quisque arcu
141	9 059,00 ?	eros
142	8 524,00 ?	eros viverra
143	1 467,00 ?	consequat varius
144	5 899,00 ?	nulla
145	5 062,00 ?	id
146	28 863,00 ?	parturient
147	12 068,00 ?	eleifend donec
148	37 010,00 ?	mauris
149	15 572,00 ?	integer aliquet
150	17 923,00 ?	orci pede
151	19 837,00 ?	a
152	4 823,00 ?	ullamcorper purus
153	29 190,00 ?	ridiculus mus
154	21 997,00 ?	convallis morbi
155	30 978,00 ?	a
156	25 310,00 ?	ante
157	11 502,00 ?	nec sem
158	3 674,00 ?	ante ipsum
159	24 393,00 ?	dui
160	28 341,00 ?	pede
161	24 128,00 ?	in
162	33 574,00 ?	id
163	16 421,00 ?	vel
164	1 340,00 ?	ante ipsum
165	39 687,00 ?	id justo
166	17 267,00 ?	ante nulla
167	11 806,00 ?	vulputate
168	9 962,00 ?	integer
169	22 791,00 ?	hac
170	18 622,00 ?	sem
171	28 124,00 ?	eleifend
172	3 922,00 ?	quam fringilla
173	27 386,00 ?	nulla justo
174	36 553,00 ?	luctus et
175	29 272,00 ?	ut nulla
176	31 295,00 ?	at turpis
177	36 874,00 ?	potenti in
178	36 244,00 ?	ac
179	20 236,00 ?	ut dolor
180	8 719,00 ?	elementum
181	13 589,00 ?	massa quis
182	19 156,00 ?	in magna
183	31 509,00 ?	non
184	9 151,00 ?	lectus pellentesque
185	31 260,00 ?	aliquam
186	38 848,00 ?	et
187	10 591,00 ?	consectetuer adipiscing
188	21 635,00 ?	nisl ut
189	4 464,00 ?	ac
190	39 069,00 ?	a
191	39 219,00 ?	accumsan
192	22 727,00 ?	in imperdiet
193	30 929,00 ?	primis
194	30 546,00 ?	primis in
195	15 823,00 ?	pellentesque
196	28 724,00 ?	justo
197	12 902,00 ?	nulla neque
198	18 112,00 ?	mauris enim
199	407,00 ?	ut
200	38 289,00 ?	et commodo
201	8 607,00 ?	faucibus orci
202	29 131,00 ?	risus dapibus
203	508,00 ?	in
204	34 643,00 ?	luctus
205	23 651,00 ?	interdum mauris
206	12 430,00 ?	natoque
207	20 208,00 ?	ut
208	2 065,00 ?	nulla
209	34 923,00 ?	nulla tellus
210	8 201,00 ?	erat curabitur
211	5 672,00 ?	eget
212	29 518,00 ?	mattis odio
213	4 823,00 ?	sit amet
214	3 301,00 ?	non velit
215	23 174,00 ?	integer ac
216	37 257,00 ?	a ipsum
217	29 349,00 ?	velit
218	30 641,00 ?	sem
219	37 873,00 ?	platea
220	28 363,00 ?	risus
221	35 414,00 ?	duis
222	22 404,00 ?	rhoncus aliquet
223	23 314,00 ?	elit
224	10 060,00 ?	dapibus
225	21 448,00 ?	mattis odio
226	22 652,00 ?	platea dictumst
227	12 183,00 ?	cras in
228	3 702,00 ?	varius
229	28 198,00 ?	integer
230	15 846,00 ?	nunc
231	38 024,00 ?	vel
232	5 813,00 ?	suspendisse
233	22 304,00 ?	accumsan tellus
234	28 776,00 ?	commodo placerat
235	22 052,00 ?	in tempus
236	24 966,00 ?	vel
237	12 628,00 ?	pulvinar
238	6 900,00 ?	ligula suspendisse
239	12 178,00 ?	odio
240	13 672,00 ?	sem sed
241	29 553,00 ?	amet
242	9 531,00 ?	curae
243	14 777,00 ?	mollis molestie
244	10 344,00 ?	ridiculus mus
245	35 980,00 ?	nisi
246	37 328,00 ?	elit
247	38 241,00 ?	massa
248	12 305,00 ?	justo lacinia
249	25 585,00 ?	at
250	25 110,00 ?	rhoncus aliquam
251	19 023,00 ?	sit
252	28 031,00 ?	vitae quam
253	25 275,00 ?	mus etiam
254	33 489,00 ?	augue vestibulum
255	32 615,00 ?	hac
256	12 205,00 ?	volutpat
257	34 455,00 ?	ac
258	21 813,00 ?	quisque id
259	26 271,00 ?	dolor morbi
260	3 731,00 ?	lacus
261	37 241,00 ?	et commodo
262	25 866,00 ?	arcu adipiscing
263	36 485,00 ?	mauris
264	8 221,00 ?	at
265	36 310,00 ?	nec
266	27 478,00 ?	purus aliquet
267	7 165,00 ?	vulputate luctus
268	22 644,00 ?	felis
269	33 741,00 ?	quis
270	14 296,00 ?	in lectus
271	7 797,00 ?	congue eget
272	23 557,00 ?	dolor
273	22 470,00 ?	in tempus
274	30 057,00 ?	at
275	30 228,00 ?	in ante
276	36 077,00 ?	primis
277	15 133,00 ?	velit
278	22 865,00 ?	molestie
279	18 583,00 ?	orci nullam
280	241,00 ?	cursus id
281	28 138,00 ?	curae nulla
282	4 238,00 ?	semper interdum
283	35 230,00 ?	donec odio
284	33 224,00 ?	tortor
285	28 394,00 ?	odio porttitor
286	32 256,00 ?	dapibus augue
287	8 875,00 ?	ut suscipit
288	11 920,00 ?	faucibus accumsan
289	26 896,00 ?	in imperdiet
290	7 225,00 ?	semper
291	17 765,00 ?	orci luctus
292	3 760,00 ?	vulputate
293	12 720,00 ?	leo rhoncus
294	24 584,00 ?	vel enim
295	25 406,00 ?	integer
296	2 654,00 ?	eget
297	24 749,00 ?	felis sed
298	26 882,00 ?	pede morbi
299	30 007,00 ?	sed
300	533,00 ?	pellentesque
301	36 253,00 ?	id lobortis
302	9 007,00 ?	pulvinar sed
303	24 757,00 ?	eget congue
304	10 520,00 ?	in
305	18 698,00 ?	eu
306	8 196,00 ?	sed
307	39 135,00 ?	in hac
308	25 852,00 ?	orci eget
309	35 139,00 ?	cras pellentesque
310	39 863,00 ?	turpis
311	6 140,00 ?	praesent lectus
312	30 423,00 ?	interdum venenatis
313	29 820,00 ?	cras non
314	6 605,00 ?	eu sapien
315	25 932,00 ?	est phasellus
316	8 829,00 ?	ut erat
317	14 685,00 ?	vestibulum ante
318	27 607,00 ?	odio
319	37 550,00 ?	risus auctor
320	21 520,00 ?	ultrices phasellus
321	18 663,00 ?	amet
322	12 800,00 ?	libero non
323	10 291,00 ?	lectus
324	10 009,00 ?	quis libero
325	26 689,00 ?	placerat
326	14 111,00 ?	quam
327	37 446,00 ?	ut volutpat
328	30 737,00 ?	ipsum
329	25 937,00 ?	massa donec
330	10 052,00 ?	odio elementum
331	12 493,00 ?	mattis
332	16 472,00 ?	integer
333	5 349,00 ?	aliquam non
334	13 723,00 ?	ultrices posuere
335	23 615,00 ?	ultrices libero
336	33 773,00 ?	non
337	27 242,00 ?	nam
338	22 233,00 ?	quam sollicitudin
339	30 466,00 ?	praesent
340	25 923,00 ?	orci luctus
341	18 058,00 ?	arcu libero
342	30 847,00 ?	duis
343	27 020,00 ?	platea
344	14 539,00 ?	in
345	20 923,00 ?	rutrum
346	29 267,00 ?	sapien placerat
347	30 823,00 ?	cubilia
348	15 812,00 ?	vel
349	21 175,00 ?	sagittis dui
350	14 378,00 ?	ut
351	13 873,00 ?	ut tellus
352	18 482,00 ?	aliquam
353	7 927,00 ?	at
354	4 054,00 ?	odio porttitor
355	4 490,00 ?	magna ac
356	36 848,00 ?	faucibus orci
357	6 614,00 ?	non ligula
358	28 323,00 ?	lorem ipsum
359	3 152,00 ?	iaculis diam
360	38 956,00 ?	enim
361	18 777,00 ?	ipsum
362	28 600,00 ?	vestibulum sit
363	31 520,00 ?	eu
364	3 952,00 ?	ligula nec
365	32 347,00 ?	sed tristique
366	39 633,00 ?	velit
367	4 883,00 ?	duis ac
368	21 483,00 ?	tempor convallis
369	39 707,00 ?	massa
370	15 158,00 ?	quis
371	24 903,00 ?	nisl duis
372	20 798,00 ?	lacinia
373	6 197,00 ?	tristique fusce
374	18 475,00 ?	id
375	23 189,00 ?	curabitur
376	30 838,00 ?	feugiat
377	903,00 ?	magna ac
378	37 202,00 ?	bibendum imperdiet
379	5 572,00 ?	augue a
380	5 118,00 ?	sapien
381	28 082,00 ?	erat volutpat
382	18 526,00 ?	morbi quis
383	33 849,00 ?	curabitur convallis
384	11 056,00 ?	faucibus orci
385	15 798,00 ?	volutpat sapien
386	21 231,00 ?	aliquam non
387	16 475,00 ?	ac lobortis
388	37 145,00 ?	interdum in
389	9 207,00 ?	eleifend luctus
390	33 489,00 ?	consequat nulla
391	34 973,00 ?	turpis
392	34 024,00 ?	primis
393	25 715,00 ?	maecenas
394	26 242,00 ?	cursus
395	7 077,00 ?	metus
396	12 762,00 ?	vestibulum aliquet
397	12 473,00 ?	blandit ultrices
398	37 724,00 ?	cras pellentesque
399	35 444,00 ?	vel
400	34 067,00 ?	enim
401	31 797,00 ?	in ante
402	26 417,00 ?	risus praesent
403	25 901,00 ?	sed vel
404	34 160,00 ?	proin eu
405	30 582,00 ?	donec
406	22 935,00 ?	rutrum
407	27 191,00 ?	sit amet
408	31 150,00 ?	eu
409	30 049,00 ?	duis mattis
410	15 098,00 ?	duis consequat
411	2 450,00 ?	nec nisi
412	12 550,00 ?	aliquet at
413	33 378,00 ?	quis
414	38 515,00 ?	integer ac
415	18 517,00 ?	mi
416	18 973,00 ?	est
417	21 583,00 ?	id consequat
418	31 790,00 ?	turpis
419	22 117,00 ?	lacinia sapien
420	18 616,00 ?	magnis dis
421	20 092,00 ?	libero
422	7 280,00 ?	sit amet
423	21 378,00 ?	fusce
424	38 368,00 ?	duis
425	20 193,00 ?	phasellus sit
426	28 299,00 ?	congue
427	33 870,00 ?	non quam
428	21 906,00 ?	velit
429	12 714,00 ?	consequat morbi
430	36 209,00 ?	ante ipsum
431	15 087,00 ?	non
432	1 529,00 ?	aliquet
433	4 136,00 ?	pellentesque
434	8 986,00 ?	pulvinar nulla
435	29 975,00 ?	sit
436	5 618,00 ?	pulvinar
437	9 899,00 ?	tortor
438	16 606,00 ?	duis consequat
439	28 287,00 ?	non mi
440	3 357,00 ?	aliquam
441	19 634,00 ?	mus vivamus
442	18 344,00 ?	vulputate luctus
443	17 479,00 ?	donec ut
444	5 985,00 ?	nunc
445	29 926,00 ?	nulla sed
446	3 934,00 ?	eu
447	1 467,00 ?	neque libero
448	30 876,00 ?	nisi volutpat
449	32 341,00 ?	ac
450	15 699,00 ?	malesuada in
451	16 577,00 ?	odio
452	5 799,00 ?	lectus
453	1 652,00 ?	condimentum
454	19 937,00 ?	erat
455	6 842,00 ?	dignissim
456	20 858,00 ?	eget elit
457	9 613,00 ?	nulla quisque
458	21 821,00 ?	metus
459	6 620,00 ?	posuere
460	27 030,00 ?	pellentesque
461	7 242,00 ?	purus
462	9 639,00 ?	tempor turpis
463	36 119,00 ?	consectetuer
464	16 734,00 ?	eu magna
465	33 665,00 ?	scelerisque quam
466	33 022,00 ?	tempus
467	11 121,00 ?	habitasse platea
468	37 886,00 ?	volutpat
469	6 230,00 ?	quam
470	3 921,00 ?	fusce
471	36 399,00 ?	primis in
472	3 027,00 ?	sapien ut
473	25 096,00 ?	suspendisse potenti
474	28 971,00 ?	lorem
475	20 981,00 ?	rhoncus
476	39 475,00 ?	curabitur
477	15 983,00 ?	posuere
478	2 669,00 ?	tincidunt lacus
479	10 898,00 ?	nibh
480	34 428,00 ?	ante ipsum
481	26 644,00 ?	dolor
482	7 849,00 ?	et tempus
483	38 504,00 ?	tortor
484	38 322,00 ?	tortor
485	22 415,00 ?	non sodales
486	29 715,00 ?	nulla suspendisse
487	15 570,00 ?	tellus nisi
488	32 458,00 ?	lacinia
489	10 289,00 ?	etiam vel
490	6 166,00 ?	suspendisse ornare
491	11 244,00 ?	id pretium
492	8 810,00 ?	diam
493	6 047,00 ?	odio justo
494	32 956,00 ?	arcu sed
495	25 315,00 ?	tellus semper
496	15 932,00 ?	duis
497	39 206,00 ?	molestie
498	37 614,00 ?	dictumst
499	8 455,00 ?	convallis
500	34 345,00 ?	nisi
501	12 729,00 ?	eget vulputate
502	36 772,00 ?	bibendum imperdiet
503	519,00 ?	consequat lectus
504	22 431,00 ?	et
505	23 967,00 ?	curae
506	8 908,00 ?	fusce
507	9 641,00 ?	ornare consequat
508	34 275,00 ?	mi
509	14 854,00 ?	elementum
510	22 973,00 ?	donec
511	11 151,00 ?	quis
512	14 916,00 ?	vivamus tortor
513	22 892,00 ?	rhoncus aliquam
514	18 090,00 ?	fusce posuere
515	22 259,00 ?	nisl
516	13 163,00 ?	pede
517	16 720,00 ?	ante ipsum
518	7 546,00 ?	quis
519	16 533,00 ?	cum sociis
520	115,00 ?	cursus
521	1 622,00 ?	nunc rhoncus
522	30 845,00 ?	enim
523	25 824,00 ?	lacus at
524	18 012,00 ?	justo eu
525	26 663,00 ?	suspendisse ornare
526	37 026,00 ?	nulla ultrices
527	18 502,00 ?	fusce
528	15 136,00 ?	dui
529	31 120,00 ?	lectus pellentesque
530	19 303,00 ?	scelerisque
531	36 705,00 ?	magna vulputate
532	30 635,00 ?	tincidunt eu
533	27 051,00 ?	tempus semper
534	33 240,00 ?	odio donec
535	9 398,00 ?	in
536	27 043,00 ?	fermentum justo
537	37 444,00 ?	in
538	4 474,00 ?	lacus morbi
539	32 252,00 ?	amet
540	4 162,00 ?	a
541	12 136,00 ?	convallis
542	16 222,00 ?	sapien quis
543	14 618,00 ?	sit amet
544	20 783,00 ?	quisque
545	24 496,00 ?	quisque
546	3 203,00 ?	congue diam
547	4 307,00 ?	amet consectetuer
548	24 506,00 ?	diam
549	31 764,00 ?	etiam faucibus
550	29 279,00 ?	morbi quis
551	26 303,00 ?	phasellus id
552	10 449,00 ?	in
553	9 673,00 ?	ultrices posuere
554	31 134,00 ?	convallis
555	10 566,00 ?	massa
556	26 728,00 ?	condimentum
557	10 941,00 ?	praesent blandit
558	13 925,00 ?	duis at
559	16 216,00 ?	justo eu
560	9 209,00 ?	ultrices
561	14 263,00 ?	luctus
562	8 316,00 ?	vivamus
563	27 094,00 ?	nulla
564	176,00 ?	vel nulla
565	31 026,00 ?	varius integer
566	8 333,00 ?	erat id
567	23 785,00 ?	morbi non
568	24 907,00 ?	quis turpis
569	29 656,00 ?	quis turpis
570	10 877,00 ?	pellentesque
571	18 609,00 ?	dolor
572	3 986,00 ?	libero
573	1 167,00 ?	nonummy maecenas
574	23 763,00 ?	pellentesque ultrices
575	9 833,00 ?	lacus at
576	7 834,00 ?	sapien sapien
577	16 900,00 ?	a ipsum
578	12 253,00 ?	varius nulla
579	8 065,00 ?	luctus
580	14 766,00 ?	in
581	33 636,00 ?	dis parturient
582	28 510,00 ?	nullam varius
583	16 028,00 ?	nulla
584	15 803,00 ?	faucibus
585	11 576,00 ?	augue aliquam
586	1 767,00 ?	interdum mauris
587	39 169,00 ?	quam
588	39 641,00 ?	augue luctus
589	26 979,00 ?	vitae quam
590	8 670,00 ?	nascetur
591	38 938,00 ?	venenatis
592	1 715,00 ?	ultrices
593	7 068,00 ?	ligula
594	8 297,00 ?	velit
595	21 539,00 ?	duis bibendum
596	39 570,00 ?	ante
597	16 618,00 ?	orci
598	9 371,00 ?	cras mi
599	39 926,00 ?	eu pede
600	6 157,00 ?	at
601	26 592,00 ?	fusce
602	25 159,00 ?	sagittis
603	35 572,00 ?	pulvinar nulla
604	1 523,00 ?	proin
605	25 153,00 ?	tincidunt eget
606	25 798,00 ?	elementum
607	2 247,00 ?	volutpat convallis
608	14 002,00 ?	mi
609	21 221,00 ?	nascetur
610	23 361,00 ?	ac leo
611	7 543,00 ?	nascetur ridiculus
612	18 104,00 ?	integer a
613	34 125,00 ?	non quam
614	1 227,00 ?	sed sagittis
615	20 471,00 ?	integer ac
616	13 753,00 ?	donec odio
617	28 375,00 ?	rutrum ac
618	21 647,00 ?	varius
619	38 871,00 ?	semper porta
620	275,00 ?	elementum
621	10 411,00 ?	in ante
622	27 663,00 ?	interdum
623	16 956,00 ?	et ultrices
624	12 849,00 ?	sit amet
625	5 242,00 ?	est
626	11 461,00 ?	potenti
627	15 630,00 ?	imperdiet et
628	13 105,00 ?	quis tortor
629	11 968,00 ?	vestibulum
630	3 248,00 ?	curabitur convallis
631	18 827,00 ?	odio
632	19 940,00 ?	vel
633	30 596,00 ?	duis bibendum
634	11 164,00 ?	posuere
635	1 078,00 ?	diam erat
636	34 479,00 ?	tempus vivamus
637	3 665,00 ?	hendrerit at
638	9 568,00 ?	aenean lectus
639	7 908,00 ?	mauris
640	23 939,00 ?	sed
641	4 909,00 ?	donec vitae
642	9 280,00 ?	etiam
643	35 811,00 ?	commodo vulputate
644	11 210,00 ?	nascetur ridiculus
645	22 510,00 ?	pharetra magna
646	36 837,00 ?	libero non
647	6 366,00 ?	neque sapien
648	32 596,00 ?	erat eros
649	32 160,00 ?	fermentum
650	39 092,00 ?	penatibus
651	984,00 ?	velit donec
652	30 111,00 ?	erat nulla
653	11 721,00 ?	ut
654	26 338,00 ?	rutrum
655	25 533,00 ?	at
656	22 158,00 ?	id luctus
657	35 230,00 ?	venenatis
658	21 984,00 ?	vulputate
659	12 694,00 ?	erat fermentum
660	23 953,00 ?	odio donec
661	15 659,00 ?	duis
662	27 671,00 ?	odio curabitur
663	32 247,00 ?	orci
664	2 112,00 ?	quis turpis
665	22 281,00 ?	id ligula
666	24 639,00 ?	curabitur convallis
667	7 434,00 ?	orci
668	2 387,00 ?	et magnis
669	16 251,00 ?	suspendisse potenti
670	34 946,00 ?	et commodo
671	10 150,00 ?	eget
672	35 891,00 ?	fusce
673	4 365,00 ?	pretium iaculis
674	32 688,00 ?	ut
675	8 719,00 ?	integer
676	31 411,00 ?	augue vel
677	8 932,00 ?	nunc commodo
678	23 635,00 ?	condimentum
679	27 757,00 ?	in quam
680	16 925,00 ?	risus
681	7 573,00 ?	donec
682	31 076,00 ?	quis
683	24 023,00 ?	primis
684	149,00 ?	ipsum primis
685	21 804,00 ?	tortor
686	14 798,00 ?	duis
687	29 642,00 ?	laoreet
688	10 024,00 ?	nulla
689	5 574,00 ?	praesent blandit
690	36 223,00 ?	vestibulum ante
691	1 095,00 ?	natoque penatibus
692	9 896,00 ?	et
693	30 543,00 ?	venenatis
694	22 212,00 ?	luctus et
695	17 958,00 ?	ut
696	10 223,00 ?	posuere
697	7 277,00 ?	pulvinar
698	14 916,00 ?	consequat metus
699	8 882,00 ?	elit proin
700	34 892,00 ?	consequat
701	25 925,00 ?	cras
702	13 699,00 ?	quis
703	21 186,00 ?	odio cras
704	29 932,00 ?	dui maecenas
705	26 998,00 ?	dui
706	25 876,00 ?	duis
707	8 802,00 ?	vulputate
708	20 083,00 ?	pede
709	7 312,00 ?	ac
710	6 985,00 ?	metus sapien
711	195,00 ?	nam tristique
712	39 968,00 ?	pede
713	27 678,00 ?	quis
714	10 034,00 ?	metus aenean
715	8 960,00 ?	amet eros
716	22 746,00 ?	sed
717	20 682,00 ?	tempor
718	36 050,00 ?	adipiscing
719	16 906,00 ?	est
720	6 178,00 ?	turpis
721	34 287,00 ?	lectus
722	19 379,00 ?	amet
723	5 312,00 ?	elementum in
724	35 511,00 ?	leo
725	4 801,00 ?	massa
726	19 270,00 ?	maecenas
727	416,00 ?	erat
728	34 095,00 ?	non mauris
729	26 723,00 ?	in
730	335,00 ?	potenti in
731	31 643,00 ?	amet turpis
732	14 810,00 ?	curae
733	375,00 ?	ultrices enim
734	13 358,00 ?	quis orci
735	17 211,00 ?	vulputate
736	22 278,00 ?	donec
737	33 218,00 ?	posuere cubilia
738	2 845,00 ?	scelerisque quam
739	5 386,00 ?	ut at
740	24 556,00 ?	mauris
741	25 271,00 ?	odio porttitor
742	38 859,00 ?	id sapien
743	18 857,00 ?	quam suspendisse
744	18 076,00 ?	gravida nisi
745	12 114,00 ?	blandit
746	29 626,00 ?	vel nisl
747	27 199,00 ?	luctus ultricies
748	30 764,00 ?	hendrerit at
749	35 498,00 ?	tortor
750	1 678,00 ?	id
751	32 588,00 ?	nisl
752	27 593,00 ?	sit
753	19 216,00 ?	rutrum ac
754	21 225,00 ?	sagittis nam
755	12 319,00 ?	pellentesque quisque
756	18 656,00 ?	vel sem
757	15 845,00 ?	est
758	13 241,00 ?	nulla elit
759	21 558,00 ?	et ultrices
760	33 401,00 ?	justo
761	20 212,00 ?	mauris
762	7 476,00 ?	in faucibus
763	1 340,00 ?	dui
764	25 584,00 ?	elit
765	37 799,00 ?	sed tristique
766	15 777,00 ?	vestibulum
767	19 630,00 ?	feugiat non
768	7 312,00 ?	primis in
769	3 874,00 ?	orci nullam
770	31 608,00 ?	vitae
771	36 043,00 ?	aenean
772	38 319,00 ?	suspendisse potenti
773	37 391,00 ?	imperdiet
774	6 922,00 ?	eros
775	6 835,00 ?	id sapien
776	19 149,00 ?	ante
777	18 674,00 ?	semper est
778	1 121,00 ?	fermentum
779	39 440,00 ?	justo lacinia
780	27 772,00 ?	hac habitasse
781	35 469,00 ?	vivamus
782	12 992,00 ?	sapien
783	18 284,00 ?	ridiculus mus
784	25 985,00 ?	phasellus in
785	22 234,00 ?	lacus purus
786	21 009,00 ?	quis augue
787	12 767,00 ?	commodo vulputate
788	19 764,00 ?	et magnis
789	16 634,00 ?	hac
790	4 389,00 ?	eget congue
791	28 089,00 ?	gravida
792	24 502,00 ?	ipsum primis
793	21 062,00 ?	ultrices phasellus
794	34 615,00 ?	fusce
795	7 904,00 ?	eget
796	25 849,00 ?	pellentesque at
797	15 864,00 ?	cubilia curae
798	7 853,00 ?	a
799	29 437,00 ?	in
800	29 460,00 ?	pellentesque
801	6 967,00 ?	aliquet
802	1 224,00 ?	donec vitae
803	2 025,00 ?	fermentum
804	15 150,00 ?	id lobortis
805	37 814,00 ?	eleifend pede
806	26 371,00 ?	tempus sit
807	32 418,00 ?	augue vestibulum
808	38 887,00 ?	a ipsum
809	37 235,00 ?	ac tellus
810	3 865,00 ?	phasellus in
811	32 469,00 ?	sodales sed
812	28 974,00 ?	in
813	26 782,00 ?	vulputate
814	14 404,00 ?	pharetra magna
815	8 555,00 ?	sed
816	24 899,00 ?	turpis
817	5 748,00 ?	hac habitasse
818	18 244,00 ?	tortor quis
819	26 727,00 ?	quam
820	12 379,00 ?	massa volutpat
821	10 334,00 ?	nascetur ridiculus
822	26 486,00 ?	nulla
823	35 869,00 ?	metus
824	14 602,00 ?	nulla pede
825	16 126,00 ?	consequat ut
826	35 803,00 ?	integer
827	14 404,00 ?	elementum
828	18 458,00 ?	tincidunt in
829	13 660,00 ?	tincidunt ante
830	4 633,00 ?	feugiat
831	10 434,00 ?	magnis dis
832	22 316,00 ?	quisque arcu
833	31 069,00 ?	ligula
834	25 498,00 ?	integer tincidunt
835	10 404,00 ?	in
836	19 030,00 ?	nec nisi
837	7 976,00 ?	sollicitudin vitae
838	22 059,00 ?	in faucibus
839	24 090,00 ?	justo morbi
840	32 953,00 ?	orci eget
841	30 814,00 ?	hac
842	19 993,00 ?	nulla pede
843	34 502,00 ?	etiam
844	37 948,00 ?	elit sodales
845	5 692,00 ?	ligula sit
846	38 250,00 ?	eros viverra
847	23 114,00 ?	egestas metus
848	22 522,00 ?	fusce posuere
849	30 911,00 ?	eget
850	20 283,00 ?	suspendisse
851	17 134,00 ?	vestibulum
852	35 609,00 ?	non
853	6 202,00 ?	parturient montes
854	20 414,00 ?	integer
855	33 733,00 ?	lobortis
856	23 574,00 ?	turpis adipiscing
857	11 759,00 ?	porttitor id
858	5 413,00 ?	hendrerit at
859	11 357,00 ?	quam
860	1 683,00 ?	at lorem
861	23 096,00 ?	in
862	24 569,00 ?	rhoncus
863	28 009,00 ?	tellus
864	17 839,00 ?	pulvinar
865	38 898,00 ?	pellentesque
866	9 847,00 ?	duis
867	34 384,00 ?	nisi
868	14 048,00 ?	amet
869	34 282,00 ?	vestibulum
870	7 686,00 ?	sagittis sapien
871	1 253,00 ?	tristique est
872	24 546,00 ?	at
873	39 467,00 ?	pellentesque viverra
874	7 966,00 ?	diam
875	18 528,00 ?	vivamus
876	9 251,00 ?	ipsum
877	29 914,00 ?	eget
878	20 937,00 ?	convallis
879	12 454,00 ?	mattis
880	3 210,00 ?	maecenas
881	4 794,00 ?	posuere
882	21 393,00 ?	quis
883	30 822,00 ?	gravida
884	35 779,00 ?	purus phasellus
885	7 926,00 ?	iaculis
886	6 593,00 ?	a nibh
887	17 177,00 ?	tortor eu
888	17 130,00 ?	in faucibus
889	19 052,00 ?	in imperdiet
890	39 147,00 ?	cursus
891	38 640,00 ?	at
892	32 950,00 ?	in
893	4 280,00 ?	ligula
894	28 629,00 ?	eu
895	2 554,00 ?	neque libero
896	20 107,00 ?	quis
897	32 231,00 ?	eleifend donec
898	19 126,00 ?	ut mauris
899	38 455,00 ?	nibh
900	23 288,00 ?	integer non
901	25 611,00 ?	quisque
902	7 127,00 ?	auctor
903	26 690,00 ?	sem
904	6 303,00 ?	auctor sed
905	10 006,00 ?	molestie sed
906	17 419,00 ?	nam
907	22 566,00 ?	sapien
908	28 486,00 ?	neque vestibulum
909	28 079,00 ?	id
910	25 190,00 ?	in faucibus
911	30 288,00 ?	gravida sem
912	18 670,00 ?	mattis odio
913	8 996,00 ?	phasellus
914	14 877,00 ?	nunc
915	23 162,00 ?	elementum
916	31 083,00 ?	nonummy
917	31 827,00 ?	quisque erat
918	18 665,00 ?	ac
919	26 486,00 ?	accumsan
920	25 057,00 ?	odio
921	21 228,00 ?	elementum pellentesque
922	27 442,00 ?	vestibulum
923	34 366,00 ?	quis
924	35 989,00 ?	augue
925	31 059,00 ?	massa
926	13 656,00 ?	ut dolor
927	27 069,00 ?	id
928	12 295,00 ?	molestie
929	11 710,00 ?	nulla suspendisse
930	33 127,00 ?	montes nascetur
931	39 444,00 ?	in
932	4 421,00 ?	lobortis
933	30 997,00 ?	quam
934	17 152,00 ?	nisi vulputate
935	13 240,00 ?	nisi nam
936	7 647,00 ?	duis bibendum
937	35 989,00 ?	morbi
938	25 439,00 ?	viverra pede
939	24 331,00 ?	dictumst maecenas
940	27 005,00 ?	condimentum neque
941	11 858,00 ?	facilisi
942	38 690,00 ?	purus eu
943	1 533,00 ?	platea dictumst
944	10 827,00 ?	ut nunc
945	38 214,00 ?	commodo
946	21 339,00 ?	malesuada in
947	24 633,00 ?	placerat ante
948	22 233,00 ?	proin
949	18 896,00 ?	tortor duis
950	29 827,00 ?	nulla facilisi
951	37 315,00 ?	maecenas leo
952	34 523,00 ?	dis parturient
953	38 142,00 ?	pellentesque
954	35 258,00 ?	neque
955	14 529,00 ?	nullam
956	6 565,00 ?	justo in
957	121,00 ?	nam nulla
958	29 480,00 ?	adipiscing lorem
959	13 892,00 ?	volutpat sapien
960	17 162,00 ?	congue diam
961	22 988,00 ?	congue risus
962	15 959,00 ?	vitae quam
963	10 681,00 ?	sit amet
964	13 263,00 ?	lectus
965	30 330,00 ?	nisl aenean
966	33 181,00 ?	iaculis
967	21 814,00 ?	quam turpis
968	37 677,00 ?	suscipit
969	25 242,00 ?	ipsum
970	1 762,00 ?	donec ut
971	18 443,00 ?	metus sapien
972	27 872,00 ?	ultrices enim
973	39 380,00 ?	sapien ut
974	7 857,00 ?	pede ullamcorper
975	16 907,00 ?	mauris lacinia
976	26 544,00 ?	tellus
977	597,00 ?	non
978	32 572,00 ?	placerat
979	1 096,00 ?	elementum nullam
980	382,00 ?	mi sit
981	38 208,00 ?	vulputate luctus
982	12 985,00 ?	ultrices posuere
983	20 345,00 ?	ante ipsum
984	36 208,00 ?	sodales sed
985	789,00 ?	sapien arcu
986	6 164,00 ?	semper rutrum
987	35 981,00 ?	orci
988	10 214,00 ?	eget orci
989	32 663,00 ?	nisl ut
990	17 070,00 ?	sed augue
991	18 385,00 ?	sapien
992	11 621,00 ?	est phasellus
993	4 710,00 ?	luctus cum
994	29 579,00 ?	sed ante
995	20 306,00 ?	accumsan
996	22 340,00 ?	sapien
997	12 456,00 ?	dui maecenas
998	14 642,00 ?	et tempus
999	38 826,00 ?	dolor
1000	33 965,00 ?	semper
\.


--
-- TOC entry 3165 (class 0 OID 16437)
-- Dependencies: 203
-- Data for Name: medicine_form; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.medicine_form (id, name) FROM stdin;
1	Сухое ЛС
2	Жидкое ЛС
3	Готовое ЛС
4	Товары санитарной гигиены
5	Перевязочные материалы
6	Наркотические ЛС
7	Яды
\.


--
-- TOC entry 3173 (class 0 OID 16479)
-- Dependencies: 211
-- Data for Name: pharmacological_group; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.pharmacological_group (id, name) FROM stdin;
1	Вегетотропные средства
2	Гематотропные средства
3	Гормоны и их антагонисты
4	Диагностические средства
5	Иммунотропные препараты
6	Интермедианты
7	Метаболики
8	Нейротропные средства
9	Органотропные средства
10	Противомикробные средства
11	Противоопухолевые средства
12	Наркотические анальгетики
\.


--
-- TOC entry 3163 (class 0 OID 16429)
-- Dependencies: 201
-- Data for Name: pharmacy_warhouse; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.pharmacy_warhouse (id, opening_hours, address) FROM stdin;
5	10:00-22:00	ул. Проспект им. Ленина, д. 53а
9	11:00-14:00	ул. Проспект им. Ленина, д. 6
1	08:00-20:00	ул. Генерала Штеменко, д. 2Б
2	07:00-20:00	ул. Репина, д. 11а
3	07:00-21:00	ул. Качалова, д. 46
4	08:00-18:00	ул. Хользунова, д. 33
6	06:00-16:00	ул. Проспект им. Ленина, д. 28
7	08:00-20:00	ул. Комсольская, д. 6
8	07:00-20:00	ул. Михаила Балонина, д. 11
10	04:00-14:00	ул. Маршала Рокоссовского, д. 50
11	13:00-02:00	077 Loomis Terrace
12	08:00-20:00	0 Lotheville Trail
13	09:00-19:00	28559 Shasta Avenue
14	09:00-19:00	08 Almo Pass
15	08:00-20:00	264 Arrowood Plaza
16	06:00-22:00	394 Stone Corner Terrace
17	08:00-20:00	89683 Loftsgordon Court
18	09:00-19:00	945 Nobel Alley
19	06:00-22:00	1 Blaine Lane
20	09:00-19:00	9129 Pennsylvania Circle
21	06:00-22:00	84914 Fulton Alley
22	08:00-20:00	3 Tony Road
23	06:00-22:00	4 Forster Center
24	06:00-22:00	47508 Stuart Road
25	09:00-19:00	58 Stang Alley
26	13:00-02:00	72474 Maple Wood Hill
27	06:00-22:00	5343 Everett Road
28	13:00-02:00	2863 Sachtjen Point
29	09:00-19:00	48520 Sunbrook Place
30	06:00-22:00	76663 Northwestern Circle
31	06:00-22:00	36 Aberg Terrace
32	08:00-20:00	07049 Becker Park
33	09:00-19:00	022 Manufacturers Pass
34	08:00-20:00	4 Stuart Point
35	13:00-02:00	4 Burrows Point
36	13:00-02:00	850 Portage Drive
37	09:00-19:00	0715 Luster Terrace
38	13:00-02:00	5 Bunting Place
39	08:00-20:00	9 Norway Maple Alley
40	08:00-20:00	83 Anderson Alley
41	09:00-19:00	049 Del Sol Plaza
42	06:00-22:00	4 Comanche Circle
43	06:00-22:00	785 Springview Street
44	13:00-02:00	9402 3rd Lane
45	09:00-19:00	079 Acker Hill
46	08:00-20:00	919 Starling Park
47	06:00-22:00	70414 Forest Run Street
48	09:00-19:00	6 Lien Plaza
49	13:00-02:00	0 Oxford Court
50	08:00-20:00	65910 Longview Circle
51	13:00-02:00	2224 Rowland Trail
52	13:00-02:00	2 Glendale Alley
53	08:00-20:00	50659 Spohn Plaza
54	06:00-22:00	8932 Caliangt Crossing
55	13:00-02:00	585 Portage Plaza
56	06:00-22:00	0634 Pennsylvania Junction
57	08:00-20:00	2 Shoshone Terrace
58	13:00-02:00	59 Scoville Court
59	06:00-22:00	05 Heath Court
60	06:00-22:00	90 Utah Drive
61	09:00-19:00	713 Hintze Pass
62	08:00-20:00	2 Granby Street
63	13:00-02:00	8592 Mallory Court
64	08:00-20:00	463 Dovetail Circle
65	13:00-02:00	6623 Northport Place
66	06:00-22:00	0 Meadow Vale Trail
67	13:00-02:00	0542 Welch Park
68	09:00-19:00	186 Superior Drive
69	06:00-22:00	50 Debra Parkway
70	08:00-20:00	041 Delaware Road
71	09:00-19:00	27 Derek Road
72	09:00-19:00	0 Pierstorff Road
73	13:00-02:00	223 Moose Way
74	08:00-20:00	97685 Chive Point
75	08:00-20:00	898 Golf View Plaza
76	06:00-22:00	7029 Nova Street
77	08:00-20:00	819 Haas Center
78	09:00-19:00	0 Killdeer Plaza
79	13:00-02:00	7742 Dakota Center
80	08:00-20:00	99 Springview Parkway
81	13:00-02:00	776 Kenwood Street
82	09:00-19:00	237 Jackson Junction
83	13:00-02:00	5956 Gateway Terrace
84	13:00-02:00	4957 Dixon Road
85	06:00-22:00	43334 Mendota Avenue
86	06:00-22:00	4972 Bartelt Lane
87	13:00-02:00	7 Old Gate Trail
88	09:00-19:00	314 Rigney Junction
89	06:00-22:00	4 Luster Road
90	13:00-02:00	48478 Eggendart Center
91	13:00-02:00	02529 Miller Pass
92	09:00-19:00	55499 Amoth Street
93	06:00-22:00	54 Bluestem Pass
94	08:00-20:00	0 Dovetail Alley
95	08:00-20:00	38145 Erie Crossing
96	13:00-02:00	38571 Maple Wood Place
97	09:00-19:00	8694 Village Street
98	08:00-20:00	936 Westport Lane
99	06:00-22:00	48534 Coolidge Place
100	09:00-19:00	680 Towne Point
101	06:00-22:00	20 Dennis Road
102	13:00-02:00	857 Ruskin Trail
103	13:00-02:00	50315 Pankratz Junction
104	13:00-02:00	3 Rutledge Court
105	09:00-19:00	693 Claremont Terrace
106	06:00-22:00	6 Onsgard Crossing
107	13:00-02:00	7 Waywood Crossing
108	06:00-22:00	93 Cordelia Road
109	09:00-19:00	3787 Parkside Park
110	06:00-22:00	86 Nancy Place
111	06:00-22:00	951 Katie Road
112	08:00-20:00	6477 Kensington Road
113	08:00-20:00	5 Veith Parkway
114	13:00-02:00	4 Sauthoff Place
115	08:00-20:00	80818 Sutteridge Crossing
116	09:00-19:00	50623 Hovde Center
117	08:00-20:00	665 Kingsford Avenue
118	08:00-20:00	3 Eggendart Junction
119	13:00-02:00	90382 Barnett Alley
120	06:00-22:00	5020 Cordelia Street
121	13:00-02:00	429 Loomis Plaza
122	08:00-20:00	49 Rusk Plaza
123	08:00-20:00	6894 Westend Way
124	09:00-19:00	22 Melody Avenue
125	06:00-22:00	861 Erie Lane
126	06:00-22:00	8 Raven Street
127	13:00-02:00	75 Melby Drive
128	06:00-22:00	200 Esker Road
129	13:00-02:00	180 Heath Court
130	08:00-20:00	8 Buell Street
131	06:00-22:00	475 Gateway Road
132	08:00-20:00	015 Dakota Place
133	06:00-22:00	04 Southridge Road
134	08:00-20:00	1 Monica Point
135	13:00-02:00	9 Goodland Alley
136	09:00-19:00	13 Lyons Way
137	09:00-19:00	938 Thierer Drive
138	13:00-02:00	07535 Namekagon Park
139	09:00-19:00	0 Sachs Park
140	09:00-19:00	19134 Elgar Drive
141	13:00-02:00	676 Bunting Plaza
142	09:00-19:00	8 School Parkway
143	13:00-02:00	6 Laurel Terrace
144	08:00-20:00	05 Merchant Pass
145	06:00-22:00	4663 Coleman Park
146	06:00-22:00	14387 Bluejay Plaza
147	09:00-19:00	185 Nelson Plaza
148	06:00-22:00	572 Prairie Rose Parkway
149	08:00-20:00	79189 Mccormick Road
150	08:00-20:00	99590 Wayridge Crossing
151	13:00-02:00	6350 Commercial Junction
152	13:00-02:00	3 Crest Line Drive
153	06:00-22:00	10 Logan Lane
154	09:00-19:00	18547 International Drive
155	13:00-02:00	63757 Huxley Lane
156	09:00-19:00	4 Calypso Drive
157	08:00-20:00	2940 Elka Terrace
158	08:00-20:00	7 Hayes Crossing
159	08:00-20:00	966 Muir Alley
160	09:00-19:00	2 Main Alley
161	09:00-19:00	74769 Buell Avenue
162	06:00-22:00	2603 Lakewood Hill
163	13:00-02:00	3 Bobwhite Way
164	09:00-19:00	32 Emmet Road
165	13:00-02:00	5 Mockingbird Street
166	06:00-22:00	020 Holmberg Circle
167	08:00-20:00	49637 Gerald Terrace
168	06:00-22:00	0366 Meadow Valley Street
169	08:00-20:00	9215 Banding Circle
170	08:00-20:00	15 Old Gate Center
171	08:00-20:00	7 Darwin Hill
172	06:00-22:00	06 Dayton Point
173	06:00-22:00	0662 Mandrake Lane
174	08:00-20:00	2 Prentice Plaza
175	08:00-20:00	58 Nelson Plaza
176	08:00-20:00	2 Mayer Terrace
177	08:00-20:00	11282 Cottonwood Trail
178	09:00-19:00	785 Jenna Road
179	13:00-02:00	275 Mayfield Plaza
180	06:00-22:00	57 Erie Pass
181	09:00-19:00	70 Fair Oaks Avenue
182	13:00-02:00	584 Oak Valley Center
183	08:00-20:00	7 Twin Pines Junction
184	13:00-02:00	09087 Gina Point
185	06:00-22:00	30035 Saint Paul Avenue
186	09:00-19:00	181 Porter Trail
187	13:00-02:00	6 Village Way
188	06:00-22:00	35265 Arizona Center
189	09:00-19:00	2878 Bunker Hill Junction
190	13:00-02:00	1 Birchwood Park
191	09:00-19:00	81 Maple Wood Circle
192	09:00-19:00	65386 Menomonie Road
193	06:00-22:00	5 Melrose Lane
194	06:00-22:00	71 Hermina Center
195	08:00-20:00	02889 Menomonie Park
196	08:00-20:00	8938 Pankratz Center
197	06:00-22:00	7016 Sachs Drive
198	13:00-02:00	1 Kipling Street
199	13:00-02:00	61720 Montana Hill
200	13:00-02:00	6890 Swallow Road
201	06:00-22:00	9 Oak Valley Avenue
202	09:00-19:00	0 Upham Point
203	06:00-22:00	8760 Charing Cross Alley
204	06:00-22:00	06377 Kropf Junction
205	13:00-02:00	5 Buena Vista Alley
206	09:00-19:00	30 Carpenter Alley
207	13:00-02:00	96 Mitchell Park
208	09:00-19:00	163 Graedel Park
209	06:00-22:00	0 School Pass
210	13:00-02:00	374 Sage Terrace
211	09:00-19:00	50909 Eagan Park
212	13:00-02:00	82182 Melody Pass
213	08:00-20:00	14199 Shasta Pass
214	06:00-22:00	2 Manitowish Hill
215	09:00-19:00	63178 Vernon Terrace
216	13:00-02:00	38390 Northwestern Way
217	09:00-19:00	67897 Meadow Vale Terrace
218	09:00-19:00	225 Huxley Parkway
219	09:00-19:00	72 Magdeline Plaza
220	09:00-19:00	96 Northland Lane
221	13:00-02:00	5 Straubel Place
222	09:00-19:00	0 Muir Street
223	06:00-22:00	56 Sherman Plaza
224	08:00-20:00	5 Fuller Pass
225	09:00-19:00	12719 Anzinger Point
226	13:00-02:00	62970 Novick Road
227	06:00-22:00	352 Sommers Terrace
228	08:00-20:00	1 Mccormick Circle
229	09:00-19:00	02 2nd Circle
230	06:00-22:00	1368 Maple Street
231	13:00-02:00	1251 Bashford Way
232	09:00-19:00	807 Oriole Trail
233	13:00-02:00	5006 Melrose Hill
234	13:00-02:00	57 Crescent Oaks Lane
235	13:00-02:00	3969 Mcbride Crossing
236	13:00-02:00	3480 Towne Junction
237	13:00-02:00	5 Del Mar Plaza
238	06:00-22:00	328 Union Point
239	13:00-02:00	41349 Donald Court
240	09:00-19:00	731 Hanover Pass
241	13:00-02:00	932 Ilene Lane
242	09:00-19:00	16 Heath Junction
243	06:00-22:00	625 Cottonwood Pass
244	06:00-22:00	3696 Schurz Parkway
245	13:00-02:00	9 Manley Drive
246	09:00-19:00	89 Bashford Way
247	08:00-20:00	080 Linden Junction
248	06:00-22:00	8288 Butternut Park
249	09:00-19:00	56635 Crowley Terrace
250	08:00-20:00	257 Grim Crossing
251	08:00-20:00	53898 Maple Wood Hill
252	06:00-22:00	1 Kings Parkway
253	08:00-20:00	7 Del Mar Terrace
254	06:00-22:00	2861 David Circle
255	09:00-19:00	351 Brentwood Crossing
256	09:00-19:00	1 Birchwood Terrace
257	09:00-19:00	3591 Coolidge Terrace
258	08:00-20:00	3131 Waywood Circle
259	06:00-22:00	19 Sugar Alley
260	08:00-20:00	29 Mockingbird Parkway
261	13:00-02:00	810 Roth Terrace
262	06:00-22:00	5 Karstens Trail
263	13:00-02:00	1 Lake View Crossing
264	09:00-19:00	57515 Division Pass
265	08:00-20:00	5802 School Street
266	09:00-19:00	6672 Forest Dale Junction
267	06:00-22:00	6390 Vermont Court
268	08:00-20:00	0 Anzinger Avenue
269	13:00-02:00	0676 Judy Point
270	13:00-02:00	79 Sullivan Hill
271	09:00-19:00	47028 Toban Street
272	09:00-19:00	74 Hoard Parkway
273	08:00-20:00	6 Evergreen Road
274	13:00-02:00	2 Banding Alley
275	09:00-19:00	712 Bellgrove Hill
276	13:00-02:00	0 Goodland Center
277	13:00-02:00	40968 Roth Plaza
278	06:00-22:00	1 Melvin Circle
279	08:00-20:00	3183 Bunting Trail
280	08:00-20:00	597 New Castle Road
281	06:00-22:00	7 Tennyson Plaza
282	06:00-22:00	48 Lakeland Center
283	13:00-02:00	88587 Anderson Pass
284	09:00-19:00	44 Fairfield Drive
285	13:00-02:00	9 Orin Parkway
286	13:00-02:00	07324 Utah Trail
287	09:00-19:00	278 Graceland Plaza
288	08:00-20:00	38 Farragut Crossing
289	08:00-20:00	77965 Oneill Pass
290	13:00-02:00	63 Coolidge Circle
291	06:00-22:00	3748 Emmet Street
292	08:00-20:00	994 International Trail
293	09:00-19:00	4 Fairfield Drive
294	06:00-22:00	9 Milwaukee Street
295	13:00-02:00	3644 Dayton Way
296	08:00-20:00	82 Shasta Hill
297	06:00-22:00	30185 Clarendon Road
298	13:00-02:00	5355 4th Circle
299	06:00-22:00	9 Erie Pass
300	09:00-19:00	67 5th Crossing
301	13:00-02:00	9 Rusk Terrace
302	13:00-02:00	7 Warbler Crossing
303	08:00-20:00	73 Mitchell Center
304	09:00-19:00	7 Northwestern Junction
305	13:00-02:00	973 Elmside Crossing
306	08:00-20:00	2 Union Way
307	08:00-20:00	78 Kings Street
308	13:00-02:00	05 Farwell Alley
309	13:00-02:00	3 Autumn Leaf Parkway
310	09:00-19:00	1 Debra Terrace
311	08:00-20:00	7575 Goodland Hill
312	13:00-02:00	9 Helena Point
313	13:00-02:00	136 3rd Plaza
314	09:00-19:00	9 Buena Vista Plaza
315	06:00-22:00	3625 Riverside Lane
316	09:00-19:00	522 Melvin Place
317	09:00-19:00	94465 Katie Point
318	06:00-22:00	27 Knutson Center
319	13:00-02:00	865 Cody Center
320	13:00-02:00	31109 Red Cloud Park
321	06:00-22:00	06625 Veith Street
322	08:00-20:00	0 Melrose Way
323	09:00-19:00	66 Kinsman Drive
324	13:00-02:00	4 Eggendart Plaza
325	09:00-19:00	204 Lotheville Way
326	09:00-19:00	32204 Nelson Avenue
327	06:00-22:00	9518 Sunfield Park
328	06:00-22:00	413 Bunting Terrace
329	06:00-22:00	404 Texas Court
330	09:00-19:00	2357 Maple Trail
331	09:00-19:00	58803 Maple Wood Terrace
332	08:00-20:00	07477 Farragut Road
333	06:00-22:00	38 Hazelcrest Junction
334	13:00-02:00	7 Dovetail Avenue
335	08:00-20:00	86 Starling Center
336	09:00-19:00	0725 Corscot Way
337	08:00-20:00	05703 Ryan Plaza
338	09:00-19:00	08318 Dapin Way
339	09:00-19:00	81 Lake View Pass
340	08:00-20:00	7680 Roth Parkway
341	06:00-22:00	918 Maple Wood Street
342	09:00-19:00	67 Meadow Ridge Place
343	09:00-19:00	42 Waubesa Place
344	13:00-02:00	12581 Monterey Trail
345	13:00-02:00	11480 Anthes Hill
346	06:00-22:00	58888 Ridge Oak Lane
347	09:00-19:00	25 Sachs Terrace
348	09:00-19:00	5 Colorado Way
349	08:00-20:00	78634 Express Parkway
350	13:00-02:00	030 Lighthouse Bay Court
351	06:00-22:00	42 Hoard Hill
352	06:00-22:00	02 Graceland Trail
353	06:00-22:00	681 Luster Plaza
354	06:00-22:00	3578 Blackbird Crossing
355	06:00-22:00	05758 2nd Point
356	06:00-22:00	60660 Brown Lane
357	09:00-19:00	39451 Norway Maple Alley
358	08:00-20:00	766 Waubesa Way
359	06:00-22:00	1 Boyd Lane
360	13:00-02:00	738 Oakridge Point
361	09:00-19:00	95 Sullivan Point
362	09:00-19:00	2122 Melody Point
363	09:00-19:00	3405 Fieldstone Crossing
364	13:00-02:00	4460 Commercial Center
365	06:00-22:00	35 Dunning Drive
366	06:00-22:00	1 Oriole Street
367	13:00-02:00	688 Darwin Terrace
368	13:00-02:00	87793 Glendale Circle
369	06:00-22:00	0 Barnett Center
370	09:00-19:00	8234 Green Ridge Trail
371	09:00-19:00	617 Knutson Parkway
372	09:00-19:00	1 Nelson Circle
373	13:00-02:00	15 Lillian Way
374	06:00-22:00	5 Karstens Plaza
375	09:00-19:00	49 Arapahoe Crossing
376	06:00-22:00	344 Golf View Avenue
377	08:00-20:00	48053 Elmside Center
378	06:00-22:00	09075 Center Drive
379	13:00-02:00	98501 Bluejay Road
380	09:00-19:00	098 Declaration Drive
381	13:00-02:00	47100 Oxford Avenue
382	08:00-20:00	8 Rieder Alley
383	06:00-22:00	884 Blaine Place
384	09:00-19:00	82 Everett Drive
385	08:00-20:00	99 Sauthoff Lane
386	13:00-02:00	0555 Thompson Circle
387	08:00-20:00	38036 Lyons Avenue
388	09:00-19:00	21090 Alpine Point
389	08:00-20:00	67507 Morningstar Parkway
390	08:00-20:00	8 Longview Junction
391	13:00-02:00	4778 Mendota Hill
392	06:00-22:00	23808 Lindbergh Alley
393	06:00-22:00	385 Hooker Court
394	06:00-22:00	19211 Little Fleur Park
395	08:00-20:00	481 Crownhardt Place
396	06:00-22:00	7749 East Circle
397	13:00-02:00	3782 American Ash Pass
398	06:00-22:00	523 Merry Parkway
399	13:00-02:00	584 Golf Terrace
400	06:00-22:00	272 Melvin Hill
401	09:00-19:00	0899 Portage Drive
402	13:00-02:00	6531 Oakridge Center
403	06:00-22:00	291 Green Drive
404	13:00-02:00	924 Sachs Lane
405	13:00-02:00	717 Rockefeller Place
406	06:00-22:00	227 Oriole Street
407	06:00-22:00	70819 Manley Lane
408	09:00-19:00	4 Independence Trail
409	09:00-19:00	3701 Nova Alley
410	13:00-02:00	5803 Meadow Ridge Avenue
411	09:00-19:00	9 Northview Pass
412	08:00-20:00	4 Gulseth Center
413	13:00-02:00	37 Burning Wood Crossing
414	13:00-02:00	22975 Acker Park
415	06:00-22:00	17 Twin Pines Plaza
416	13:00-02:00	9519 Corry Circle
417	13:00-02:00	1 Brickson Park Parkway
418	08:00-20:00	401 Colorado Drive
419	09:00-19:00	4 Warbler Trail
420	09:00-19:00	91534 Pine View Pass
421	06:00-22:00	4 Ramsey Alley
422	09:00-19:00	54928 Prairieview Place
423	09:00-19:00	53904 Waxwing Center
424	08:00-20:00	8 Petterle Parkway
425	06:00-22:00	40 Larry Point
426	06:00-22:00	74519 Meadow Valley Road
427	09:00-19:00	81295 Nelson Junction
428	09:00-19:00	497 Corben Park
429	06:00-22:00	73225 Hoffman Avenue
430	13:00-02:00	7 Killdeer Crossing
431	08:00-20:00	87 Fulton Parkway
432	09:00-19:00	63 Iowa Parkway
433	08:00-20:00	96 Bowman Street
434	13:00-02:00	40 Moulton Parkway
435	13:00-02:00	35 Monument Street
436	08:00-20:00	093 Columbus Avenue
437	09:00-19:00	0 Laurel Point
438	13:00-02:00	4251 Pleasure Place
439	09:00-19:00	00893 Dapin Place
440	09:00-19:00	06 5th Crossing
441	09:00-19:00	96 Upham Alley
442	13:00-02:00	582 Oriole Alley
443	06:00-22:00	6466 Arapahoe Pass
444	06:00-22:00	5 Victoria Lane
445	08:00-20:00	91 Cardinal Park
446	08:00-20:00	125 2nd Junction
447	08:00-20:00	40669 Warbler Point
448	13:00-02:00	807 Lien Road
449	08:00-20:00	584 Bellgrove Drive
450	13:00-02:00	69392 Boyd Center
451	09:00-19:00	4 Old Shore Park
452	06:00-22:00	9395 Maywood Parkway
453	06:00-22:00	93913 School Plaza
454	13:00-02:00	72485 Helena Park
455	13:00-02:00	60 Manitowish Plaza
456	06:00-22:00	66349 Gerald Road
457	13:00-02:00	8 Nancy Place
458	06:00-22:00	10 Scoville Parkway
459	13:00-02:00	57 Twin Pines Point
460	09:00-19:00	18367 Village Green Center
461	13:00-02:00	3 Hoard Place
462	13:00-02:00	43 Moulton Lane
463	13:00-02:00	7 Ilene Street
464	13:00-02:00	69629 Grim Street
465	09:00-19:00	92461 Butternut Point
466	06:00-22:00	2995 Valley Edge Trail
467	13:00-02:00	7 Pierstorff Court
468	09:00-19:00	68028 Canary Park
469	13:00-02:00	583 Michigan Crossing
470	06:00-22:00	01 Fisk Trail
471	06:00-22:00	5950 Rutledge Road
472	13:00-02:00	0 Forest Dale Street
473	09:00-19:00	095 Kipling Hill
474	08:00-20:00	254 Sullivan Road
475	08:00-20:00	8 Harbort Pass
476	08:00-20:00	42 Ruskin Alley
477	09:00-19:00	3747 Ronald Regan Terrace
478	08:00-20:00	0381 Maple Terrace
479	08:00-20:00	4 Graceland Circle
480	09:00-19:00	815 Westridge Place
481	08:00-20:00	341 Crownhardt Plaza
482	06:00-22:00	10421 Dexter Road
483	08:00-20:00	915 Emmet Center
484	13:00-02:00	9076 Stuart Terrace
485	06:00-22:00	385 Buell Way
486	09:00-19:00	56482 Northridge Point
487	08:00-20:00	21964 Glacier Hill Park
488	09:00-19:00	0 Eastwood Point
489	09:00-19:00	3378 Lillian Lane
490	06:00-22:00	430 Monterey Trail
491	09:00-19:00	3 Reindahl Point
492	13:00-02:00	0 Main Way
493	13:00-02:00	096 Sullivan Crossing
494	06:00-22:00	06 Lakewood Center
495	06:00-22:00	41 Tennessee Drive
496	13:00-02:00	6119 Bunker Hill Junction
497	13:00-02:00	4219 Sommers Parkway
498	06:00-22:00	8393 Gerald Road
499	08:00-20:00	706 Bashford Court
500	06:00-22:00	98204 Claremont Place
501	06:00-22:00	704 Logan Avenue
502	06:00-22:00	097 Surrey Parkway
503	09:00-19:00	46 Portage Park
504	13:00-02:00	5929 Hermina Street
505	08:00-20:00	80 Summer Ridge Trail
506	13:00-02:00	547 Sutherland Plaza
507	06:00-22:00	0241 Moland Parkway
508	06:00-22:00	4249 Continental Drive
509	09:00-19:00	20 Farragut Street
510	08:00-20:00	415 Karstens Road
511	13:00-02:00	28 Leroy Court
512	06:00-22:00	0916 Dottie Pass
513	13:00-02:00	85464 Acker Court
514	06:00-22:00	12452 Prairieview Road
515	08:00-20:00	9 Lakewood Junction
516	08:00-20:00	97730 Anniversary Circle
517	06:00-22:00	34496 Northview Road
518	09:00-19:00	573 Sommers Parkway
519	09:00-19:00	9939 Sheridan Junction
520	09:00-19:00	4 Kim Place
521	09:00-19:00	2400 Lawn Drive
522	13:00-02:00	2 Cody Way
523	13:00-02:00	721 Dennis Hill
524	13:00-02:00	692 Fieldstone Junction
525	13:00-02:00	24984 Walton Junction
526	13:00-02:00	300 Bluejay Plaza
527	09:00-19:00	30 Meadow Ridge Pass
528	09:00-19:00	16 Northwestern Street
529	08:00-20:00	61731 Talisman Alley
530	08:00-20:00	760 Golf Parkway
531	09:00-19:00	15742 Charing Cross Junction
532	13:00-02:00	883 Sachs Way
533	06:00-22:00	090 Old Shore Parkway
534	13:00-02:00	4743 Bobwhite Parkway
535	09:00-19:00	1 Vahlen Junction
536	09:00-19:00	68366 Hermina Point
537	06:00-22:00	3 Maryland Terrace
538	09:00-19:00	876 Corscot Crossing
539	09:00-19:00	21033 Hoffman Center
540	08:00-20:00	48464 Fairview Drive
541	06:00-22:00	73 Clove Parkway
542	13:00-02:00	36 Delaware Alley
543	06:00-22:00	14136 Veith Terrace
544	06:00-22:00	27087 Daystar Court
545	08:00-20:00	1467 Gateway Avenue
546	09:00-19:00	12 Manufacturers Terrace
547	06:00-22:00	95016 Merchant Crossing
548	06:00-22:00	2239 Surrey Hill
549	06:00-22:00	062 Warrior Hill
550	08:00-20:00	10 Sherman Hill
551	08:00-20:00	769 Charing Cross Avenue
552	13:00-02:00	78 Columbus Court
553	09:00-19:00	03 Ryan Parkway
554	06:00-22:00	46 Alpine Hill
555	06:00-22:00	2314 Bonner Way
556	08:00-20:00	9522 Clemons Drive
557	06:00-22:00	66 Jana Hill
558	06:00-22:00	128 Crescent Oaks Way
559	13:00-02:00	843 Bultman Avenue
560	13:00-02:00	1 Fieldstone Street
561	08:00-20:00	96472 Sycamore Pass
562	09:00-19:00	8770 Manitowish Point
563	13:00-02:00	3 Lyons Terrace
564	08:00-20:00	6 Veith Hill
565	08:00-20:00	6 Basil Pass
566	13:00-02:00	3 Hintze Alley
567	06:00-22:00	3056 Almo Crossing
568	09:00-19:00	647 Scoville Park
569	13:00-02:00	38408 Onsgard Junction
570	06:00-22:00	59 Carioca Court
571	09:00-19:00	369 Coleman Place
572	06:00-22:00	6 Sachs Plaza
573	13:00-02:00	0210 Veith Circle
574	06:00-22:00	7047 Crowley Center
575	13:00-02:00	578 Oriole Hill
576	08:00-20:00	751 Paget Point
577	06:00-22:00	9039 Merrick Crossing
578	06:00-22:00	24356 Ludington Park
579	06:00-22:00	9 Jenifer Crossing
580	08:00-20:00	6673 Lyons Point
581	06:00-22:00	5 Dennis Road
582	08:00-20:00	2 Westport Place
583	13:00-02:00	2 Burrows Trail
584	08:00-20:00	8107 Mitchell Circle
585	13:00-02:00	517 Dixon Drive
586	09:00-19:00	431 Rieder Alley
587	09:00-19:00	382 Fremont Point
588	06:00-22:00	20 Holy Cross Circle
589	09:00-19:00	223 Meadow Valley Pass
590	09:00-19:00	86460 Northland Hill
591	09:00-19:00	77 Kingsford Road
592	09:00-19:00	41811 Rowland Crossing
593	06:00-22:00	2 Delaware Way
594	13:00-02:00	247 Cardinal Way
595	06:00-22:00	54 Oriole Place
596	09:00-19:00	320 Mayfield Circle
597	13:00-02:00	54468 Eliot Drive
598	06:00-22:00	5723 Morningstar Center
599	09:00-19:00	14730 Dixon Circle
600	13:00-02:00	73497 Myrtle Lane
601	13:00-02:00	108 Straubel Parkway
602	08:00-20:00	5941 Muir Alley
603	13:00-02:00	726 Mariners Cove Crossing
604	08:00-20:00	4379 La Follette Junction
605	08:00-20:00	1 Susan Way
606	06:00-22:00	82555 Waywood Hill
607	09:00-19:00	1647 Hovde Pass
608	06:00-22:00	22877 Blaine Park
609	08:00-20:00	96501 Elgar Crossing
610	08:00-20:00	4 Karstens Center
611	08:00-20:00	70 Mcbride Plaza
612	08:00-20:00	35637 Memorial Avenue
613	13:00-02:00	654 Mcguire Plaza
614	08:00-20:00	7 Michigan Circle
615	06:00-22:00	2 Stone Corner Crossing
616	08:00-20:00	449 Prairieview Terrace
617	08:00-20:00	9941 Arapahoe Center
618	06:00-22:00	236 Norway Maple Plaza
619	08:00-20:00	34370 Bonner Crossing
620	09:00-19:00	6144 Thackeray Avenue
621	06:00-22:00	17536 Prairie Rose Drive
622	13:00-02:00	3965 Southridge Pass
623	08:00-20:00	5657 Mcbride Way
624	13:00-02:00	4 Sutherland Point
625	09:00-19:00	406 Haas Court
626	06:00-22:00	944 Roth Place
627	09:00-19:00	1918 Eggendart Trail
628	06:00-22:00	2 Granby Pass
629	09:00-19:00	35235 Namekagon Lane
630	09:00-19:00	6 Havey Court
631	06:00-22:00	6183 Saint Paul Junction
632	06:00-22:00	7 Gateway Road
633	13:00-02:00	35803 Eastlawn Alley
634	08:00-20:00	99 Pepper Wood Avenue
635	08:00-20:00	505 Melvin Parkway
636	06:00-22:00	6015 Sycamore Hill
637	09:00-19:00	226 Quincy Circle
638	09:00-19:00	4 Derek Point
639	08:00-20:00	2838 Corscot Court
640	06:00-22:00	9 Bultman Place
641	13:00-02:00	79930 Troy Trail
642	08:00-20:00	856 Luster Street
643	13:00-02:00	9 Prairie Rose Center
644	09:00-19:00	1 Anderson Park
645	09:00-19:00	1 Glendale Parkway
646	06:00-22:00	4 Myrtle Trail
647	09:00-19:00	289 Towne Terrace
648	08:00-20:00	45 Mayer Road
649	09:00-19:00	0 Birchwood Park
650	13:00-02:00	0005 Hauk Lane
651	09:00-19:00	621 Hooker Street
652	09:00-19:00	7053 Talmadge Terrace
653	09:00-19:00	7 Becker Plaza
654	06:00-22:00	86873 Clyde Gallagher Pass
655	06:00-22:00	5881 Onsgard Court
656	08:00-20:00	6061 Rockefeller Lane
657	06:00-22:00	0 Eggendart Junction
658	09:00-19:00	85 Hermina Place
659	09:00-19:00	20516 Sheridan Trail
660	09:00-19:00	55 Florence Alley
661	09:00-19:00	8 Red Cloud Avenue
662	13:00-02:00	92491 Armistice Parkway
663	09:00-19:00	29 Rigney Road
664	08:00-20:00	70156 Bobwhite Center
665	08:00-20:00	06 Union Hill
666	13:00-02:00	16571 Rusk Lane
667	13:00-02:00	3269 Wayridge Hill
668	08:00-20:00	4 Little Fleur Park
669	08:00-20:00	68 Sunfield Circle
670	13:00-02:00	9 Anthes Court
671	08:00-20:00	07450 Ramsey Lane
672	06:00-22:00	14 Loftsgordon Parkway
673	09:00-19:00	7 Oxford Drive
674	13:00-02:00	20 Randy Place
675	09:00-19:00	50 Arkansas Drive
676	13:00-02:00	01560 Bartillon Center
677	13:00-02:00	6 Ilene Parkway
678	06:00-22:00	8 Truax Junction
679	06:00-22:00	47403 Anniversary Street
680	06:00-22:00	27 Ryan Drive
681	08:00-20:00	12 Marcy Junction
682	08:00-20:00	06 8th Alley
683	06:00-22:00	024 Calypso Alley
684	09:00-19:00	1058 Luster Avenue
685	08:00-20:00	98 Sachs Street
686	13:00-02:00	01 Namekagon Street
687	13:00-02:00	7947 Anhalt Way
688	09:00-19:00	66345 Bluestem Terrace
689	08:00-20:00	9 Riverside Court
690	09:00-19:00	998 Elka Circle
691	06:00-22:00	15373 Swallow Parkway
692	06:00-22:00	29972 Porter Terrace
693	08:00-20:00	36649 Westerfield Point
694	09:00-19:00	5 Dovetail Park
695	08:00-20:00	05 Badeau Point
696	06:00-22:00	40 Forster Circle
697	09:00-19:00	3753 Corscot Plaza
698	13:00-02:00	28001 Talisman Alley
699	08:00-20:00	34 Mcguire Road
700	13:00-02:00	22 Bonner Alley
701	08:00-20:00	9 Loeprich Plaza
702	08:00-20:00	0658 Steensland Plaza
703	08:00-20:00	525 Continental Hill
704	08:00-20:00	158 Swallow Place
705	13:00-02:00	6 Westport Center
706	08:00-20:00	06898 Prentice Crossing
707	08:00-20:00	28 Heffernan Plaza
708	09:00-19:00	06 Stuart Crossing
709	08:00-20:00	807 Killdeer Court
710	06:00-22:00	1891 Judy Parkway
711	08:00-20:00	67859 Ludington Pass
712	09:00-19:00	0 Dawn Avenue
713	13:00-02:00	36421 6th Street
714	13:00-02:00	604 Bonner Pass
715	08:00-20:00	85944 Victoria Road
716	08:00-20:00	397 Waxwing Center
717	13:00-02:00	88876 Graedel Place
718	06:00-22:00	8892 Birchwood Center
719	13:00-02:00	1424 Anzinger Street
720	13:00-02:00	76 Hansons Point
721	13:00-02:00	428 Hallows Avenue
722	06:00-22:00	8 Sauthoff Drive
723	08:00-20:00	031 Swallow Drive
724	13:00-02:00	71 1st Hill
725	13:00-02:00	85997 Becker Plaza
726	13:00-02:00	46 Clyde Gallagher Street
727	08:00-20:00	89 Golf Course Crossing
728	06:00-22:00	1 Lakewood Gardens Place
729	13:00-02:00	228 Oxford Hill
730	09:00-19:00	24488 Golden Leaf Trail
731	08:00-20:00	45089 Troy Plaza
732	08:00-20:00	2 Cody Center
733	13:00-02:00	43 Milwaukee Circle
734	08:00-20:00	969 Thackeray Hill
735	06:00-22:00	4682 Stephen Center
736	06:00-22:00	92810 Hoffman Plaza
737	06:00-22:00	93 Clarendon Pass
738	09:00-19:00	5 Granby Point
739	13:00-02:00	3 Lillian Drive
740	08:00-20:00	360 Charing Cross Parkway
741	06:00-22:00	7932 Portage Place
742	13:00-02:00	5 Melody Trail
743	09:00-19:00	9 Dapin Avenue
744	06:00-22:00	63 Hanson Circle
745	13:00-02:00	354 Golden Leaf Hill
746	09:00-19:00	9 Hovde Lane
747	09:00-19:00	73 Macpherson Lane
748	06:00-22:00	296 Harper Crossing
749	09:00-19:00	4 Lindbergh Lane
750	13:00-02:00	55157 Hansons Center
751	13:00-02:00	4116 Quincy Plaza
752	08:00-20:00	1 Nevada Avenue
753	06:00-22:00	69394 Judy Trail
754	13:00-02:00	8897 Buhler Road
755	09:00-19:00	35 Fisk Park
756	13:00-02:00	0417 Stang Park
757	08:00-20:00	239 Sunbrook Court
758	06:00-22:00	70 Bonner Place
759	06:00-22:00	7756 Center Road
760	08:00-20:00	8099 Sloan Place
761	08:00-20:00	739 Linden Court
762	13:00-02:00	62 School Avenue
763	08:00-20:00	87 Northland Circle
764	13:00-02:00	85571 Packers Drive
765	09:00-19:00	79 Pond Place
766	13:00-02:00	4 Canary Avenue
767	06:00-22:00	864 Crest Line Point
768	13:00-02:00	411 Hansons Court
769	06:00-22:00	6 Rowland Pass
770	08:00-20:00	77458 Milwaukee Crossing
771	13:00-02:00	719 Elgar Lane
772	08:00-20:00	12794 Scott Pass
773	08:00-20:00	5668 Bowman Alley
774	06:00-22:00	79 Hazelcrest Park
775	09:00-19:00	4 Harbort Road
776	09:00-19:00	7892 Heath Center
777	06:00-22:00	99 Hanover Junction
778	06:00-22:00	45 Barnett Parkway
779	09:00-19:00	266 Morrow Circle
780	09:00-19:00	7931 Graceland Lane
781	13:00-02:00	6623 Brown Street
782	09:00-19:00	5075 Carberry Hill
783	09:00-19:00	630 8th Avenue
784	13:00-02:00	2 Macpherson Drive
785	06:00-22:00	74542 High Crossing Circle
786	06:00-22:00	8 Paget Crossing
787	08:00-20:00	077 Ridge Oak Point
788	06:00-22:00	49277 Delaware Way
789	08:00-20:00	004 Pennsylvania Way
790	06:00-22:00	6948 Fieldstone Street
791	09:00-19:00	762 Rieder Crossing
792	08:00-20:00	0 Forest Dale Alley
793	06:00-22:00	2 Park Meadow Junction
794	08:00-20:00	3221 Dakota Place
795	09:00-19:00	6 John Wall Terrace
796	08:00-20:00	858 Eagle Crest Way
797	08:00-20:00	699 Lyons Way
798	06:00-22:00	1804 Corscot Way
799	13:00-02:00	4430 Granby Crossing
800	13:00-02:00	46547 Shopko Parkway
801	06:00-22:00	08 Debs Parkway
802	06:00-22:00	66657 Lindbergh Drive
803	06:00-22:00	3 Little Fleur Plaza
804	09:00-19:00	81 Miller Court
805	09:00-19:00	33807 Vermont Point
806	08:00-20:00	237 Hayes Avenue
807	06:00-22:00	190 Monica Center
808	08:00-20:00	3 Chive Place
809	09:00-19:00	96 Hintze Avenue
810	13:00-02:00	5313 Hanson Lane
811	08:00-20:00	61 Petterle Trail
812	09:00-19:00	30820 Springview Pass
813	09:00-19:00	4 Eagan Trail
814	06:00-22:00	664 Truax Road
815	06:00-22:00	14 Red Cloud Court
816	09:00-19:00	7 Westend Lane
817	13:00-02:00	93563 Meadow Valley Way
818	06:00-22:00	0807 Coleman Court
819	08:00-20:00	2 Trailsway Parkway
820	09:00-19:00	86185 Hallows Hill
821	06:00-22:00	348 Wayridge Place
822	09:00-19:00	63198 Dorton Court
823	13:00-02:00	6 Mandrake Circle
824	09:00-19:00	15 Grasskamp Place
825	09:00-19:00	47858 Merchant Parkway
826	09:00-19:00	9 Trailsway Terrace
827	13:00-02:00	70507 Delaware Pass
828	08:00-20:00	6 Buena Vista Park
829	13:00-02:00	4 Kenwood Pass
830	13:00-02:00	0839 Cardinal Point
831	09:00-19:00	74035 Warner Parkway
832	08:00-20:00	300 Pond Place
833	13:00-02:00	077 Randy Plaza
834	06:00-22:00	55 Petterle Park
835	09:00-19:00	16 Prairieview Hill
836	06:00-22:00	367 Pepper Wood Parkway
837	09:00-19:00	58 Mariners Cove Crossing
838	06:00-22:00	4770 Kenwood Way
839	08:00-20:00	841 Hoepker Pass
840	09:00-19:00	74 Warner Drive
841	08:00-20:00	7697 Lunder Hill
842	08:00-20:00	13270 Arapahoe Road
843	08:00-20:00	4283 Mockingbird Lane
844	09:00-19:00	33926 Reinke Lane
845	13:00-02:00	05 Eliot Court
846	08:00-20:00	0 Kennedy Park
847	09:00-19:00	101 Ohio Parkway
848	13:00-02:00	1827 Longview Terrace
849	09:00-19:00	95230 Doe Crossing Avenue
850	08:00-20:00	173 Cherokee Junction
851	06:00-22:00	277 Vera Parkway
852	06:00-22:00	5861 Main Street
853	09:00-19:00	9 Shopko Lane
854	08:00-20:00	7497 Talmadge Road
855	08:00-20:00	08976 Continental Avenue
856	13:00-02:00	823 7th Street
857	08:00-20:00	178 3rd Road
858	13:00-02:00	4 Corscot Parkway
859	09:00-19:00	56 Carey Circle
860	13:00-02:00	428 Bowman Court
861	13:00-02:00	36 Merrick Drive
862	08:00-20:00	519 Maywood Parkway
863	13:00-02:00	7836 Caliangt Point
864	09:00-19:00	01 American Ash Park
865	09:00-19:00	74 Manitowish Way
866	13:00-02:00	5977 Thompson Terrace
867	08:00-20:00	262 Arkansas Court
868	09:00-19:00	88787 Hazelcrest Park
869	13:00-02:00	42607 Brickson Park Junction
870	06:00-22:00	8 Bonner Junction
871	09:00-19:00	506 Mayer Parkway
872	09:00-19:00	78 Stone Corner Avenue
873	13:00-02:00	45 Anhalt Drive
874	08:00-20:00	6032 Raven Lane
875	06:00-22:00	8115 7th Parkway
876	08:00-20:00	18 Ridge Oak Road
877	06:00-22:00	50 Lotheville Avenue
878	08:00-20:00	62 Milwaukee Point
879	13:00-02:00	197 Farwell Parkway
880	06:00-22:00	41744 Chive Point
881	13:00-02:00	12 Morningstar Crossing
882	06:00-22:00	6987 Rutledge Parkway
883	08:00-20:00	9170 Acker Junction
884	09:00-19:00	03321 Division Trail
885	08:00-20:00	6757 Saint Paul Point
886	08:00-20:00	93 Dapin Street
887	13:00-02:00	904 Birchwood Point
888	08:00-20:00	7 Kinsman Lane
889	08:00-20:00	01 Donald Court
890	06:00-22:00	65187 Susan Terrace
891	13:00-02:00	7 East Hill
892	08:00-20:00	2 Pond Trail
893	09:00-19:00	09653 Corscot Way
894	13:00-02:00	8232 Stoughton Road
895	13:00-02:00	30 Hoepker Circle
896	06:00-22:00	19 Fair Oaks Point
897	13:00-02:00	52531 Lakewood Junction
898	09:00-19:00	256 Dottie Junction
899	08:00-20:00	4 Charing Cross Center
900	08:00-20:00	29 Oakridge Park
901	08:00-20:00	1967 New Castle Pass
902	08:00-20:00	976 American Ash Court
903	13:00-02:00	990 Mccormick Avenue
904	13:00-02:00	05487 Messerschmidt Street
905	06:00-22:00	9980 Surrey Parkway
906	09:00-19:00	8757 Kipling Way
907	13:00-02:00	3076 Anzinger Court
908	06:00-22:00	82575 Ruskin Road
909	06:00-22:00	9 Jenifer Parkway
910	13:00-02:00	3 Montana Point
911	09:00-19:00	9 Surrey Road
912	09:00-19:00	7166 Bobwhite Park
913	13:00-02:00	0249 Stang Lane
914	08:00-20:00	68 Glendale Trail
915	06:00-22:00	60936 Barnett Hill
916	13:00-02:00	12034 Lunder Parkway
917	06:00-22:00	524 Petterle Avenue
918	13:00-02:00	07 Kropf Alley
919	08:00-20:00	4 Gale Avenue
920	13:00-02:00	861 Troy Pass
921	08:00-20:00	59 Charing Cross Center
922	08:00-20:00	38386 Di Loreto Pass
923	09:00-19:00	018 Manley Avenue
924	06:00-22:00	353 Lien Center
925	08:00-20:00	47529 Cascade Park
926	13:00-02:00	8581 Alpine Avenue
927	13:00-02:00	05 Farmco Road
928	08:00-20:00	721 Talmadge Drive
929	08:00-20:00	77 Crownhardt Trail
930	09:00-19:00	140 Almo Road
931	06:00-22:00	4 Meadow Vale Junction
932	08:00-20:00	13 Briar Crest Crossing
933	13:00-02:00	6 Susan Road
934	09:00-19:00	73943 Miller Terrace
935	13:00-02:00	9 Blackbird Center
936	09:00-19:00	8988 Milwaukee Way
937	06:00-22:00	79708 John Wall Avenue
938	08:00-20:00	8 Superior Pass
939	09:00-19:00	9428 Birchwood Trail
940	09:00-19:00	0102 Dapin Park
941	09:00-19:00	02623 Dryden Plaza
942	13:00-02:00	39075 Linden Way
943	09:00-19:00	5423 Sunfield Crossing
944	13:00-02:00	75775 Michigan Alley
945	13:00-02:00	6 Graedel Parkway
946	09:00-19:00	6259 Pine View Hill
947	13:00-02:00	9 Towne Street
948	06:00-22:00	88319 Anniversary Hill
949	06:00-22:00	71 Bunting Road
950	09:00-19:00	61 Marcy Pass
951	09:00-19:00	73827 Sutherland Crossing
952	06:00-22:00	6519 Graedel Circle
953	08:00-20:00	5 Pennsylvania Drive
954	06:00-22:00	448 Scott Place
955	13:00-02:00	0363 Autumn Leaf Hill
956	09:00-19:00	8068 1st Circle
957	08:00-20:00	74 Golf View Trail
958	08:00-20:00	54 Emmet Terrace
959	13:00-02:00	5 Maywood Lane
960	08:00-20:00	3431 Portage Trail
961	09:00-19:00	7 Sheridan Circle
962	06:00-22:00	22 Montana Hill
963	13:00-02:00	14981 Annamark Place
964	13:00-02:00	4006 Tony Alley
965	08:00-20:00	8 Hansons Court
966	09:00-19:00	8 High Crossing Place
967	06:00-22:00	01627 Prairieview Circle
968	08:00-20:00	012 Brentwood Pass
969	08:00-20:00	239 Pepper Wood Way
970	13:00-02:00	07232 Gateway Way
971	09:00-19:00	514 Forest Run Way
972	06:00-22:00	2541 Butternut Point
973	09:00-19:00	860 Main Junction
974	06:00-22:00	3 Judy Crossing
975	06:00-22:00	48 Eliot Place
976	13:00-02:00	162 Ronald Regan Center
977	08:00-20:00	255 Fair Oaks Circle
978	09:00-19:00	05 Marquette Road
979	13:00-02:00	18627 Coleman Circle
980	09:00-19:00	4872 Sundown Hill
981	08:00-20:00	8 Kingsford Street
982	13:00-02:00	68764 Susan Court
983	09:00-19:00	9721 Iowa Lane
984	13:00-02:00	48450 Toban Plaza
985	09:00-19:00	22 Pankratz Parkway
986	13:00-02:00	5882 Rigney Hill
987	13:00-02:00	4388 Victoria Court
988	09:00-19:00	68359 Lukken Street
989	09:00-19:00	5 Evergreen Center
990	06:00-22:00	4 Grasskamp Plaza
991	06:00-22:00	3 Evergreen Alley
992	13:00-02:00	4 Lotheville Hill
993	06:00-22:00	2 Emmet Court
994	06:00-22:00	67 Ramsey Parkway
995	08:00-20:00	5 Daystar Lane
996	09:00-19:00	837 Hallows Place
997	13:00-02:00	438 Di Loreto Plaza
998	06:00-22:00	9560 Dakota Park
999	09:00-19:00	18628 Heath Hill
1000	09:00-19:00	70864 Cordelia Road
\.


--
-- TOC entry 3167 (class 0 OID 16445)
-- Dependencies: 205
-- Data for Name: storage_department; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.storage_department (id, name, id_medicine_form, id_pharmacy_warhouse) FROM stdin;
1	E0001	1	1
2	B0002	1	2
3	S0101	2	3
4	F1010	3	4
5	D4315	3	5
6	G6134	4	6
7	M9123	5	7
8	L1623	5	8
9	J7182	6	9
10	H2163	7	10
11	N3829	7	11
12	S2275	7	12
13	G9669	6	13
14	P4111	3	14
15	Q4979	4	15
16	L6164	2	16
17	D7511	7	17
18	K4721	4	18
19	V5806	6	19
20	I5958	4	20
21	N6845	2	21
22	P5768	4	22
23	Q6496	6	23
24	G8588	6	24
25	A5158	7	25
26	C3051	3	26
27	B4715	2	27
28	X8424	5	28
29	H3468	6	29
30	S5169	5	30
31	J6503	2	31
32	J9053	2	32
33	C7214	5	33
34	Z8903	4	34
35	Q0581	2	35
36	H1460	6	36
37	C7786	2	37
38	R2908	3	38
39	W3660	2	39
40	O2996	3	40
41	L2794	5	41
42	Z6935	3	42
43	U4710	2	43
44	T5493	6	44
45	P9680	4	45
46	F5039	6	46
47	H5991	6	47
48	F2839	6	48
49	S0875	2	49
50	L0799	6	50
51	G3129	3	51
52	A5690	3	52
53	R7708	2	53
54	D8220	6	54
55	H2857	4	55
56	B0480	5	56
57	N3761	4	57
58	E0102	3	58
59	J5865	4	59
60	X7497	5	60
61	U8445	2	61
62	D5293	7	62
63	O9083	4	63
64	R8472	5	64
65	O8532	2	65
66	T0819	7	66
67	R9439	6	67
68	A7836	6	68
69	H3631	7	69
70	O4669	7	70
71	C9588	7	71
72	H6212	7	72
73	Q9719	2	73
74	W1631	4	74
75	P0275	3	75
76	W5041	3	76
77	P3896	6	77
78	D1909	2	78
79	N2566	2	79
80	Y2441	2	80
81	Y9534	1	81
82	E2473	2	82
83	T0033	2	83
84	N4237	6	84
85	R0083	2	85
86	E5345	6	86
87	A6741	2	87
88	K3240	5	88
89	Y3888	7	89
90	Y9401	2	90
91	O8218	6	91
92	K7309	3	92
93	J1451	7	93
94	O7940	2	94
95	K8139	3	95
96	P1954	2	96
97	J5021	1	97
98	D4069	3	98
99	O0639	2	99
100	J7770	1	100
101	S6936	3	101
102	S1262	6	102
103	J6453	1	103
104	J3435	4	104
105	F6526	1	105
106	Y3402	3	106
107	T7770	2	107
108	S0292	2	108
109	T2238	4	109
110	U6476	7	110
111	A2475	4	111
112	Y9252	7	112
113	Y7368	7	113
114	U9439	7	114
115	R4043	1	115
116	Q5963	3	116
117	C1126	6	117
118	Q5090	2	118
119	Z3135	6	119
120	O5965	6	120
121	O5788	7	121
122	U5587	5	122
123	P7728	1	123
124	Q3914	7	124
125	R3619	5	125
126	M9630	6	126
127	V4085	1	127
128	F8961	2	128
129	C1194	3	129
130	H1925	2	130
131	P4505	5	131
132	M5793	1	132
133	E1987	3	133
134	F3502	4	134
135	U0339	6	135
136	L0512	5	136
137	C2681	2	137
138	T4250	1	138
139	P3890	3	139
140	F5756	2	140
141	I8499	6	141
142	A5545	3	142
143	L0701	3	143
144	R2552	2	144
145	F2021	7	145
146	H6266	2	146
147	V4224	4	147
148	Y2146	3	148
149	S2160	6	149
150	Q5343	7	150
151	A9124	2	151
152	I1681	4	152
153	A9650	4	153
154	R6860	1	154
155	G2101	5	155
156	V6699	2	156
157	C6280	4	157
158	X8439	6	158
159	I6585	7	159
160	U7470	6	160
161	I4366	3	161
162	R1319	7	162
163	M3555	6	163
164	N4391	6	164
165	O8382	1	165
166	H0981	2	166
167	G9595	6	167
168	U5341	4	168
169	W9234	5	169
170	S8242	1	170
171	A5961	1	171
172	P7424	2	172
173	Y9659	2	173
174	B1895	2	174
175	A4786	1	175
176	A4853	5	176
177	W2129	1	177
178	J2078	7	178
179	M4090	1	179
180	Q3086	4	180
181	V9761	4	181
182	G0113	2	182
183	H3181	5	183
184	K8583	6	184
185	A1781	3	185
186	K1052	1	186
187	K2396	1	187
188	W0747	1	188
189	J3446	4	189
190	V1193	4	190
191	M3608	4	191
192	Y9306	3	192
193	I1993	7	193
194	L4325	1	194
195	Q0231	5	195
196	O7005	5	196
197	P0072	5	197
198	I2177	4	198
199	I8796	2	199
200	F4336	2	200
201	J2983	1	201
202	H3450	4	202
203	K6524	4	203
204	E8644	4	204
205	D8916	3	205
206	B6281	3	206
207	B9285	7	207
208	G4099	3	208
209	T3950	5	209
210	D1220	3	210
211	D9619	3	211
212	W4942	1	212
213	N1099	5	213
214	J4156	4	214
215	A5879	7	215
216	V2725	7	216
217	O4182	1	217
218	F3103	7	218
219	O1143	3	219
220	K3466	2	220
221	D9260	3	221
222	G6395	3	222
223	U5645	4	223
224	P8483	1	224
225	P3807	6	225
226	I4196	1	226
227	E3009	3	227
228	G3629	6	228
229	W1290	1	229
230	G5469	6	230
231	L1197	6	231
232	Y4628	2	232
233	G4588	1	233
234	K0596	5	234
235	J6798	5	235
236	L1277	5	236
237	H1575	1	237
238	M6321	7	238
239	Z0954	2	239
240	L8442	3	240
241	S2436	7	241
242	Q2630	4	242
243	I5369	7	243
244	O4597	3	244
245	R6956	5	245
246	T7221	4	246
247	E6201	2	247
248	F9096	3	248
249	K9354	5	249
250	E3726	2	250
251	P3077	1	251
252	R8649	3	252
253	O4267	5	253
254	L3687	4	254
255	V4766	3	255
256	O4270	2	256
257	H5885	4	257
258	P7897	4	258
259	Z8134	7	259
260	C9959	7	260
261	G1453	6	261
262	H5765	5	262
263	P3200	4	263
264	H0433	7	264
265	O0807	3	265
266	M2038	7	266
267	X3693	7	267
268	F2353	5	268
269	O5516	1	269
270	W8606	5	270
271	S0112	1	271
272	U1336	1	272
273	Z8642	6	273
274	T9216	6	274
275	R2500	7	275
276	D6351	1	276
277	X1441	3	277
278	N5580	2	278
279	T5719	6	279
280	R0389	4	280
281	S8031	6	281
282	I1269	7	282
283	T4607	7	283
284	P0527	7	284
285	M6850	1	285
286	X9412	2	286
287	G6639	3	287
288	P1777	7	288
289	A9217	1	289
290	G2822	3	290
291	C1340	5	291
292	E2022	2	292
293	A5874	4	293
294	O1803	2	294
295	B5184	1	295
296	H8818	2	296
297	W0500	4	297
298	R6110	2	298
299	T5561	5	299
300	G5351	7	300
301	P1855	7	301
302	M8077	4	302
303	V9499	2	303
304	M6638	4	304
305	H3150	3	305
306	K2123	3	306
307	H4761	7	307
308	A1877	2	308
309	Y6667	3	309
310	F6935	3	310
311	Y2804	6	311
312	X7715	7	312
313	B7325	4	313
314	O5494	3	314
315	K3536	5	315
316	U7937	5	316
317	D1987	6	317
318	B1669	5	318
319	S9251	7	319
320	H5559	5	320
321	C7694	2	321
322	I4425	2	322
323	J7941	2	323
324	M2213	2	324
325	K4566	1	325
326	O5415	7	326
327	C0055	4	327
328	Q7608	4	328
329	Q1542	5	329
330	Y9471	6	330
331	R6029	3	331
332	N5879	3	332
333	G2461	4	333
334	X0814	7	334
335	H3732	1	335
336	Q3452	4	336
337	J9983	5	337
338	W7570	2	338
339	P7714	7	339
340	O7797	4	340
341	Y4015	5	341
342	Z5678	6	342
343	C0080	4	343
344	B8138	2	344
345	Z8866	4	345
346	R9684	1	346
347	M5521	5	347
348	F6529	6	348
349	S4312	5	349
350	R0215	1	350
351	F0387	2	351
352	S2836	6	352
353	T5094	3	353
354	S5408	7	354
355	S7101	5	355
356	E8208	2	356
357	F7976	4	357
358	U3710	3	358
359	K7651	4	359
360	B7193	1	360
361	W4676	5	361
362	O3084	3	362
363	B9504	6	363
364	I3435	6	364
365	Y4134	5	365
366	D1777	4	366
367	L5836	7	367
368	L1461	6	368
369	L9643	7	369
370	M8537	4	370
371	F0840	2	371
372	Y6376	6	372
373	B8133	7	373
374	M9026	5	374
375	X0843	4	375
376	T4432	6	376
377	T7210	6	377
378	C6323	2	378
379	H5861	3	379
380	I6873	6	380
381	L0501	5	381
382	G6306	3	382
383	A7744	1	383
384	A3603	5	384
385	I7853	1	385
386	F3584	3	386
387	C1990	6	387
388	Q5935	4	388
389	S5802	5	389
390	F2933	1	390
391	J1905	1	391
392	D2310	7	392
393	X6924	2	393
394	R1455	7	394
395	O1164	2	395
396	L1243	6	396
397	J2997	7	397
398	A0211	7	398
399	Q4795	3	399
400	P4356	3	400
401	M9173	2	401
402	Z4190	4	402
403	N8460	2	403
404	F0450	3	404
405	U2200	2	405
406	D5394	3	406
407	U8145	1	407
408	G9498	2	408
409	Y9228	6	409
410	N3339	7	410
411	G5825	6	411
412	I6464	7	412
413	V4883	3	413
414	O3252	4	414
415	Y2159	7	415
416	R6343	3	416
417	E3106	1	417
418	I5926	2	418
419	C9660	6	419
420	N8073	3	420
421	O5207	4	421
422	N6229	7	422
423	K9217	3	423
424	S7554	2	424
425	Y6788	5	425
426	R8508	7	426
427	J8328	1	427
428	C9581	6	428
429	N1391	4	429
430	S5226	5	430
431	M5641	2	431
432	P4328	6	432
433	M6075	1	433
434	T7328	5	434
435	F8421	4	435
436	Q8578	4	436
437	X9696	7	437
438	V9839	2	438
439	H0654	6	439
440	S1655	1	440
441	L9130	5	441
442	Q2682	5	442
443	J3796	4	443
444	C2965	2	444
445	S4742	4	445
446	V4539	2	446
447	C5480	1	447
448	S8152	4	448
449	E4520	2	449
450	N4412	6	450
451	U5762	2	451
452	K4762	3	452
453	R0006	1	453
454	N9570	5	454
455	M4455	5	455
456	L5089	4	456
457	N2290	5	457
458	E6312	5	458
459	U0712	4	459
460	B0711	4	460
461	H6200	4	461
462	E0842	5	462
463	R6568	4	463
464	X9044	3	464
465	B0644	6	465
466	F3941	5	466
467	O0573	2	467
468	K7523	3	468
469	I0905	2	469
470	M0208	5	470
471	O1519	2	471
472	P2194	6	472
473	I2753	2	473
474	R7766	2	474
475	D3503	2	475
476	Y7873	4	476
477	W8216	1	477
478	Z0155	1	478
479	H2129	5	479
480	J0272	1	480
481	U3434	6	481
482	C6525	6	482
483	V4849	6	483
484	W1355	1	484
485	E8384	1	485
486	C7074	4	486
487	G4349	6	487
488	Z6251	3	488
489	Q4285	4	489
490	B7286	4	490
491	O2683	4	491
492	R0898	3	492
493	N2317	1	493
494	Y6618	1	494
495	U8224	7	495
496	A8817	4	496
497	D4506	7	497
498	O1414	4	498
499	L9890	7	499
500	O9505	5	500
501	V6314	2	501
502	X1504	2	502
503	L5887	5	503
504	K7235	3	504
505	X3768	6	505
506	W3006	7	506
507	C8876	1	507
508	F3439	4	508
509	A2171	5	509
510	V9711	1	510
511	I8007	1	511
512	B4392	6	512
513	V3636	6	513
514	W5368	7	514
515	C0020	6	515
516	S9103	5	516
517	N3096	4	517
518	P3341	6	518
519	K8079	5	519
520	I0451	4	520
521	I6656	7	521
522	J3642	3	522
523	Y2329	1	523
524	D4907	2	524
525	Z1837	4	525
526	A2440	7	526
527	V6998	7	527
528	Y6462	5	528
529	O3595	7	529
530	Q7160	3	530
531	V4254	7	531
532	F8025	3	532
533	O4911	3	533
534	M3521	7	534
535	C9446	4	535
536	N0907	7	536
537	M2400	4	537
538	I9112	6	538
539	T4558	2	539
540	L0531	7	540
541	T4286	4	541
542	Z0418	7	542
543	E3963	7	543
544	R2904	3	544
545	D7471	6	545
546	W7358	4	546
547	A2999	3	547
548	G6642	6	548
549	G8157	7	549
550	X4282	1	550
551	O3432	4	551
552	Z2885	4	552
553	H7955	7	553
554	I7902	2	554
555	A0481	6	555
556	K2587	5	556
557	N8011	7	557
558	P3425	3	558
559	L0460	4	559
560	J1910	2	560
561	H0877	7	561
562	H3554	6	562
563	L9174	7	563
564	K7658	7	564
565	Z3442	1	565
566	F5747	2	566
567	K8271	6	567
568	N7809	6	568
569	J0487	6	569
570	Q5840	4	570
571	U8514	2	571
572	L7232	7	572
573	I1845	2	573
574	R7036	2	574
575	O8403	6	575
576	O3235	1	576
577	H1766	1	577
578	Y4268	6	578
579	K7679	7	579
580	U2237	6	580
581	S8091	3	581
582	N6202	6	582
583	S9080	6	583
584	U1683	2	584
585	X5259	6	585
586	C1353	3	586
587	H9948	2	587
588	Y2193	6	588
589	Y1034	6	589
590	P3420	6	590
591	I1228	5	591
592	P1793	1	592
593	D4381	1	593
594	O8957	6	594
595	Y3810	2	595
596	D0388	4	596
597	S2300	5	597
598	W4994	5	598
599	F7855	7	599
600	D7673	3	600
601	K2717	7	601
602	C7235	3	602
603	W4033	6	603
604	P0214	7	604
605	K3750	5	605
606	T1984	5	606
607	J8830	1	607
608	N7289	6	608
609	V2738	7	609
610	Z9344	6	610
611	O9206	7	611
612	I0649	4	612
613	J2708	7	613
614	K6668	7	614
615	B4407	3	615
616	P2825	7	616
617	M2826	3	617
618	L8407	7	618
619	P1512	5	619
620	N7005	5	620
621	H5518	2	621
622	L9060	3	622
623	L9130	4	623
624	V3817	5	624
625	F8325	6	625
626	N1812	4	626
627	L3670	1	627
628	R4402	3	628
629	T2057	2	629
630	G5467	4	630
631	L4068	6	631
632	Q2661	1	632
633	J2661	6	633
634	J3056	2	634
635	Z1140	3	635
636	A4020	3	636
637	V3213	7	637
638	N4130	4	638
639	D4064	3	639
640	X3374	4	640
641	R9432	6	641
642	D8879	4	642
643	A4960	1	643
644	T7579	7	644
645	X5290	3	645
646	S2680	6	646
647	U5348	4	647
648	W1422	1	648
649	P7075	3	649
650	U3912	2	650
651	I5896	2	651
652	D2266	4	652
653	J7245	4	653
654	F0895	3	654
655	P6376	6	655
656	Z1016	2	656
657	D2044	2	657
658	T1339	7	658
659	J4678	7	659
660	H6140	1	660
661	Y9325	2	661
662	F9348	5	662
663	R4754	7	663
664	R7099	2	664
665	C7277	6	665
666	R5539	4	666
667	K6770	6	667
668	T5865	5	668
669	R7386	5	669
670	U2733	1	670
671	W0559	1	671
672	O0980	2	672
673	N7822	2	673
674	F7694	2	674
675	L5775	3	675
676	P3937	7	676
677	S5048	7	677
678	C6860	4	678
679	T2679	5	679
680	G6983	2	680
681	T3358	3	681
682	W5391	1	682
683	U9114	5	683
684	K9284	2	684
685	J1702	4	685
686	T4837	6	686
687	C4004	6	687
688	G2380	1	688
689	V4326	4	689
690	O6596	2	690
691	Y1851	2	691
692	J1714	3	692
693	L1188	7	693
694	P2860	4	694
695	F7750	7	695
696	V3491	3	696
697	Q1316	2	697
698	H2518	1	698
699	Q1570	1	699
700	A0993	4	700
701	V0434	4	701
702	C7403	2	702
703	R4667	1	703
704	H2708	6	704
705	R9419	6	705
706	U6339	6	706
707	U8326	4	707
708	P9301	1	708
709	V5834	3	709
710	Z5980	4	710
711	R5251	5	711
712	Q2609	2	712
713	T6819	6	713
714	Q8607	3	714
715	F8586	7	715
716	N1512	7	716
717	C9297	3	717
718	W8880	5	718
719	R1932	5	719
720	R9563	7	720
721	Q2292	2	721
722	E0937	4	722
723	Z6975	6	723
724	K6868	7	724
725	R3556	4	725
726	V2447	3	726
727	F5834	4	727
728	H5122	2	728
729	L7633	2	729
730	U3138	3	730
731	S7568	1	731
732	A8378	6	732
733	N6936	1	733
734	Y1995	5	734
735	Q9208	6	735
736	C9544	1	736
737	Y2622	1	737
738	M6842	5	738
739	J0239	6	739
740	N1367	6	740
741	I2573	1	741
742	V6603	1	742
743	U1630	3	743
744	S5228	1	744
745	U5293	1	745
746	F8205	1	746
747	D7366	5	747
748	B7263	3	748
749	J4260	1	749
750	M4623	2	750
751	E1987	2	751
752	K7599	7	752
753	E7925	5	753
754	C7242	4	754
755	C7690	5	755
756	A9089	7	756
757	N3656	7	757
758	U5090	3	758
759	M6428	6	759
760	Q5595	3	760
761	G1928	5	761
762	E3748	2	762
763	Z6353	6	763
764	Y2801	4	764
765	O5512	7	765
766	I4019	7	766
767	D0474	2	767
768	D4201	4	768
769	U5472	2	769
770	D6304	4	770
771	P7455	7	771
772	F5379	2	772
773	O7939	5	773
774	T7184	2	774
775	K6324	6	775
776	D4405	3	776
777	H3637	5	777
778	B0661	5	778
779	C7510	1	779
780	Q7248	6	780
781	E7851	4	781
782	Q3565	4	782
783	G8470	4	783
784	L8669	2	784
785	S5962	1	785
786	X3570	5	786
787	T8477	7	787
788	N9877	6	788
789	Y2202	3	789
790	M2887	6	790
791	Y4387	3	791
792	D9292	4	792
793	W2687	7	793
794	H0315	2	794
795	Y4818	2	795
796	C7882	6	796
797	C8354	7	797
798	L3697	3	798
799	L2466	3	799
800	X2191	3	800
801	G9147	2	801
802	O0148	7	802
803	N2867	7	803
804	D0854	5	804
805	N8618	6	805
806	S3318	3	806
807	L9504	1	807
808	V4534	3	808
809	U4683	2	809
810	O8342	5	810
811	Q9607	5	811
812	D6465	2	812
813	A7084	3	813
814	J9734	3	814
815	S6266	3	815
816	N1839	4	816
817	T9586	1	817
818	X2756	5	818
819	G4329	7	819
820	U6425	7	820
821	K5375	5	821
822	P6880	4	822
823	M8611	7	823
824	D9844	4	824
825	G2178	3	825
826	I9978	7	826
827	F1238	6	827
828	T4329	2	828
829	L4730	4	829
830	S9070	4	830
831	Y0049	2	831
832	K9708	2	832
833	F6778	6	833
834	I6267	6	834
835	W7520	2	835
836	B6529	7	836
837	T0846	6	837
838	B9573	6	838
839	G4574	6	839
840	L4408	1	840
841	T8433	4	841
842	Z7987	5	842
843	V1673	7	843
844	P0921	3	844
845	A3538	4	845
846	E0678	2	846
847	E6742	2	847
848	A3347	5	848
849	W2599	1	849
850	X6461	1	850
851	R7558	1	851
852	O5470	2	852
853	B4702	2	853
854	S4189	7	854
855	N9174	4	855
856	Z3964	5	856
857	R6167	3	857
858	M1969	3	858
859	K3528	1	859
860	W8400	5	860
861	Y5999	1	861
862	B0578	2	862
863	O8093	1	863
864	E0467	4	864
865	Q9414	6	865
866	Z9884	1	866
867	M7629	2	867
868	Z0250	7	868
869	G9887	3	869
870	N4699	5	870
871	M1894	6	871
872	B9660	6	872
873	U8655	3	873
874	U8693	2	874
875	P2851	5	875
876	Z0455	5	876
877	O9328	4	877
878	A1213	4	878
879	S6421	6	879
880	B4428	3	880
881	R8476	4	881
882	E8966	6	882
883	K4923	6	883
884	I6962	7	884
885	B5477	3	885
886	R6107	1	886
887	I7646	6	887
888	Q3261	3	888
889	R8235	4	889
890	I9535	5	890
891	L8922	6	891
892	P5097	1	892
893	W9723	1	893
894	X0463	4	894
895	X6388	2	895
896	F4308	4	896
897	U8790	2	897
898	G6812	1	898
899	N2123	1	899
900	Q8141	2	900
901	I6852	3	901
902	K8892	3	902
903	Z3691	5	903
904	L6138	2	904
905	S1289	5	905
906	D5170	6	906
907	C7259	3	907
908	E5739	4	908
909	U6228	1	909
910	E7178	4	910
911	U1406	6	911
912	S8746	6	912
913	I6430	5	913
914	S2066	6	914
915	N6524	7	915
916	W8894	2	916
917	J4776	5	917
918	G4803	6	918
919	M9136	1	919
920	Y1713	3	920
921	Y8456	4	921
922	N2499	3	922
923	Q4436	2	923
924	K7641	2	924
925	D7577	5	925
926	J7129	2	926
927	F4943	5	927
928	K3656	2	928
929	P8617	1	929
930	I7016	5	930
931	O4397	1	931
932	M3078	3	932
933	P5037	3	933
934	W5301	2	934
935	Y0576	6	935
936	O7000	5	936
937	K7758	4	937
938	R8845	4	938
939	F6690	4	939
940	E9506	5	940
941	G9632	6	941
942	A7874	4	942
943	X2885	7	943
944	B6972	4	944
945	A5263	4	945
946	L1331	3	946
947	D6635	5	947
948	L9110	5	948
949	Z8932	3	949
950	A0204	1	950
951	P3162	6	951
952	Z1826	7	952
953	T6636	5	953
954	D1452	3	954
955	E9818	4	955
956	Z8697	4	956
957	A9642	4	957
958	P0706	2	958
959	F5566	1	959
960	W1530	1	960
961	S1961	2	961
962	Y5365	6	962
963	C6459	1	963
964	U2217	2	964
965	L1606	4	965
966	G7497	7	966
967	Q5147	1	967
968	Z1211	1	968
969	Q4132	2	969
970	N4600	2	970
971	H3893	7	971
972	M6591	4	972
973	J3134	6	973
974	F0957	4	974
975	J2491	7	975
976	D9840	1	976
977	U3696	3	977
978	F8581	4	978
979	O0464	5	979
980	R3209	6	980
981	F9119	1	981
982	M2275	1	982
983	L7975	4	983
984	X3622	1	984
985	V5710	4	985
986	P0644	3	986
987	T2165	4	987
988	W9488	2	988
989	U5312	1	989
990	X9398	7	990
991	O0432	1	991
992	Q1050	5	992
993	L4305	7	993
994	W7350	6	994
995	A6698	1	995
996	F5785	5	996
997	T9164	7	997
998	H4777	5	998
999	H3729	5	999
1000	R6925	1	1000
\.


--
-- TOC entry 3171 (class 0 OID 16471)
-- Dependencies: 209
-- Data for Name: storage_method; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.storage_method (id, name) FROM stdin;
1	Навальный
2	Напольный
3	Подвесной
4	Стеллажный
\.


--
-- TOC entry 3185 (class 0 OID 16591)
-- Dependencies: 223
-- Data for Name: voyage; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.voyage (id, voyage_number, car_number, destination_point, end_date_time, id_contract, start_date_time) FROM stdin;
11	L891245	п010ды	ул. Краснознаменская, д. 6	2021-05-15 07:00:00	1	2021-05-15 06:00:00
12	G831754	л234щк	ул. Райкова, д. 32	2021-05-27 14:00:00	5	2021-05-27 13:00:00
13	O861237	р832дв	ул. 7 Гвардейской, д. 42	2021-07-21 13:00:00	3	2021-07-13 06:00:00
3	H949812	б129дф	ул. Репина, д. 11а	2021-07-21 13:00:00	3	2021-07-13 06:00:00
5	K128423	л832рй	ул. Проспект им. Ленина, д. 53а	2021-05-27 14:00:00	5	2021-05-27 13:00:00
6	J234879	л123ту	ул. Проспект им. Ленина, д. 28	2021-04-12 06:00:00	6	2021-04-11 23:50:00
10	D912635	м134эн	ул. Маршала Рокоссовского, д. 50	2021-05-09 12:45:00	10	2021-05-09 10:40:00
9	T128472	у337ну	ул. Пирогова, д. 2б	2021-04-23 09:00:00	9	2021-04-23 07:00:00
14	S600636	b353yd	954 Debs Hill	2020-12-26 21:03:33	14	2020-12-05 12:10:21
15	U265878	u883qo	595 Hovde Terrace	2020-12-23 08:51:52	15	2021-02-01 14:24:25
16	X939175	a589hv	6 Morning Road	2020-07-07 17:10:03	16	2021-02-20 02:38:20
17	K991663	y038dz	218 Anderson Plaza	2021-02-09 10:43:49	17	2020-09-25 18:23:04
18	F688246	j386nt	15 Ridgeview Trail	2020-10-23 14:49:59	18	2020-06-24 16:53:11
19	G553257	b361tn	03337 Village Place	2020-10-20 11:27:32	19	2020-08-29 19:06:26
20	K951637	d778ei	22 Holy Cross Place	2021-05-01 18:44:50	20	2020-10-02 12:55:17
21	Y189097	m900qy	052 Arizona Point	2021-01-27 03:18:00	21	2021-05-21 12:17:14
22	M818857	r007bl	079 Acker Park	2020-09-07 18:06:30	22	2020-12-01 05:12:19
23	Q185428	v209xr	01 Kinsman Circle	2020-12-04 13:10:01	23	2021-01-24 15:26:34
24	Y447430	d274ia	1 Farwell Center	2021-05-01 13:38:30	24	2021-02-01 16:45:39
25	M713439	h672td	9 Towne Terrace	2020-06-16 18:46:47	25	2021-04-05 04:27:58
26	B721534	l942ub	8541 Larry Avenue	2020-10-19 16:00:20	26	2020-09-29 10:37:01
27	I531085	f666pb	89040 Warrior Drive	2021-01-31 11:20:03	27	2021-02-23 03:07:56
28	A262503	u105ar	190 Merchant Trail	2020-07-12 23:24:26	28	2020-09-02 21:25:35
29	V287593	q546vy	617 Carioca Parkway	2020-07-02 23:25:15	29	2021-02-15 04:37:02
30	Q419957	d824te	17 Hoffman Court	2020-12-24 12:42:04	30	2020-10-22 10:09:23
31	P735211	d239oy	7100 Havey Park	2021-05-12 19:41:19	31	2020-07-29 03:27:38
32	G780448	p646nf	66452 Reindahl Avenue	2021-03-29 10:29:44	32	2021-05-18 19:08:19
33	F633010	z144yv	23 Talisman Point	2020-08-08 14:52:56	33	2020-11-13 01:14:04
34	T608509	j291rq	1 Sheridan Circle	2021-04-26 23:19:24	34	2021-02-27 12:26:45
35	B757146	c963do	64349 Clove Trail	2020-07-31 18:03:26	35	2020-06-15 07:49:44
36	G049904	v770ad	40407 Anhalt Terrace	2020-09-06 23:02:48	36	2020-10-11 13:59:06
37	W790082	a320qp	1177 Fallview Way	2020-05-28 20:20:09	37	2020-12-23 00:54:49
38	J126976	m126ua	89 Dakota Parkway	2020-10-13 03:59:19	38	2021-05-19 22:04:41
39	J225295	g609is	95715 Mosinee Center	2020-09-21 13:03:38	39	2021-05-12 12:33:01
40	P008185	i642ky	992 Packers Pass	2021-02-01 10:58:42	40	2021-05-05 11:26:09
41	S566508	j964pi	403 Anderson Street	2020-07-12 16:43:42	41	2020-09-15 09:17:01
42	C511579	c720fy	28 Nancy Junction	2021-01-08 07:08:00	42	2020-10-12 04:31:01
43	C890755	i285bp	47348 Longview Center	2020-10-09 13:33:04	43	2020-10-23 02:53:01
1	E912643	а123бм	ул. 7 Гвардейской, д. 42	2021-05-15 07:00:00	1	2021-05-15 06:00:00
44	E339638	j725jt	76589 Dahle Parkway	2020-05-26 20:17:52	44	2021-04-09 00:45:05
7	F091284	д019ра	ул. Обломова, д. 71	2021-05-17 21:00:00	7	2021-05-17 15:00:00
8	P019284	о821па	ул. Жукова, д. 32	2021-08-29 15:30:00	8	2021-08-29 11:20:00
45	O656743	v763oe	8 Golf Court	2020-11-13 12:01:54	45	2021-02-26 05:39:33
46	H334303	w553vz	97 Jenna Hill	2020-10-23 00:27:51	46	2020-10-22 09:05:07
47	L874575	u077ln	8 Bay Center	2021-02-26 04:04:56	47	2021-01-11 18:16:43
48	U802756	s529yx	75710 South Road	2020-12-20 18:32:25	48	2020-08-06 19:31:57
49	E611312	w965ka	39 Arrowood Trail	2021-02-22 20:02:02	49	2021-04-14 17:07:21
2	R123098	и742да	ул. Металлургов, д. 23	2021-06-13 09:00:00	2	2021-06-13 08:00:00
4	L912482	б892ов	ул. Хиросимы, д. 43	2021-05-23 14:30:00	4	2021-05-23 07:45:00
50	H853396	p809ia	654 Dapin Circle	2021-01-30 02:35:45	50	2021-02-07 13:18:25
51	T191384	k300ni	42 Anzinger Lane	2021-01-27 08:48:59	51	2020-07-03 10:56:16
52	A224672	g623lv	92 Barby Way	2021-01-26 16:44:23	52	2021-04-11 07:03:49
53	O058491	m915mb	6 Colorado Way	2020-12-17 07:55:11	53	2020-08-05 11:26:06
54	L385177	t811xz	66103 Golf View Avenue	2021-05-20 20:52:55	54	2021-02-13 08:59:37
55	N537708	n520bf	95 Lillian Lane	2020-06-28 15:01:40	55	2020-06-14 12:44:27
56	U115060	c440gm	01 Gale Pass	2020-09-26 17:19:56	56	2020-06-24 05:43:45
57	Z161383	x972xm	0502 Melvin Center	2020-11-25 10:07:17	57	2021-01-23 20:43:21
58	U364759	f207vy	328 Grover Center	2020-09-19 01:42:21	58	2020-12-05 21:34:20
59	Q958406	q460ec	49098 Browning Terrace	2021-03-09 14:34:35	59	2020-09-18 18:54:59
60	C381096	b370tr	92 Maywood Center	2020-12-04 03:38:20	60	2021-01-26 13:27:30
61	E526882	t766np	84 Heffernan Court	2021-03-13 06:10:22	61	2021-01-07 04:42:42
62	M323159	n592sk	808 Lakeland Junction	2020-06-12 03:01:43	62	2020-12-22 18:17:14
63	D694247	l704wf	12 Cottonwood Parkway	2020-11-29 11:04:12	63	2021-05-03 23:40:29
64	X420522	f740hq	8787 Karstens Park	2021-01-16 04:16:29	64	2020-10-31 13:55:01
65	D331947	r745fo	07 Trailsway Junction	2021-03-08 20:12:17	65	2020-11-19 13:08:57
66	F393999	q314kw	63773 Hovde Court	2020-08-28 10:42:30	66	2020-06-27 10:25:34
67	H128095	o582uy	8 Northport Lane	2020-11-18 01:11:12	67	2021-04-08 01:20:58
68	K348060	v855pn	83 Warner Street	2020-07-16 21:06:50	68	2020-09-09 11:45:48
69	E889374	x090op	2 Declaration Terrace	2021-02-09 16:49:22	69	2021-04-07 18:01:12
70	L215128	k285ho	0778 Reindahl Hill	2021-01-16 00:35:14	70	2020-06-10 10:05:50
71	W788057	x982ks	6 Katie Court	2021-03-04 07:46:58	71	2020-07-08 05:55:12
72	R512421	c443qu	35862 Hoffman Center	2021-05-16 04:37:05	72	2021-03-21 21:33:52
73	E032819	p680gn	8126 Bonner Place	2020-05-29 04:56:22	73	2020-07-01 09:36:56
74	N734950	d473br	336 Golden Leaf Circle	2020-08-01 16:56:21	74	2021-01-21 04:40:06
75	A303858	i947lp	4476 Hanover Street	2020-08-06 01:16:58	75	2020-12-04 04:53:46
76	C813323	m025op	5 Warner Junction	2021-02-23 05:52:59	76	2020-12-23 16:38:16
77	V781925	j216yl	8075 Cambridge Hill	2020-11-10 20:21:01	77	2021-02-11 04:19:50
78	I307533	e361gs	62 Glacier Hill Crossing	2020-09-08 00:57:24	78	2021-01-12 18:12:53
79	Z924438	p248hr	735 Merrick Trail	2021-05-21 20:36:24	79	2020-08-14 03:39:09
80	N168844	i177mf	81 Kingsford Court	2021-04-30 03:50:49	80	2020-06-19 12:53:40
81	L975130	c934ld	876 Center Street	2020-11-10 13:54:29	81	2021-03-27 15:46:51
82	Z383460	f814bi	56 Brickson Park Avenue	2020-11-30 13:44:20	82	2020-06-20 18:06:32
83	Q246900	x509cy	20 Sloan Way	2021-03-20 03:42:28	83	2020-09-04 13:04:32
84	G308859	d407at	3 Spaight Alley	2021-04-22 10:45:26	84	2020-10-20 09:19:36
85	T912628	b173yu	8 Mitchell Court	2021-01-15 03:52:11	85	2020-05-27 04:49:34
86	L015912	d774er	142 Bayside Plaza	2020-12-01 19:42:04	86	2021-02-15 04:11:16
87	P451703	e725wr	34 Grayhawk Parkway	2020-07-29 23:34:05	87	2021-04-16 19:00:10
88	O613470	r650zr	774 Havey Junction	2021-01-08 17:04:44	88	2020-06-05 19:28:51
89	B216031	q745cf	79513 Mandrake Hill	2020-12-27 11:33:05	89	2020-06-29 08:13:37
90	R910945	k031bf	09 Burning Wood Center	2020-12-13 20:51:05	90	2020-11-23 12:56:34
91	C350434	f556iq	76 Johnson Avenue	2020-06-11 05:15:10	91	2020-08-27 08:26:04
92	T429838	o863oq	5 Karstens Terrace	2020-05-31 15:13:49	92	2020-10-19 08:33:54
93	G804472	k280rf	505 Merchant Alley	2021-02-05 19:27:01	93	2020-06-09 19:10:26
94	Y762510	m750pp	0627 Merrick Street	2021-01-27 10:37:38	94	2020-09-27 07:31:24
95	U518357	q792tp	4596 Hudson Alley	2020-12-10 10:37:39	95	2020-07-10 14:57:22
96	M536776	u770jg	0394 Sachtjen Alley	2020-06-22 11:48:19	96	2020-09-19 08:30:25
97	Z192857	g886qt	22651 Jana Drive	2020-06-16 05:25:20	97	2021-04-24 03:20:15
98	Y415451	o445vy	9545 Barnett Pass	2021-04-24 07:15:05	98	2020-07-23 06:48:02
99	O974881	z876dt	43 Jay Street	2021-05-08 19:44:18	99	2020-10-06 10:06:11
100	N439449	a765qi	891 Hallows Street	2021-02-04 21:05:44	100	2020-12-24 01:40:01
101	S140555	m019sn	9 Mockingbird Plaza	2021-04-19 12:40:42	101	2021-04-22 14:43:31
102	W157681	d847eg	01542 Meadow Ridge Crossing	2020-10-06 20:07:39	102	2021-05-04 16:26:01
103	U273635	p442iq	4 Kensington Plaza	2020-12-26 11:32:35	103	2020-10-02 22:40:18
104	D399608	f437hk	699 Clemons Place	2020-12-15 04:02:15	104	2021-05-02 03:06:17
105	T507293	m925oc	58557 West Lane	2020-12-24 10:17:40	105	2021-04-20 10:05:56
106	I735677	m210zq	0031 Petterle Terrace	2020-05-24 10:32:27	106	2020-09-27 21:42:18
107	E019305	o174qk	88 Eagle Crest Street	2020-08-04 11:34:55	107	2020-08-27 02:56:11
108	B654511	c042rv	6110 Little Fleur Lane	2021-05-11 01:18:18	108	2021-04-03 16:26:22
109	G461232	j940zf	60509 Saint Paul Circle	2021-03-06 06:52:51	109	2020-06-27 05:01:16
110	R822280	l330ru	01 Sutteridge Place	2020-12-24 21:07:52	110	2021-04-13 08:29:54
111	H065234	y115wy	42 Calypso Hill	2021-01-30 04:44:48	111	2020-08-21 07:39:34
112	M706928	s911pd	64886 Grover Circle	2020-10-12 16:52:58	112	2021-03-16 14:23:59
113	R160793	n801vs	3 Amoth Place	2020-07-24 19:00:54	113	2020-06-02 00:58:59
114	R285785	z407ra	6 Rowland Road	2020-06-16 13:37:07	114	2020-06-14 18:33:54
115	J351971	b272jf	90744 Mifflin Lane	2021-02-20 18:47:32	115	2021-01-08 17:05:28
116	H094091	h663bv	7117 Coolidge Crossing	2021-05-07 16:48:12	116	2020-12-10 15:31:03
117	V846835	g506zs	54 Kropf Point	2020-10-13 20:49:10	117	2020-09-08 18:34:06
118	H899044	c872jz	6119 Shasta Lane	2020-08-17 12:01:29	118	2020-09-18 04:34:42
119	L022350	w894le	2 Rusk Junction	2021-03-03 12:32:30	119	2020-08-26 01:04:01
120	Z622306	x204po	18 Redwing Way	2021-05-13 17:01:30	120	2020-05-25 22:25:48
121	P830938	k127wl	968 Huxley Plaza	2020-06-29 13:09:58	121	2020-12-06 17:08:44
122	K553109	c062yx	29 Michigan Road	2020-06-06 03:18:00	122	2020-08-14 00:39:36
123	P358352	a294bu	79 Sunfield Hill	2020-08-31 08:40:41	123	2021-04-12 03:16:24
124	Q762595	a531fk	575 Longview Way	2020-12-28 19:05:03	124	2020-11-07 02:47:03
125	C185249	s128xi	6 Northview Plaza	2020-09-17 10:08:55	125	2020-11-28 21:36:03
126	Z727253	m894gf	10216 American Ash Way	2020-10-24 17:07:51	126	2021-05-12 15:25:41
127	T702294	j031ud	46926 1st Junction	2020-12-17 15:51:13	127	2020-08-27 18:54:53
128	B907438	i044nt	1 Blackbird Alley	2020-05-31 01:40:45	128	2020-12-11 18:38:34
129	O914067	t775xz	8 Manitowish Alley	2020-10-22 09:07:26	129	2020-11-26 04:58:28
130	G653083	t702rz	356 Pankratz Point	2020-12-16 01:18:42	130	2020-09-24 21:36:02
131	N383592	h328il	2 Waubesa Point	2021-02-08 23:03:13	131	2021-02-11 02:15:25
132	F653805	l020ro	2 Eggendart Plaza	2020-10-03 02:53:10	132	2021-01-12 17:55:22
133	B602493	q632qm	86316 Esker Way	2020-06-06 05:51:39	133	2020-08-22 03:29:32
134	T601317	t579fm	97611 Dryden Drive	2021-03-30 18:08:34	134	2021-01-15 23:50:32
135	C191940	h474zu	81697 Esch Junction	2020-12-11 12:34:49	135	2021-05-10 00:04:21
136	O826593	q070pl	908 Morrow Circle	2020-07-07 08:11:26	136	2020-07-16 13:55:26
137	Q286566	w143dl	9 Oak Way	2021-04-22 15:04:12	137	2020-11-23 08:23:25
138	I101042	a493hb	2 Meadow Ridge Terrace	2021-03-01 05:16:15	138	2020-09-13 21:22:34
139	T439009	k716sy	949 Crowley Place	2020-11-05 02:50:52	139	2020-09-13 02:32:44
140	L821177	d490xc	261 Bowman Pass	2020-12-21 23:06:33	140	2021-03-27 14:55:36
141	M589234	u593ls	68 Glendale Circle	2020-08-14 21:59:19	141	2021-02-19 00:36:29
142	U132548	f933ub	3 Ridge Oak Junction	2020-09-09 09:40:17	142	2020-06-26 12:19:23
143	I440931	c417wi	3167 Eggendart Place	2021-03-10 19:49:36	143	2021-02-06 23:50:23
144	Z979544	d212od	093 Gale Parkway	2021-02-24 08:47:29	144	2021-03-20 01:16:51
145	L414978	s921io	1 Thompson Plaza	2020-11-14 03:35:13	145	2021-03-06 16:29:16
146	S907594	y312vr	822 Donald Plaza	2020-10-03 11:31:33	146	2020-05-25 14:56:50
147	U101600	p462hd	51339 Butternut Center	2021-05-17 14:58:29	147	2020-10-25 00:06:16
148	B000671	j895ia	4730 Linden Trail	2021-04-17 07:53:11	148	2020-06-10 12:04:58
149	Y876190	t147ad	5149 Meadow Ridge Street	2020-06-19 01:59:44	149	2020-07-27 09:29:32
150	P339043	m388pc	19764 Sugar Pass	2021-01-24 18:28:55	150	2020-05-30 02:06:20
151	S219343	r864aa	25301 Fuller Place	2021-03-31 12:31:53	151	2021-01-02 14:01:36
152	Q788366	a378em	31323 Hagan Plaza	2020-12-22 15:04:50	152	2020-12-26 09:34:58
153	C869837	n672pi	92818 Sutteridge Center	2021-03-10 14:41:07	153	2021-04-04 06:05:32
154	H570110	o634za	1374 Kennedy Lane	2020-06-17 17:08:22	154	2021-03-27 15:33:57
155	N900383	r913ai	285 Morningstar Center	2020-07-18 06:54:53	155	2021-01-08 02:57:27
156	H485857	i725bk	30 Oak Valley Avenue	2021-02-23 15:42:17	156	2020-09-21 12:52:34
157	C919232	z857tr	49045 Nancy Pass	2020-12-20 02:36:49	157	2020-09-30 21:10:30
158	F556590	o397nb	957 Oneill Street	2020-12-27 00:08:52	158	2021-01-09 06:46:16
159	X544095	b334pc	915 Roxbury Place	2021-04-20 18:34:16	159	2020-06-15 18:12:22
160	D056708	j304wv	8070 Miller Drive	2020-12-26 09:26:19	160	2020-05-31 07:51:29
161	S513078	b944na	571 Jenna Trail	2020-07-09 17:37:00	161	2020-10-17 05:37:24
162	U152647	w036ri	56 Wayridge Drive	2020-11-19 20:08:20	162	2021-03-27 16:22:22
163	R601176	i685ez	2139 Briar Crest Crossing	2020-06-17 18:20:56	163	2020-11-03 01:46:54
164	P861075	d153fv	59 Monument Parkway	2020-09-20 05:45:57	164	2020-11-11 17:01:08
165	P776791	u310xq	28 Longview Terrace	2020-08-11 05:08:01	165	2020-10-22 16:27:42
166	M354257	q848bc	1 Forster Street	2021-05-07 23:06:41	166	2020-06-09 17:15:56
167	L139696	c911ax	58 Daystar Trail	2021-01-01 23:48:47	167	2021-03-10 16:32:27
168	O525369	c832vd	664 Melby Way	2021-01-15 15:06:55	168	2020-12-04 12:08:42
169	S530913	h621gy	90553 Vermont Pass	2021-03-20 09:18:21	169	2020-12-15 08:35:18
170	O046398	n024zj	9345 Lindbergh Pass	2021-02-19 09:35:14	170	2021-04-03 15:34:41
171	M092690	a703yz	56755 Tennessee Circle	2020-09-27 03:41:12	171	2020-12-10 05:10:16
172	O084297	e650wj	58298 Elka Drive	2020-11-14 14:44:26	172	2021-04-26 12:51:37
173	L660488	b883iq	8 Trailsway Road	2020-08-15 10:48:40	173	2020-06-01 04:16:59
174	X566969	r248jt	75 Porter Parkway	2020-10-03 11:16:32	174	2020-12-03 12:28:43
175	B570350	f972ho	93506 Gerald Park	2021-03-17 09:30:14	175	2020-09-09 11:54:43
176	P224285	g803lk	79675 Shopko Trail	2020-12-16 23:48:37	176	2021-01-11 21:14:41
177	J322558	v698gf	0 Kinsman Road	2021-04-07 21:56:31	177	2021-03-12 21:24:01
178	K117753	k305rt	28575 Sachs Point	2021-03-04 14:16:53	178	2020-12-18 19:34:53
179	B867937	g553vz	77106 Almo Pass	2020-07-16 01:09:33	179	2020-06-02 19:56:03
180	C564542	s393ow	55532 Elka Circle	2020-12-14 12:47:12	180	2021-03-13 18:52:15
181	N950155	c943nn	92650 Hayes Place	2021-03-06 21:14:22	181	2020-11-08 16:16:02
182	F396096	x904yw	3408 Kennedy Circle	2021-04-26 00:29:49	182	2021-05-09 14:09:20
183	J143621	v720wp	143 Eastlawn Plaza	2020-05-26 01:04:20	183	2021-05-15 07:15:40
184	B717758	f897es	296 Monterey Lane	2020-10-09 13:46:50	184	2020-06-08 12:29:12
185	Y972100	k221tm	414 Darwin Junction	2021-01-11 07:20:04	185	2020-11-04 11:55:08
186	M060743	a082io	5221 Banding Pass	2020-08-14 20:00:13	186	2021-04-25 04:42:14
187	R990596	p161xp	49757 Sycamore Circle	2020-07-13 22:22:27	187	2020-09-16 23:15:08
188	K253833	i583rl	909 Hazelcrest Street	2020-06-20 08:21:28	188	2021-05-08 03:45:10
189	M093926	h952dy	15 Dryden Lane	2020-11-09 03:22:36	189	2021-03-24 00:29:33
190	N300343	n042dl	02738 Crescent Oaks Trail	2020-11-14 07:25:26	190	2020-10-17 03:57:46
191	B766450	j040gb	0803 Maryland Way	2021-04-13 13:52:19	191	2021-04-06 19:38:06
192	G603388	g216bf	45 Golf Course Lane	2020-08-18 08:09:33	192	2021-01-08 00:46:11
193	M107146	v995bk	67 Granby Drive	2021-03-02 12:35:23	193	2021-01-11 18:38:12
194	R154020	u807wr	29954 Londonderry Pass	2020-09-11 16:25:24	194	2020-12-24 11:03:13
195	E395991	y580xx	4 Arrowood Hill	2020-10-27 15:10:15	195	2020-11-25 06:41:00
196	W827027	g571go	5191 Delaware Circle	2020-12-21 08:45:22	196	2020-08-20 11:53:57
197	C487216	u054vn	14369 Ohio Center	2021-01-29 01:52:46	197	2020-08-07 23:51:54
198	X796770	p050xu	2 Glacier Hill Junction	2020-05-24 00:03:48	198	2020-07-18 06:24:49
199	S884904	l089ab	905 Amoth Terrace	2021-02-20 21:09:07	199	2020-06-10 04:47:27
200	C061907	j196wd	59 Becker Avenue	2020-07-02 02:34:56	200	2021-01-13 16:43:25
201	J774674	s221pp	27301 Declaration Center	2020-09-12 15:17:41	201	2020-06-05 08:23:12
202	B568129	j161mm	4 Gerald Lane	2020-07-01 18:48:01	202	2020-10-01 16:03:47
203	U699563	g837ff	9647 Manitowish Terrace	2020-12-04 05:56:40	203	2020-07-27 23:15:24
204	V937003	f901ow	67 Del Mar Place	2021-01-09 23:51:38	204	2020-12-07 03:01:20
205	B179608	n545wc	6 Lotheville Parkway	2021-05-05 01:03:21	205	2020-11-01 12:18:33
206	E044144	b767xj	7 Superior Drive	2020-12-26 11:47:22	206	2020-08-08 02:32:21
207	Q711377	h001jq	6048 Carberry Alley	2020-10-14 08:55:29	207	2020-10-13 05:56:56
208	V217029	g952vz	7822 Darwin Hill	2020-09-17 08:11:04	208	2020-09-29 14:07:55
209	S391751	b102db	10170 American Ash Road	2021-02-07 13:15:41	209	2020-06-09 11:04:29
210	Z718751	w113mf	253 Stephen Drive	2021-05-11 20:40:43	210	2021-04-28 17:04:10
211	H858315	h330iq	6 Morrow Way	2021-05-19 09:32:54	211	2020-12-07 00:12:14
212	B948419	o346rv	67323 Dahle Center	2021-02-27 14:22:00	212	2020-07-09 08:33:09
213	X083303	f382ul	8 Ludington Alley	2021-04-26 10:22:57	213	2020-05-29 18:55:03
214	N821176	m536sj	283 Pine View Terrace	2021-01-20 11:09:21	214	2020-10-14 08:00:21
215	T179901	l227mz	601 Autumn Leaf Point	2020-06-26 23:18:04	215	2021-04-16 06:20:15
216	B737283	k822na	94 Rigney Circle	2020-06-29 04:05:17	216	2020-11-15 14:37:51
217	G505560	k492pv	449 Hansons Place	2021-03-14 09:05:27	217	2020-11-08 05:06:24
218	V014031	j511at	590 Riverside Court	2020-07-10 16:11:06	218	2021-02-28 12:23:06
219	D834558	y432wi	272 Ronald Regan Street	2020-10-09 17:10:51	219	2021-04-27 01:48:27
220	L296585	q742yp	60076 Beilfuss Parkway	2020-10-26 06:59:38	220	2020-12-24 04:33:49
221	F220161	j713ie	221 Summer Ridge Hill	2020-10-18 16:09:06	221	2021-02-23 08:47:37
222	S181311	l858ve	153 Autumn Leaf Plaza	2021-05-03 16:38:12	222	2020-07-03 00:19:35
223	M009200	z397os	9 Garrison Park	2020-05-25 04:26:32	223	2020-06-03 11:04:28
224	D583954	x361hm	454 Bonner Drive	2021-04-21 23:05:30	224	2020-06-23 15:16:18
225	E629819	b835cl	493 International Parkway	2020-08-29 03:44:47	225	2021-02-16 22:07:04
226	L050171	l223xg	9 Evergreen Hill	2021-02-17 20:41:01	226	2020-07-15 17:14:07
227	A219460	b088lz	722 Butterfield Junction	2021-03-15 08:43:28	227	2021-02-01 20:47:01
228	B016670	g001ut	5376 Everett Alley	2020-08-16 00:24:02	228	2021-04-04 02:38:43
229	F809672	k245ph	253 Brickson Park Crossing	2020-08-13 07:15:54	229	2020-07-14 04:32:46
230	Y974511	s316gm	91259 Schurz Lane	2020-11-01 14:32:45	230	2021-02-13 01:17:05
231	M955468	b084yp	4078 Truax Hill	2021-01-08 23:35:25	231	2021-03-19 19:49:18
232	Y791141	l407ji	2 Union Terrace	2020-11-12 14:17:04	232	2020-12-11 11:23:55
233	M062946	b022rv	3 Meadow Ridge Lane	2021-03-06 15:45:01	233	2020-08-22 15:09:21
234	N707991	z951ro	9413 Commercial Alley	2021-03-24 14:14:30	234	2021-01-05 22:36:07
235	W395096	v522ix	05435 Kropf Point	2021-03-16 18:10:12	235	2020-09-20 03:50:51
236	F075699	q669vn	0 Everett Parkway	2020-06-30 05:11:41	236	2021-01-26 09:57:53
237	B711294	l586rr	41010 Harper Trail	2021-03-26 23:42:39	237	2020-12-14 18:12:23
238	B543082	n785lx	71 Melby Point	2021-02-02 11:20:59	238	2020-09-03 02:48:42
239	I829690	q425vm	2696 Oak Circle	2020-09-15 19:41:42	239	2021-03-28 22:05:44
240	T622030	q500in	85289 Delaware Point	2020-10-07 15:07:26	240	2020-09-06 22:12:22
241	G856806	b196yd	670 Moose Junction	2020-12-15 23:05:10	241	2021-05-02 18:42:47
242	E919113	c877wq	18 Lillian Parkway	2020-12-08 19:01:14	242	2021-03-25 04:52:24
243	Q003789	r676yd	32 Becker Point	2021-05-09 06:23:34	243	2021-03-04 03:52:36
244	R327256	o764hh	5869 Gateway Way	2020-07-20 10:29:54	244	2020-07-09 17:15:02
245	I796504	h876qo	988 Commercial Crossing	2021-04-24 17:19:44	245	2020-09-09 16:37:50
246	A726135	e683ik	0957 Del Mar Way	2021-04-08 12:41:46	246	2020-12-23 22:51:05
247	B493527	b685xo	68108 Monument Alley	2020-10-09 20:28:22	247	2021-02-15 02:02:20
248	G718418	d256na	9 Garrison Road	2020-08-09 08:10:47	248	2020-10-21 15:17:17
249	P050921	h882fb	293 Nancy Center	2020-07-24 22:21:26	249	2020-07-17 13:29:36
250	N012401	g805go	7 Sheridan Junction	2020-09-17 21:28:13	250	2020-07-27 15:37:58
251	I158737	l614hw	0866 Jenna Center	2021-03-08 16:17:12	251	2021-03-25 10:50:56
252	A961900	e387kz	387 Redwing Center	2020-11-23 20:44:52	252	2021-02-11 14:47:53
253	J436089	q058es	79266 Oxford Crossing	2020-10-18 12:12:56	253	2021-02-02 05:27:58
254	L222430	v510rd	523 Mcguire Avenue	2021-03-23 09:29:50	254	2020-10-31 15:10:00
255	C871176	o405vo	0633 Longview Circle	2021-01-04 05:08:52	255	2020-06-01 03:14:06
256	B530468	i844vr	6950 Old Shore Park	2021-04-03 01:48:53	256	2020-11-03 00:27:18
257	Q748533	l035am	84331 Sachtjen Park	2020-07-16 21:03:02	257	2020-06-14 07:18:00
258	K525105	h333lg	98151 Luster Alley	2020-08-28 09:20:49	258	2020-07-06 23:28:01
260	R057766	q921iy	8 Vermont Pass	2020-11-12 01:58:40	260	2020-07-31 02:27:54
261	S463679	t718bu	099 Truax Place	2020-06-08 21:43:17	261	2020-09-12 16:59:24
262	V668261	y619re	671 Shopko Junction	2021-01-20 19:13:25	262	2021-04-20 06:28:25
263	A727840	t185bc	86086 Clarendon Point	2020-06-03 11:24:36	263	2020-09-14 10:10:02
264	U832271	j155mo	597 New Castle Parkway	2020-12-30 22:39:09	264	2021-03-02 09:10:26
265	O510702	j077cd	3846 Butternut Crossing	2021-02-01 22:02:55	265	2020-09-19 03:57:47
266	M564186	c193dh	668 Northport Circle	2020-06-14 11:59:18	266	2020-11-24 18:47:29
267	H736171	h592py	3 Rutledge Hill	2021-01-19 08:00:10	267	2021-04-06 19:46:45
268	D253947	f403ji	1 Mallard Center	2020-08-24 02:24:03	268	2020-11-19 07:55:30
269	P587573	t341dn	744 Starling Road	2020-12-05 04:17:57	269	2020-05-28 00:19:21
270	C712027	c808dv	58 Vahlen Way	2020-08-08 09:26:57	270	2020-10-16 01:11:14
271	R584650	b188ng	0 Shopko Trail	2020-11-13 08:36:51	271	2020-06-09 10:06:51
272	W279161	e644ra	1 Hoard Crossing	2020-09-04 01:09:39	272	2020-07-15 00:22:06
273	A184631	i715bi	2398 Golf Circle	2021-04-05 19:02:51	273	2021-01-19 13:30:59
274	Z751563	e932ci	511 Kipling Circle	2020-09-01 04:27:51	274	2020-11-30 00:01:05
275	M914956	f957wp	0 Fordem Court	2021-01-24 07:33:20	275	2021-03-02 22:10:15
276	P110681	w336gn	1917 Oriole Circle	2020-11-09 17:56:53	276	2021-04-28 20:25:25
277	P259418	e254of	576 Shasta Hill	2020-09-15 03:42:59	277	2020-12-02 11:06:48
278	V310791	i760ak	70651 Crownhardt Crossing	2021-02-20 08:27:21	278	2021-01-31 21:24:32
279	G913722	q956tq	50 Grasskamp Terrace	2020-09-19 17:24:26	279	2020-07-11 08:48:48
280	L062025	j952zc	9390 Elgar Hill	2020-08-23 09:46:15	280	2020-09-25 04:28:50
281	R417067	x089kk	871 Kingsford Drive	2021-04-26 21:51:08	281	2021-02-22 18:33:44
282	T229045	w578dp	6 Anderson Junction	2020-12-18 13:17:11	282	2020-06-24 14:14:33
283	D611458	h408sw	5279 Mayer Drive	2020-06-17 22:40:21	283	2020-12-18 22:49:11
284	X862150	x269qv	73127 Schlimgen Court	2021-05-15 23:25:04	284	2021-05-06 03:07:35
285	G250190	l179hc	08 Acker Drive	2020-07-30 03:13:31	285	2020-09-24 15:06:01
286	Q321709	s466nj	4 Mcbride Plaza	2020-09-09 01:02:35	286	2021-05-22 05:54:46
287	M619918	i877vc	2 South Trail	2020-06-26 07:44:38	287	2021-03-23 15:16:39
288	E752285	t402qt	9167 Bellgrove Hill	2021-05-14 20:05:15	288	2021-01-10 05:42:05
289	N408766	c540cz	34149 Rieder Court	2020-08-11 07:27:03	289	2020-10-23 22:09:06
290	Y916828	i915ri	0 Nancy Place	2020-12-27 05:53:05	290	2020-07-04 11:59:04
291	J040433	l098vz	82163 Roth Alley	2021-04-11 11:49:30	291	2020-12-21 03:49:49
292	C116233	f648hd	5033 Hooker Crossing	2020-05-24 15:43:27	292	2021-02-27 02:25:22
293	H037552	z734rt	9 Melody Crossing	2021-02-07 21:31:18	293	2020-06-03 23:52:07
294	P091080	m422we	7637 Sunnyside Plaza	2021-03-22 13:59:38	294	2020-07-15 03:12:51
295	Q454380	w559cg	714 Walton Avenue	2021-02-17 20:52:08	295	2020-08-31 21:26:25
296	Q373623	r225nx	4431 Carberry Avenue	2021-03-31 01:37:35	296	2020-06-29 04:46:32
297	N288786	d038gv	3276 Packers Court	2020-07-22 03:23:25	297	2020-11-06 16:45:50
298	W015096	y129at	2483 Eagle Crest Road	2020-10-07 11:53:33	298	2020-08-03 08:10:20
299	D325948	o532er	9724 Dakota Court	2021-05-15 02:43:22	299	2020-06-17 18:08:50
300	N898160	q308mz	81302 Bultman Plaza	2021-05-18 05:18:52	300	2020-06-20 17:04:39
301	P470037	j781zh	30 Oakridge Pass	2020-12-06 00:05:40	301	2020-10-12 21:46:38
302	W564815	i672wl	2526 Schmedeman Circle	2020-09-08 03:58:14	302	2020-10-11 21:17:36
303	Z711737	h457hu	40 Vernon Circle	2020-06-10 10:35:49	303	2021-03-19 16:36:15
304	L272873	d770pn	7 Logan Parkway	2020-11-15 19:16:10	304	2020-09-09 00:27:47
305	B116003	k800qs	2 Northport Plaza	2020-09-21 13:29:19	305	2021-05-13 12:47:46
306	U854473	u723ll	057 Acker Avenue	2021-02-25 22:33:08	306	2020-06-18 21:38:09
307	B020198	s710sx	973 Utah Alley	2021-04-01 16:51:47	307	2020-10-13 06:09:25
308	V946330	q583kt	34 Manley Place	2020-11-11 18:43:15	308	2020-12-01 01:06:15
309	C116465	x413yo	88 Clemons Circle	2021-05-13 22:37:01	309	2020-12-17 10:56:27
310	X489066	e326dj	3 Bellgrove Circle	2020-11-08 15:54:49	310	2020-11-30 20:55:44
311	D838196	j797cz	76652 Rigney Lane	2020-08-27 10:00:10	311	2021-04-20 09:02:36
312	J050446	t326sm	14 Washington Pass	2021-01-05 07:29:12	312	2021-02-23 00:44:28
313	Z763651	y620gf	373 Dorton Circle	2020-09-03 20:50:13	313	2020-09-10 00:30:18
314	K359250	o906xv	234 American Ash Center	2021-01-04 20:56:59	314	2021-01-08 09:56:10
315	E575338	h428jn	25090 Stang Trail	2021-01-24 20:55:35	315	2020-07-22 12:58:10
316	P730726	u841nu	95277 Harbort Point	2021-04-03 21:35:17	316	2020-09-30 08:51:31
317	F567767	e176eb	295 Pepper Wood Drive	2020-10-12 10:37:48	317	2021-05-20 06:54:51
318	E108897	t351kx	5115 Manufacturers Street	2021-03-15 07:17:38	318	2020-08-29 10:33:48
319	I559247	u286mf	1 Ilene Road	2021-02-10 00:49:58	319	2020-06-19 07:35:44
320	Z719990	a063aq	01 Rigney Road	2021-04-18 02:06:29	320	2021-02-10 11:56:00
321	S049027	e622is	36 Rowland Plaza	2021-03-18 02:37:04	321	2020-07-13 21:56:23
322	L949464	o001go	65 Dayton Pass	2020-08-02 06:07:30	322	2020-07-25 20:33:52
323	J548418	c855ku	59899 Becker Plaza	2020-09-22 13:03:19	323	2020-06-18 00:19:49
324	D349791	c368ve	39 Katie Avenue	2021-05-14 23:06:18	324	2021-04-05 16:22:51
325	I559170	g847xe	07 Welch Hill	2021-01-07 18:47:46	325	2020-09-28 15:51:30
326	S159369	b924yr	61073 Sheridan Way	2020-08-04 21:03:59	326	2021-02-25 07:18:21
327	E078227	l638lm	38 Blaine Plaza	2020-11-15 15:57:50	327	2020-11-04 00:27:43
328	F778201	q808xf	701 Autumn Leaf Lane	2020-10-20 13:03:22	328	2021-01-18 13:42:05
329	F997868	q286jd	6 8th Place	2021-02-17 10:27:31	329	2020-09-10 15:48:45
330	B626856	q454ur	3997 Erie Parkway	2021-04-20 20:52:06	330	2020-07-26 22:56:16
331	N004532	q239zh	09 Dapin Junction	2020-10-15 15:30:34	331	2020-09-06 18:33:45
332	G225146	b974dl	1228 Knutson Alley	2020-12-07 18:45:45	332	2021-03-17 05:31:03
333	Y160751	f635vd	4 Randy Alley	2021-04-08 13:37:19	333	2020-09-03 19:53:43
334	Q686098	q553kg	16267 Walton Crossing	2020-12-16 22:56:30	334	2021-02-02 00:22:10
335	P351243	m870vk	3 Hazelcrest Crossing	2020-06-04 22:33:03	335	2020-07-13 11:03:12
336	D783689	a536xf	3932 Eastwood Street	2020-09-02 21:24:37	336	2021-02-03 07:58:48
337	E327880	h826rz	6 Ridgeway Center	2020-08-19 00:30:53	337	2020-10-28 09:50:33
338	B378045	z751mz	10 Daystar Place	2020-08-01 21:28:51	338	2020-06-14 02:31:26
339	Q384059	v286ix	2 Coolidge Street	2021-02-18 23:31:02	339	2020-06-15 05:34:12
340	V351407	z072gb	16801 Dapin Street	2021-01-01 13:17:44	340	2020-10-12 19:39:14
341	M497511	a979wm	33 Golden Leaf Lane	2020-12-07 19:47:22	341	2020-07-13 08:14:05
342	Z609567	o783bt	74196 Truax Place	2021-02-24 23:16:12	342	2020-07-26 17:00:41
343	T706913	z054jl	04 Mandrake Park	2021-01-11 21:07:43	343	2020-10-01 05:12:20
344	E600936	b107rx	96 Goodland Terrace	2020-07-24 09:32:21	344	2020-06-01 12:10:34
345	C938900	o009un	17 Fisk Lane	2020-12-21 02:02:53	345	2021-05-12 11:56:10
346	X561760	h832tg	1 Myrtle Center	2021-03-29 18:42:56	346	2020-05-24 21:15:17
347	K773391	k814xc	693 Huxley Street	2020-12-30 16:08:11	347	2020-05-26 00:42:00
348	N704066	f537wr	9 Kim Pass	2020-07-03 15:48:32	348	2021-04-23 00:58:15
349	E959638	g459my	59820 Pond Parkway	2020-12-02 21:12:37	349	2020-12-08 14:26:32
350	R696073	c784jo	0761 Corry Park	2021-04-01 05:39:08	350	2021-01-14 09:35:13
351	I619742	q911ow	5320 Aberg Park	2020-07-18 04:33:56	351	2020-10-24 21:42:59
352	I444606	g926bj	2 Goodland Alley	2020-08-27 06:11:12	352	2021-04-25 13:58:34
353	Z974465	h995mt	9 Oriole Plaza	2020-11-11 18:49:55	353	2020-06-10 03:22:32
354	V935457	d879nu	178 Rutledge Park	2021-04-11 21:46:12	354	2020-08-11 19:48:23
355	H746561	u537kz	356 Autumn Leaf Drive	2021-02-01 20:19:31	355	2021-04-19 23:14:12
356	N226665	s053xy	8776 Karstens Point	2020-08-25 13:31:52	356	2020-07-17 10:28:31
357	S787797	i446li	18 Ohio Junction	2021-01-03 17:44:47	357	2020-09-09 14:02:28
358	X751051	u100pw	1781 Novick Terrace	2020-10-28 18:52:45	358	2020-11-27 04:54:18
359	L682013	n284ol	943 Namekagon Road	2021-05-14 05:21:00	359	2020-10-10 21:30:55
360	S882206	m838jl	01447 Lakewood Gardens Hill	2021-04-28 03:50:44	360	2020-12-10 05:10:59
361	J467706	c696qw	17 Tennyson Crossing	2021-02-05 03:24:47	361	2021-02-20 07:03:35
362	S383739	o577tl	55840 Sachtjen Hill	2020-09-20 10:12:28	362	2021-01-12 09:10:16
363	F210865	z629gu	7248 Milwaukee Court	2020-08-14 11:51:59	363	2020-10-13 23:19:08
364	X303135	y087ld	3236 Maryland Park	2020-11-24 03:13:45	364	2020-07-17 09:51:55
365	Y763990	l502li	29227 Stuart Way	2020-06-21 02:04:09	365	2020-10-20 12:43:20
366	E043243	r490ox	10 Tennyson Road	2020-08-11 22:41:56	366	2020-06-13 08:37:49
367	H102532	f859on	2627 Tony Center	2021-02-02 15:06:46	367	2020-06-06 19:33:09
368	K100324	y947el	8614 Wayridge Court	2021-02-19 07:56:05	368	2020-09-25 08:57:07
369	W620357	f824ul	46 Hudson Hill	2021-04-13 15:34:10	369	2021-04-28 02:16:56
370	G832730	b713hx	883 Erie Point	2020-10-02 15:16:01	370	2021-05-21 05:57:13
371	H883431	b922ia	5351 Oakridge Lane	2020-12-22 18:50:53	371	2021-01-20 14:56:48
372	P199294	l482ds	17860 Sycamore Parkway	2020-07-03 18:17:01	372	2021-02-18 22:25:19
373	T437384	g964qm	93854 Packers Point	2021-05-13 07:43:00	373	2021-02-23 00:58:48
374	N586556	j798bx	0 Northridge Crossing	2021-04-01 17:38:59	374	2020-11-17 20:39:54
375	D895839	j014ki	6191 Ohio Avenue	2021-05-02 21:37:11	375	2021-01-16 10:35:04
376	N391455	j694oa	212 Ridgeview Lane	2021-05-09 11:19:21	376	2020-12-21 20:41:23
377	S737234	o180sa	29533 Cordelia Place	2020-06-16 12:46:01	377	2020-11-30 10:06:07
378	Q293103	h611mq	757 Ludington Hill	2021-03-25 13:23:20	378	2020-07-03 23:21:48
379	R412509	t245ro	7 Miller Park	2020-11-08 13:49:58	379	2020-07-09 22:07:08
380	P886645	c622zt	04 Linden Hill	2020-11-28 16:06:30	380	2020-08-31 01:32:30
381	E444029	f030cp	68 Corben Alley	2020-10-14 19:32:11	381	2021-01-18 20:33:40
382	P924729	l205as	946 Boyd Park	2020-06-29 18:48:17	382	2021-03-06 12:54:07
383	L072580	q210yd	86 Mockingbird Road	2020-10-06 11:52:54	383	2021-03-11 09:00:23
384	Y891252	r282tk	6008 Meadow Valley Plaza	2021-03-29 09:28:03	384	2020-12-28 23:59:30
385	Z553722	c108so	138 Graceland Parkway	2021-04-01 22:23:06	385	2021-05-21 01:31:06
386	S951249	c388yr	45 Marcy Trail	2020-12-07 02:30:51	386	2020-06-01 02:44:01
387	L345102	b740jf	628 Manitowish Road	2021-02-13 05:03:31	387	2021-02-25 09:37:34
388	S994806	o587md	0955 Mesta Road	2020-08-12 15:22:25	388	2021-01-21 11:31:47
389	X413040	u066mt	45983 Ridge Oak Place	2020-08-13 13:53:39	389	2020-09-15 06:57:29
390	F996226	x372ck	655 5th Hill	2020-12-11 02:54:18	390	2020-12-21 00:26:57
391	X350085	q290pt	8 Dakota Lane	2020-09-17 11:19:00	391	2021-01-29 23:33:21
392	A311539	k559rn	02477 Miller Trail	2020-08-06 22:22:50	392	2021-01-07 02:49:07
393	U357563	h121ia	348 Hollow Ridge Drive	2020-06-18 19:48:30	393	2020-06-08 10:59:30
394	W453836	z439xx	274 Shoshone Plaza	2020-11-20 05:59:47	394	2020-07-30 18:42:51
395	B842273	k253hq	645 Briar Crest Pass	2021-04-27 01:28:27	395	2020-12-31 12:53:30
396	I047421	d387mf	040 Butternut Trail	2020-12-03 17:46:19	396	2020-12-30 17:02:36
397	D614439	y893kx	8307 Hagan Court	2020-09-16 11:02:21	397	2020-06-08 11:16:04
398	N023033	j890wt	56 Del Sol Lane	2020-07-23 08:39:07	398	2020-07-18 23:32:38
399	M495277	i788iu	34 Annamark Place	2021-05-23 12:47:21	399	2020-09-07 12:28:59
400	G105488	i360lq	474 International Plaza	2020-11-15 10:35:30	400	2021-04-08 10:46:23
401	O135656	o418fc	8 Ilene Point	2020-07-13 21:05:41	401	2020-08-18 15:22:46
402	Q239988	r504td	3 Village Green Circle	2020-09-07 05:30:11	402	2020-07-21 17:35:18
403	Z431544	l293uo	42 Lakeland Terrace	2020-12-07 21:31:25	403	2020-11-14 16:46:53
404	G105503	l494fc	3 Express Place	2021-02-01 19:05:04	404	2020-09-10 14:35:52
405	I069765	g786ul	61910 Eliot Court	2020-06-13 09:04:55	405	2020-06-23 11:17:26
406	L178831	f751cl	5 Moland Pass	2020-10-11 20:21:40	406	2021-04-10 02:03:28
407	R525588	e806gj	54295 Derek Street	2020-06-20 04:01:28	407	2021-05-22 07:57:50
408	O204856	y160jj	901 Summit Point	2020-10-18 16:34:56	408	2021-04-27 16:28:53
409	F827696	k307bm	58 Pawling Center	2020-12-20 19:00:01	409	2020-12-18 17:17:17
410	F658126	y668yy	2994 Upham Hill	2020-11-13 14:28:23	410	2020-06-04 23:16:52
411	X399694	l121ip	10 Eastlawn Hill	2021-02-24 03:43:54	411	2020-11-04 13:05:36
412	R368718	j664mk	02144 Anzinger Hill	2021-01-11 03:05:02	412	2020-06-03 23:31:02
413	R998325	e813jw	0 Welch Street	2020-09-29 07:37:18	413	2020-07-27 13:13:33
414	J839564	z487ay	3963 Reinke Lane	2020-07-29 22:13:23	414	2020-09-18 04:08:51
415	Z555674	n207sn	73 Continental Park	2021-04-08 13:55:48	415	2020-11-21 10:01:29
416	I304480	q481fk	1961 Algoma Terrace	2020-10-02 15:01:02	416	2020-06-01 21:09:42
417	G619210	v186ad	0780 Miller Park	2021-04-02 12:09:58	417	2021-02-26 12:23:33
418	U684260	h485zk	1 Swallow Pass	2020-08-02 22:46:10	418	2021-04-25 18:27:34
419	A000560	g681cp	34 Fieldstone Trail	2020-11-18 15:30:08	419	2021-02-27 08:49:54
420	Q491010	e592vy	45 Nancy Circle	2020-11-22 21:45:49	420	2021-04-20 13:32:30
421	R513299	u668nu	669 Havey Street	2020-07-30 14:04:38	421	2020-05-28 04:33:58
422	L566685	r319jr	6080 Warner Court	2021-01-21 00:30:29	422	2020-06-24 08:42:12
423	X844457	f736ow	81068 Mariners Cove Park	2020-10-25 02:12:42	423	2021-01-25 10:47:16
424	K920502	c922ny	8 Nancy Court	2021-01-11 04:25:31	424	2020-12-08 22:14:39
425	N827117	h451uy	00445 Westridge Place	2021-05-21 22:11:22	425	2020-08-29 13:45:57
426	D751394	a918ag	8472 Farmco Road	2021-05-14 09:44:31	426	2020-10-15 14:09:06
427	M627800	i405lj	6438 Sunfield Avenue	2020-06-10 11:47:20	427	2020-10-13 07:10:13
428	F136763	x522ts	601 Texas Road	2020-09-23 14:03:49	428	2021-01-08 04:35:11
429	I525148	b084pg	905 Bayside Lane	2021-05-22 16:31:01	429	2021-05-04 20:22:27
430	P824543	j512pz	3 Grayhawk Hill	2020-11-17 13:07:06	430	2020-10-29 22:15:23
431	A099825	u159cn	63874 Monterey Trail	2020-12-25 19:14:03	431	2021-04-01 02:51:01
432	C987003	f075rp	895 Nelson Way	2020-11-21 09:28:27	432	2021-01-25 07:46:48
433	H235563	q008xj	1167 Continental Crossing	2020-06-06 06:33:33	433	2020-09-28 09:54:27
434	G269717	x418ex	54 Lindbergh Way	2020-12-21 21:22:37	434	2020-06-01 12:50:01
435	Q855594	j635nn	25360 Brown Court	2021-04-22 00:26:14	435	2020-12-02 16:25:41
436	D351225	v077em	6123 3rd Avenue	2020-11-25 04:34:19	436	2020-11-30 23:33:52
437	H058246	c392fo	2584 Dahle Alley	2021-02-13 15:18:47	437	2020-10-25 09:44:52
438	L884191	p051ec	8322 Sauthoff Terrace	2020-12-01 22:49:35	438	2020-06-23 21:01:37
439	G084403	a685uo	74593 Main Way	2021-03-28 13:14:16	439	2020-06-20 11:59:58
440	S970400	b163gd	52071 Morningstar Crossing	2020-12-13 07:37:39	440	2020-12-22 03:20:23
441	P047811	a190zp	684 Toban Way	2020-12-09 17:31:20	441	2020-06-24 16:05:50
442	M880170	q903ln	522 Center Terrace	2020-09-04 00:08:37	442	2021-02-17 00:56:59
443	J307207	a502eh	0 Esch Pass	2021-05-12 22:27:19	443	2020-11-14 04:01:07
444	C851020	o326gb	4 Dapin Circle	2020-11-28 21:20:25	444	2021-01-01 14:22:36
445	N576127	a952dt	939 Northland Road	2020-12-15 20:32:13	445	2021-02-09 02:20:06
446	M645054	g321ol	91 Hoard Hill	2020-05-30 21:45:08	446	2020-09-28 21:25:41
447	N197729	e256nm	8 Weeping Birch Plaza	2020-10-15 10:32:27	447	2020-06-06 07:12:54
448	Q116319	p886dn	8 Westport Way	2020-08-14 14:04:07	448	2021-03-22 00:18:06
449	K407648	i355gk	13 Northfield Court	2021-02-24 12:35:27	449	2021-04-21 16:15:30
450	R138969	m939zh	0 Northview Crossing	2020-06-28 04:59:19	450	2020-12-09 05:26:51
451	C108180	z133hs	35875 Main Parkway	2020-10-26 09:10:21	451	2020-11-23 14:55:51
452	C507962	m328wh	8808 Westridge Alley	2020-10-19 21:57:04	452	2021-03-28 00:07:59
453	R990309	o565nl	7 Sauthoff Street	2021-01-20 08:02:58	453	2020-08-18 13:18:24
454	H016881	z288we	942 Kipling Hill	2020-12-14 10:32:37	454	2020-08-22 08:19:32
455	S962938	h002ji	72 Dixon Terrace	2020-06-20 21:33:45	455	2021-03-16 15:09:39
456	G322650	d988wa	628 Grover Street	2021-03-03 15:47:14	456	2020-06-12 09:07:49
457	U490510	d453co	63 Oriole Alley	2020-09-27 00:39:00	457	2020-08-05 23:37:07
458	J046005	g654wy	9994 Norway Maple Crossing	2020-12-06 07:28:19	458	2020-12-19 03:49:24
459	V860843	r889uf	7 Hoepker Park	2021-01-08 20:39:51	459	2021-04-29 05:58:51
460	T653807	o299it	321 Mayfield Hill	2020-10-28 16:51:11	460	2021-05-03 10:18:08
461	L645450	r816mt	22 Kennedy Alley	2020-06-14 00:37:18	461	2020-09-05 12:57:11
462	D241546	n242ds	3 Warrior Hill	2021-03-25 22:23:10	462	2020-08-05 05:10:02
463	Q584583	g974tv	55 2nd Drive	2020-09-14 08:04:23	463	2020-12-23 15:22:25
464	O985882	t052kd	14 Colorado Plaza	2020-06-06 02:11:52	464	2021-05-02 23:32:03
465	N424304	t484vl	658 Monica Crossing	2020-07-02 22:24:55	465	2020-12-21 11:11:50
466	Y628726	m286mx	04181 Havey Terrace	2020-09-26 14:11:05	466	2020-10-08 04:45:13
467	H622470	o849sz	2499 Vidon Way	2020-09-22 17:19:49	467	2020-10-16 13:29:11
468	L358245	e791tm	9438 Southridge Park	2020-09-14 16:13:20	468	2020-05-29 07:56:26
469	I047044	h742gq	7 Glacier Hill Street	2020-07-11 03:16:08	469	2020-12-12 13:26:16
470	Y423202	e303de	0873 Cambridge Park	2021-02-26 11:17:02	470	2020-09-14 19:43:12
471	Q568451	i333xa	97772 Corben Junction	2021-01-15 20:26:18	471	2020-07-30 00:20:24
472	M691824	s824kv	174 Mariners Cove Junction	2020-12-01 19:35:17	472	2020-12-18 01:02:09
473	X460928	j296hk	73713 Esker Court	2020-06-24 17:21:59	473	2021-04-26 00:53:10
474	L426601	y037rq	30613 Hanson Plaza	2021-02-21 23:38:14	474	2020-06-26 20:19:42
475	B844777	r826gc	00152 Milwaukee Court	2020-10-17 09:03:55	475	2020-09-15 23:42:25
476	K544293	c886gl	08231 Beilfuss Junction	2021-04-14 01:41:10	476	2021-02-26 12:22:04
477	L996751	h110mx	802 Lakewood Gardens Hill	2020-07-10 07:34:46	477	2021-02-27 22:46:37
478	A853180	z264xw	95 Sauthoff Center	2021-05-13 01:17:36	478	2020-12-15 14:39:30
479	S311330	o199fd	4 Delladonna Road	2021-03-30 11:12:18	479	2021-05-03 08:15:34
480	V018774	l936rh	9 Myrtle Court	2021-01-27 10:53:50	480	2021-02-10 21:47:36
481	A999007	i527xt	05 Old Shore Lane	2020-09-03 16:17:43	481	2020-10-31 01:10:41
482	P567759	y831uk	168 Gulseth Court	2020-06-23 19:02:10	482	2020-06-11 12:05:32
483	C271800	y318ax	630 Shasta Parkway	2020-07-28 20:08:24	483	2021-03-16 09:20:54
484	Q259556	y556zg	93 Kipling Drive	2021-02-04 15:54:05	484	2021-02-09 09:44:31
485	T197617	v896je	9 Ryan Parkway	2021-02-07 10:13:05	485	2020-10-06 20:45:21
486	Y828224	a303cz	8449 Brentwood Center	2020-06-30 07:48:37	486	2021-03-11 11:58:52
487	I765585	r717jg	64 Orin Lane	2021-05-15 07:54:05	487	2020-12-11 20:00:48
488	M922988	f102ck	1 Eagan Avenue	2021-03-24 21:16:57	488	2021-01-13 15:59:03
489	K996713	p502qg	107 Montana Center	2021-01-07 20:43:54	489	2020-09-13 15:07:37
490	E616119	b034qs	7 Bobwhite Terrace	2021-03-20 15:18:32	490	2020-08-26 11:51:10
491	L151745	q927nx	187 Truax Terrace	2020-08-27 23:42:50	491	2020-11-19 07:18:45
492	Q568956	c005nr	0 Thompson Avenue	2020-09-08 09:09:07	492	2020-06-15 10:27:52
493	Q455736	b400bw	3478 Monica Terrace	2021-05-23 16:42:46	493	2021-03-07 23:41:39
494	O399218	i081dz	18 Thackeray Trail	2020-07-30 22:48:23	494	2020-06-12 22:15:46
495	U463962	d404ou	4127 Barby Trail	2021-04-13 03:33:13	495	2020-12-30 03:13:52
496	B612320	o153ls	31468 Hauk Drive	2021-04-12 16:10:53	496	2021-01-20 19:39:23
497	V643922	s513ok	7134 Loomis Alley	2020-08-12 15:58:09	497	2020-10-14 01:31:03
498	F908391	k133hr	3 Bowman Court	2020-09-13 06:17:54	498	2021-01-30 09:23:26
499	K459028	z609ks	6705 Menomonie Center	2020-11-24 16:07:50	499	2020-10-02 12:16:30
500	T042437	b711on	7771 Warner Place	2021-02-25 04:47:41	500	2020-11-07 23:18:55
501	I505955	t850hu	1 Barby Lane	2021-01-25 23:37:39	501	2020-08-20 08:13:11
502	M121769	f683ix	878 Leroy Avenue	2020-07-09 13:40:36	502	2020-09-22 08:43:27
503	U957890	e004du	1036 Briar Crest Pass	2021-01-13 12:03:27	503	2020-10-21 08:40:16
504	V228029	b663gp	91292 Kennedy Drive	2021-01-22 04:16:57	504	2021-03-20 13:34:14
505	Q634425	p402bx	7 Duke Plaza	2021-02-01 00:47:53	505	2020-12-27 15:39:31
506	N918251	q131jb	13 Elmside Center	2021-01-03 01:08:23	506	2020-08-23 09:14:29
507	P154635	g205ae	494 Merry Plaza	2020-10-21 22:49:58	507	2021-01-19 19:34:33
508	O487096	e503nh	51913 Crowley Lane	2020-11-12 04:20:43	508	2020-12-07 05:47:24
509	X280256	i031od	92 Old Shore Court	2021-05-19 12:17:31	509	2021-01-08 09:54:55
510	E249367	m658yf	0 Ronald Regan Court	2021-04-18 22:28:46	510	2021-01-19 06:45:43
511	C679606	m840tm	5704 Prairieview Parkway	2020-07-06 08:44:00	511	2021-04-29 06:34:48
512	I372780	z229jf	6143 Stoughton Alley	2020-11-06 17:15:40	512	2021-02-18 17:43:00
513	I369363	n245bz	97027 Pennsylvania Drive	2020-11-02 01:13:26	513	2021-04-02 07:49:05
514	Q105562	f558aw	56359 Vermont Place	2021-04-24 02:29:45	514	2020-11-21 08:06:11
515	L226615	j289bn	0 Stephen Point	2020-11-20 10:43:04	515	2021-05-03 06:02:30
516	K625285	w595pp	6193 Cherokee Junction	2020-12-20 13:47:54	516	2021-03-08 04:25:56
517	U443283	j016rj	6 Spaight Alley	2020-05-28 12:56:37	517	2020-12-28 14:37:26
518	X164812	e292gz	6425 North Road	2021-05-22 11:11:23	518	2021-04-14 10:58:20
519	Q651722	k669di	1 Granby Center	2020-11-02 17:53:50	519	2021-04-18 07:08:05
520	D976581	z471nh	91 Crowley Alley	2020-08-29 00:56:37	520	2020-05-26 02:58:03
521	J547737	b445zo	28787 Manley Crossing	2021-03-01 23:35:58	521	2021-03-10 16:04:00
522	J752223	i618zt	6405 Weeping Birch Alley	2020-08-10 13:09:01	522	2020-05-24 04:37:43
523	D538025	f800bv	90457 Village Pass	2020-12-08 20:10:20	523	2020-12-05 08:36:55
524	D224826	s257ik	0 Lukken Road	2020-10-11 20:03:04	524	2020-06-27 17:10:11
525	A585933	n799wf	5 Trailsway Parkway	2020-11-27 13:37:11	525	2020-06-20 14:48:25
526	K793320	g792bq	7 Mcguire Park	2021-03-18 00:17:42	526	2021-01-04 13:52:06
527	Z310563	c566gr	9648 Green Ridge Way	2021-04-11 20:02:00	527	2021-05-20 18:58:20
528	I798460	u326rc	32355 Butterfield Avenue	2020-11-04 08:47:50	528	2020-09-05 00:28:16
529	Y317121	j399cd	023 Fuller Plaza	2021-02-13 01:54:55	529	2021-04-29 10:00:03
530	S320575	t440lk	4636 Springs Terrace	2021-01-12 19:21:47	530	2020-08-10 07:26:34
531	U611777	s863og	20828 Lakewood Gardens Road	2020-09-05 22:18:23	531	2021-01-30 19:48:52
532	O417287	s466er	9 Columbus Point	2020-12-27 15:34:15	532	2021-04-05 03:33:25
533	V009839	r834jj	742 Namekagon Lane	2021-03-08 20:10:00	533	2020-08-20 00:59:04
534	C210467	j429pf	33 Briar Crest Drive	2020-07-30 01:16:46	534	2021-01-21 23:13:53
535	C449172	w369wt	37 Declaration Circle	2021-03-08 15:12:31	535	2021-03-11 13:01:18
536	E481651	k098up	9066 Barnett Place	2020-09-20 07:57:37	536	2020-12-13 02:52:57
537	W612584	z354sw	059 Jenifer Place	2020-09-03 13:17:02	537	2021-04-02 07:11:52
538	Z893317	v864ef	4 Del Sol Center	2021-04-24 23:22:56	538	2020-06-14 03:45:23
539	B640346	b509wa	88979 Ilene Alley	2021-02-13 21:48:36	539	2020-09-03 16:06:36
540	Q149074	p831kg	480 Evergreen Park	2021-02-10 13:04:29	540	2020-12-22 05:31:15
541	K803277	g291ui	01657 Hoard Plaza	2020-07-03 15:44:43	541	2020-08-04 23:17:40
542	R877062	c723uj	508 Bunker Hill Center	2020-07-12 16:03:49	542	2021-02-28 13:57:24
543	Y817452	c546mm	0 Hansons Crossing	2020-06-11 03:27:18	543	2020-08-07 04:15:05
544	I881190	z623dr	79 Cody Trail	2020-12-06 09:41:12	544	2020-06-22 00:34:31
545	C757972	c991cd	20215 Dahle Alley	2021-01-21 09:46:16	545	2020-12-10 20:34:25
546	G358605	p547di	365 Carioca Alley	2021-01-30 09:37:27	546	2020-12-08 08:46:04
547	L527095	f673ki	936 Kedzie Point	2020-08-15 09:12:33	547	2021-01-22 12:53:09
548	D771012	p110dr	01 Lighthouse Bay Drive	2021-02-06 15:52:54	548	2020-06-06 20:47:11
549	I810925	m871xm	7 Vermont Avenue	2021-03-01 16:52:56	549	2020-05-30 20:59:16
550	V308603	i297vc	96180 New Castle Park	2020-10-18 17:42:18	550	2021-03-15 06:21:29
551	B422345	c412zu	44748 Sundown Alley	2020-05-24 16:08:24	551	2020-11-08 08:58:58
552	L899224	a737hk	213 Dwight Center	2020-07-20 18:46:57	552	2020-12-31 03:13:06
553	I417247	d543ph	57 Ohio Junction	2020-10-12 00:57:36	553	2020-06-24 17:45:38
554	J024555	o145lr	0065 Merchant Drive	2021-03-12 23:24:01	554	2021-04-16 22:21:19
555	G473108	v231gf	25257 East Way	2020-11-24 22:15:58	555	2020-08-31 16:06:30
556	O358496	g431aw	9 Knutson Park	2020-07-16 20:44:24	556	2021-03-11 15:58:42
557	R044524	b813np	4 Bonner Pass	2021-05-12 23:41:47	557	2020-07-02 11:21:59
558	P348873	n273me	1 Eagan Street	2021-03-26 07:02:45	558	2020-12-23 18:11:05
559	P248159	v064rt	8 Muir Court	2021-04-03 23:15:31	559	2021-02-17 10:49:31
560	J237426	t062hg	58 Cordelia Way	2020-08-11 19:38:26	560	2020-08-30 01:34:03
561	R842590	w404ol	8 Sutteridge Drive	2021-05-10 10:03:20	561	2020-06-14 12:48:37
562	L036772	t975ks	398 Loftsgordon Park	2020-11-24 13:09:49	562	2020-06-24 11:03:23
563	K337894	s529rg	35 Lillian Park	2020-06-10 13:36:04	563	2020-10-07 05:55:51
564	U619463	p026vh	3 Spaight Parkway	2020-12-22 02:35:47	564	2020-06-20 00:15:49
565	J947873	u127db	7 Mosinee Crossing	2021-05-11 10:07:03	565	2021-05-21 14:19:01
566	Q206766	z820tw	605 Jackson Trail	2020-07-31 06:46:54	566	2020-10-07 01:29:35
567	J477136	d198bw	96167 Center Avenue	2021-01-05 06:48:17	567	2021-05-03 21:33:21
568	D196285	n182rn	399 Packers Alley	2020-11-24 09:57:47	568	2021-05-06 16:42:34
569	O641717	k364vr	52 Burrows Plaza	2020-08-02 14:34:23	569	2021-01-15 11:06:56
570	N082212	g345ke	1 Pennsylvania Court	2020-07-26 01:06:20	570	2021-02-08 10:26:46
571	K403481	r009cm	471 Portage Parkway	2020-09-11 15:33:55	571	2021-04-29 16:32:29
572	J129729	m539vx	6403 Mcguire Point	2020-06-12 08:56:56	572	2021-03-26 18:05:36
573	A498421	a801kg	4576 Carey Lane	2021-01-03 18:11:53	573	2020-09-13 04:21:05
574	N067029	y593cg	35194 Elmside Circle	2021-03-06 02:26:34	574	2020-11-30 20:56:59
575	F540119	m161mg	5992 Crescent Oaks Road	2020-11-04 17:58:27	575	2020-09-14 13:24:30
576	W793106	p547ne	137 Rusk Circle	2020-10-15 21:27:23	576	2021-02-17 03:18:35
577	F012862	t587we	64859 Onsgard Terrace	2021-05-10 17:50:31	577	2021-04-11 23:44:48
578	K253105	u556tk	8 Spohn Way	2020-06-23 18:41:54	578	2021-02-17 12:02:06
579	G878592	m078mf	6566 Debra Hill	2021-03-03 00:53:41	579	2021-04-21 14:27:36
580	X046088	x345jj	8022 Dunning Way	2021-03-31 12:11:24	580	2020-10-17 00:25:26
581	C377971	v053au	73874 Anthes Center	2020-11-26 23:05:05	581	2020-10-17 18:56:07
582	C667308	z491db	710 Melrose Junction	2021-01-14 14:22:44	582	2020-07-01 17:40:17
583	G792035	l305vm	45 Stang Crossing	2020-12-05 08:52:56	583	2020-09-26 01:35:03
584	N040807	r344rr	2 Arrowood Lane	2020-06-22 12:25:54	584	2020-06-17 00:49:25
585	N732026	p094uy	526 Toban Terrace	2021-03-25 01:16:20	585	2021-04-30 01:48:16
586	M883188	i597hu	1 Russell Street	2021-01-13 22:28:27	586	2020-11-20 18:58:02
587	F058783	l622ho	14 North Plaza	2021-02-16 18:11:37	587	2021-02-27 10:45:48
588	S413749	a299em	8 Crownhardt Drive	2020-11-03 23:45:15	588	2020-12-21 12:21:10
589	L700290	a307en	2 Sunnyside Drive	2020-10-22 17:26:53	589	2020-09-09 11:51:30
590	R762703	b858eh	8 Bunker Hill Alley	2020-10-05 08:39:57	590	2020-10-09 08:11:21
591	R996992	c418wk	3197 Novick Point	2020-07-05 03:16:34	591	2020-11-09 16:28:40
592	U224904	v549ij	35336 Bellgrove Parkway	2021-04-26 10:36:18	592	2020-12-26 10:00:58
593	P480446	b124hk	8379 Scoville Trail	2020-07-25 04:25:36	593	2020-08-12 03:01:00
594	I345624	x038dv	866 Clyde Gallagher Pass	2020-06-18 16:22:50	594	2020-11-07 17:12:03
595	T763919	t258oo	3905 1st Lane	2020-06-02 12:19:07	595	2021-05-14 17:01:02
596	Z464700	w236sm	279 Lerdahl Avenue	2021-04-21 08:26:14	596	2021-01-20 18:18:02
597	I432209	v927xd	626 Shelley Parkway	2021-04-12 08:09:56	597	2020-11-01 19:54:31
598	A662401	i938rr	3 Ridgeview Court	2020-08-09 06:44:20	598	2020-05-30 22:50:15
599	C844236	g738sn	17 Delladonna Way	2020-11-08 15:02:47	599	2021-01-08 14:33:43
600	G494492	g660uo	344 Clyde Gallagher Junction	2021-02-14 17:48:49	600	2021-02-16 08:53:36
601	A072823	w512ac	3 Barby Alley	2021-02-21 23:56:42	601	2021-01-25 10:54:17
602	Q995423	f376fd	42656 Dapin Circle	2021-02-06 16:43:37	602	2020-05-29 06:26:51
603	L071226	i249df	825 Grim Court	2020-07-09 16:26:17	603	2021-01-02 02:47:36
604	V786085	e866ig	3 Kropf Circle	2020-11-20 12:30:14	604	2020-06-10 00:34:19
605	W500068	f110nv	33 Valley Edge Circle	2020-08-31 15:15:10	605	2021-01-13 21:17:56
606	F925967	h148oy	12253 Farwell Circle	2021-05-03 18:32:19	606	2021-04-25 07:35:07
607	Z053111	j172jp	85413 Spaight Drive	2021-02-18 16:56:52	607	2020-12-28 16:29:22
608	Y086460	x672fk	89 Prairie Rose Street	2021-03-13 09:35:47	608	2020-09-28 16:05:53
609	K556821	c654qb	9577 Ridge Oak Way	2021-04-10 12:05:04	609	2020-11-08 09:47:23
610	S525385	u241mi	8069 Vera Pass	2021-03-17 00:36:28	610	2020-08-29 09:26:56
611	K460178	a195ke	0249 Delladonna Lane	2021-05-04 14:39:59	611	2021-01-16 06:47:44
612	H571480	d967dn	5558 Kennedy Road	2020-11-07 12:21:41	612	2020-12-14 13:41:37
613	I834958	b219by	6 Service Place	2021-05-09 10:45:47	613	2020-08-06 07:52:29
614	D365467	d925we	034 Homewood Parkway	2021-02-17 03:13:26	614	2020-07-04 07:08:15
615	U063128	z308ip	5690 Derek Point	2020-06-12 16:55:29	615	2020-09-18 00:56:05
616	U907300	e221ar	03 Division Way	2021-01-08 21:15:07	616	2020-12-14 17:42:33
617	N788327	p685qa	8387 Talmadge Circle	2020-08-26 01:00:23	617	2021-02-26 15:53:12
618	I328216	c528dp	4 Daystar Avenue	2021-05-12 11:27:08	618	2020-07-20 07:21:21
619	V451138	r746mk	68 Aberg Parkway	2021-02-23 14:02:17	619	2021-01-28 07:37:09
620	W750878	t990ww	24 Iowa Center	2021-01-18 07:43:19	620	2020-12-28 18:44:52
621	A681993	b323jo	21435 Pine View Crossing	2020-10-24 14:19:47	621	2021-05-17 18:22:00
622	B845853	a126ub	10050 Badeau Plaza	2020-08-09 17:21:09	622	2020-12-26 19:21:55
623	U787342	w558bs	7 Commercial Lane	2020-08-09 00:40:46	623	2020-10-10 12:18:07
624	Y070188	t898en	33 Forster Court	2021-03-15 00:57:43	624	2020-11-13 07:25:06
625	O075635	q012ds	4485 Prairie Rose Circle	2020-11-11 06:35:23	625	2020-07-13 07:55:16
626	L399056	t696ph	235 Columbus Avenue	2020-08-11 14:28:30	626	2020-06-05 22:32:20
627	M744186	s060bg	494 Corben Circle	2020-09-07 13:51:50	627	2020-11-02 10:18:18
628	J360383	j394gk	530 Tennyson Place	2021-03-09 02:32:52	628	2020-08-30 13:09:21
629	Y809527	x703qp	64 Jana Parkway	2020-10-16 11:59:58	629	2021-03-16 15:49:02
630	D829928	w729lc	27950 Westridge Way	2020-07-12 15:03:46	630	2021-03-07 20:40:06
631	Q589919	w578un	62304 Scoville Court	2020-09-20 11:54:26	631	2021-01-29 06:03:02
632	V402138	o886bs	807 Trailsway Drive	2020-07-30 10:02:47	632	2021-03-16 08:38:30
633	G210058	q257zr	54 Florence Court	2020-11-17 12:04:48	633	2021-04-28 18:19:56
634	A103846	n512yo	3119 Norway Maple Drive	2021-03-19 02:39:54	634	2020-05-26 19:11:11
635	Z237869	e446mh	908 Del Mar Terrace	2020-09-08 11:24:59	635	2020-06-11 20:00:48
636	D663481	s310ws	02 Kensington Circle	2020-06-30 02:12:10	636	2021-02-26 12:54:22
637	E075918	q322hh	5343 Dawn Park	2020-12-09 13:20:48	637	2021-02-26 14:27:33
638	R065336	f078ts	53451 Ruskin Crossing	2020-06-06 07:20:36	638	2021-03-28 08:57:51
639	M573597	a033mr	9182 Petterle Crossing	2020-10-30 19:27:23	639	2020-10-28 14:13:11
640	A342629	h649kk	44 Sycamore Point	2021-04-19 07:55:33	640	2021-02-01 13:09:58
641	F621783	g268fl	202 Lien Alley	2020-06-19 20:31:42	641	2020-10-08 21:30:37
642	J205316	z618la	05 Mandrake Court	2020-06-02 11:14:23	642	2021-02-14 07:54:38
643	F831571	y988lh	787 Forest Plaza	2021-02-16 13:00:29	643	2021-03-01 18:11:43
644	Z931029	r203hz	82197 Helena Plaza	2020-10-18 05:46:17	644	2020-10-29 22:27:32
645	K294866	z776jy	133 Basil Avenue	2021-04-22 22:27:31	645	2020-08-14 02:42:22
646	W247800	m460ar	64 Sloan Park	2021-04-21 18:25:20	646	2021-02-12 17:33:15
647	I207992	k918ef	05 Alpine Parkway	2020-12-21 15:07:28	647	2020-09-13 03:09:19
648	G098108	j886kw	166 Graedel Terrace	2020-11-12 14:46:51	648	2021-03-19 05:50:03
649	I175697	e995dp	006 Bunting Road	2021-02-07 12:32:10	649	2021-04-15 08:37:55
650	Y413667	n890gt	59 Lien Trail	2020-06-23 03:09:56	650	2020-12-12 16:23:37
651	R601543	g388tb	636 Stang Point	2021-01-21 08:12:42	651	2020-08-02 12:55:30
652	O431535	d490hl	31931 Schiller Lane	2021-04-24 17:08:21	652	2020-11-02 21:27:37
653	L802465	l906xe	930 Moland Court	2020-08-14 01:53:12	653	2020-06-01 15:36:23
654	B944160	r019bb	628 Truax Hill	2021-01-22 10:50:27	654	2021-02-13 03:16:26
655	I818164	z810tw	26 Pleasure Circle	2020-08-31 16:14:23	655	2021-04-13 15:17:30
656	B958826	p712yv	6 Ridge Oak Parkway	2021-05-06 18:04:59	656	2020-05-24 03:58:10
657	Q070919	s881vg	6 Warrior Crossing	2020-06-01 09:15:38	657	2020-12-04 14:58:17
658	S206060	c554ms	9 Corben Road	2021-05-15 10:42:35	658	2021-01-22 10:07:23
659	B793160	v013sv	29644 Annamark Pass	2020-05-31 12:43:21	659	2020-12-28 02:40:14
660	D215902	y073bz	1779 Haas Avenue	2020-08-15 04:43:27	660	2021-02-19 09:41:21
661	N505253	a333rv	082 Service Street	2021-04-03 02:42:50	661	2020-12-29 15:16:32
662	N239070	y032xa	1 Bunting Street	2020-08-21 04:43:08	662	2020-10-26 02:33:46
663	C658414	f302yy	91925 Briar Crest Center	2020-08-18 18:31:37	663	2021-04-30 12:13:08
664	B012234	a382vf	55 Pierstorff Circle	2020-12-10 08:21:29	664	2020-09-26 03:44:10
665	E029921	e430vy	1596 Cascade Point	2021-02-15 16:02:33	665	2021-04-28 13:13:50
666	A326965	m977gc	465 Brentwood Pass	2021-05-08 12:58:20	666	2021-02-23 08:20:59
667	N391203	i248fx	0 Elka Parkway	2020-11-29 04:04:52	667	2020-10-10 17:41:15
668	Z269376	i542sp	9324 Mccormick Hill	2020-08-13 00:10:41	668	2020-10-13 05:43:44
669	B897146	a849eg	721 Anhalt Hill	2021-04-28 14:58:15	669	2020-08-31 21:17:46
670	V348718	d609mt	740 Old Gate Trail	2021-05-01 16:17:41	670	2020-12-16 02:17:41
671	Q368422	y093ib	49 Swallow Court	2020-07-09 08:19:29	671	2021-04-28 01:59:58
672	A547664	s005em	1 Lerdahl Junction	2021-04-08 01:32:48	672	2020-08-21 20:01:36
673	W324741	a519op	51 Tennessee Plaza	2020-08-25 20:29:00	673	2021-03-26 03:18:31
674	N895866	o278vp	9880 Helena Drive	2020-11-12 17:36:28	674	2020-10-04 14:46:34
675	W686169	u344ar	84 Prentice Lane	2020-08-06 12:27:10	675	2020-07-26 16:38:38
676	P607184	w541rc	433 Granby Crossing	2021-04-21 09:44:55	676	2021-03-06 21:48:37
677	P288457	c896pg	4 Hoffman Circle	2020-12-09 01:22:57	677	2020-05-29 04:12:29
678	U062134	z059hc	62873 Spaight Parkway	2021-04-23 07:18:19	678	2021-01-13 13:31:05
679	F448366	f732ev	0 La Follette Road	2020-11-02 19:12:37	679	2020-09-20 21:09:29
680	K753568	s448ph	9 Rockefeller Way	2020-10-05 21:57:08	680	2021-02-05 11:38:43
681	X504000	n417wg	04 Bowman Way	2021-05-22 11:27:42	681	2020-12-18 09:10:10
682	L902575	a123ei	65 Pennsylvania Street	2020-12-18 22:57:55	682	2020-10-25 19:15:42
683	B611271	u817oy	12 Ronald Regan Court	2021-03-16 18:08:44	683	2020-10-28 19:21:46
684	O058108	d639vf	42392 Killdeer Place	2020-12-09 22:41:17	684	2021-02-08 15:07:55
685	T892877	i899cb	4 Tennyson Parkway	2021-01-07 09:58:45	685	2020-07-12 12:36:59
686	T310128	o246zn	7 Fairview Point	2021-01-07 20:54:35	686	2021-02-11 10:21:12
687	K360139	y554fz	716 Arizona Drive	2020-07-01 12:54:14	687	2021-02-01 12:06:18
688	M773554	z708dd	6 Dwight Plaza	2020-11-05 17:53:36	688	2021-02-20 08:47:58
689	X890299	b693bf	90022 Hansons Court	2020-09-06 14:36:35	689	2021-03-14 04:43:00
690	A517140	c252ja	91280 Union Avenue	2020-08-20 16:50:59	690	2020-12-31 20:29:56
691	T257818	z809hf	70308 Union Trail	2020-12-31 18:49:58	691	2021-05-22 17:22:34
692	Z011004	a496vj	52776 Canary Point	2021-03-12 06:13:12	692	2020-11-23 09:41:05
693	N821322	d590is	996 Dottie Crossing	2021-02-21 17:44:00	693	2021-03-03 17:03:18
694	C178073	s181bc	0 Washington Parkway	2020-08-02 12:50:51	694	2021-02-01 00:04:01
695	M613735	m378ba	68 Golf Course Lane	2021-02-20 02:54:10	695	2020-07-26 22:21:25
696	J630727	h040xf	5399 6th Center	2020-07-09 09:55:55	696	2021-01-05 23:26:48
697	T915199	s469yh	18 Monica Park	2021-03-31 20:42:29	697	2021-04-05 03:09:30
698	J497216	k784zg	3928 Golf Pass	2020-12-27 17:50:34	698	2021-04-13 21:56:46
699	F251921	w673qb	1960 Cherokee Crossing	2020-12-04 10:24:37	699	2021-02-17 11:14:36
700	B801496	y997og	182 Gina Trail	2021-04-26 05:46:45	700	2021-05-08 05:18:55
701	Z135675	f259ar	6 4th Park	2020-10-29 07:26:42	701	2021-03-06 07:59:34
702	T583776	f467uw	3797 Toban Pass	2021-01-27 09:26:32	702	2020-08-14 03:00:24
703	Y226557	v906eh	6 Roth Pass	2020-06-16 15:34:31	703	2020-10-15 11:59:06
704	E376733	u912jc	4 Kings Lane	2021-01-20 14:49:36	704	2020-07-30 15:23:55
705	V681041	k790hj	924 Packers Avenue	2020-06-14 07:15:36	705	2020-10-14 09:45:39
706	W168526	s438ko	1 Loeprich Center	2021-02-09 14:11:06	706	2021-01-11 05:19:56
707	L171846	i647ms	1825 Hazelcrest Center	2020-12-11 03:54:27	707	2021-02-26 12:27:53
708	Q382803	a633he	89779 Pearson Terrace	2021-02-06 17:11:59	708	2021-01-14 00:47:21
709	U999449	g608is	978 Onsgard Circle	2021-02-20 09:07:09	709	2021-03-15 12:38:36
710	Z918592	x787ld	938 Saint Paul Court	2021-01-12 18:37:57	710	2021-05-09 21:10:54
711	O292009	l490lw	34661 Westport Park	2020-07-26 10:17:11	711	2020-09-21 22:03:38
712	W753542	b602zn	44072 Hoard Trail	2020-12-11 20:00:15	712	2020-09-22 22:55:33
713	R658321	e501sh	78414 Garrison Center	2020-11-16 14:04:27	713	2021-05-19 18:00:29
714	F429899	r764ju	13 Fordem Road	2020-07-29 15:17:32	714	2020-06-30 21:21:21
715	N256659	g720sh	230 Arizona Trail	2020-12-04 21:17:47	715	2021-04-28 09:14:20
716	Q286191	h244xk	0 Carey Way	2020-06-27 06:47:20	716	2020-09-24 23:13:24
717	G345268	d255pw	76 Hanson Street	2021-01-11 05:59:33	717	2021-04-15 21:53:40
718	O561816	a127hh	948 Monument Pass	2021-02-17 01:02:34	718	2020-05-25 20:21:59
719	J377509	q951ic	361 Muir Junction	2021-02-14 18:05:57	719	2020-09-03 07:41:55
720	W772291	e887ri	75 Thompson Court	2020-06-27 03:51:41	720	2020-07-08 15:48:44
721	I712501	z094bw	392 Beilfuss Terrace	2021-05-16 08:12:34	721	2020-11-20 19:38:08
722	J566716	o140wg	09408 Union Road	2020-09-28 03:54:31	722	2020-06-22 15:18:15
723	F954132	c362cq	42 Vidon Court	2020-09-12 17:11:08	723	2020-12-20 07:54:37
724	L669254	i049vh	4176 Union Court	2020-09-12 07:31:04	724	2021-05-09 05:23:38
725	J411704	k476yq	74 Jackson Alley	2021-02-06 20:12:21	725	2020-07-13 14:51:50
726	I984046	p221vc	18 Westport Hill	2020-08-06 11:06:33	726	2021-03-28 15:10:52
727	W289024	x172yw	07211 Mayfield Court	2021-02-03 05:18:51	727	2020-08-22 00:16:00
728	R764683	q122fw	3 Shoshone Terrace	2020-10-09 01:58:58	728	2020-08-31 18:29:45
729	K526674	s761to	929 Helena Terrace	2021-01-11 03:07:28	729	2021-01-16 03:27:16
730	A426316	c050qc	89181 Victoria Street	2020-12-01 18:37:01	730	2020-09-27 20:09:55
731	F786883	b223js	9262 Duke Drive	2021-03-28 14:51:15	731	2020-10-15 21:10:27
732	A848599	e677oq	9454 Southridge Parkway	2020-08-12 16:15:46	732	2020-11-27 00:50:34
733	A191010	l738vs	04 Portage Street	2020-09-26 13:04:57	733	2020-12-11 06:07:36
734	O446079	m151op	90755 Warbler Parkway	2020-05-29 06:41:12	734	2021-01-03 05:16:05
735	T307846	n555dq	48904 Spenser Way	2021-03-21 23:33:09	735	2020-11-25 09:15:04
736	I879760	i307it	5 Lien Pass	2020-11-09 08:45:56	736	2020-10-29 22:33:21
737	V288615	b703yd	64 Alpine Circle	2020-10-30 05:00:27	737	2020-06-02 04:15:11
738	J900037	c425oz	03 Blue Bill Park Lane	2021-02-23 09:29:46	738	2020-06-25 05:39:45
739	P239404	n136go	6 Namekagon Crossing	2020-12-24 11:42:26	739	2020-07-04 02:46:01
740	A457879	p820zp	63 Sachtjen Hill	2021-05-05 11:04:32	740	2020-07-27 09:44:55
741	Q274882	w192ez	77 Bartillon Hill	2021-04-21 16:05:49	741	2021-05-21 23:33:01
742	R957266	g921je	24950 5th Pass	2020-07-15 22:11:32	742	2020-08-16 22:04:46
743	S209219	x199nd	6 Ronald Regan Hill	2020-08-10 08:25:42	743	2021-03-06 20:03:13
744	Y548686	a173sz	8 Bartelt Circle	2020-12-19 01:58:35	744	2021-04-08 21:47:03
745	J206617	e301fv	63209 Cascade Place	2021-01-13 15:28:58	745	2020-12-15 01:57:30
746	F154664	i473fv	38071 Sullivan Place	2020-09-15 08:38:16	746	2020-09-04 19:28:16
747	J146618	v555ho	838 Maryland Crossing	2020-11-24 03:49:16	747	2021-03-30 08:15:14
748	G155895	j852re	19913 Coleman Point	2021-02-04 08:20:53	748	2020-11-30 21:02:03
749	R167335	h969rd	090 Cottonwood Park	2020-12-16 08:39:27	749	2021-05-07 08:12:55
750	O566929	o215ho	97 Elgar Way	2020-07-07 10:01:33	750	2020-11-05 22:07:37
751	D161139	t971gl	76 Barby Crossing	2020-06-09 08:41:13	751	2021-01-03 13:23:35
752	P274732	j152jj	57 Karstens Avenue	2021-05-05 18:18:29	752	2020-11-20 12:10:14
753	W183612	u611qw	7 Fair Oaks Road	2021-05-03 22:37:26	753	2021-03-07 17:13:40
754	P629411	a863yg	25 Shelley Terrace	2021-05-12 08:15:59	754	2020-07-23 08:29:37
755	R562022	f824mt	16 Toban Park	2021-03-07 11:14:40	755	2020-11-11 16:26:18
756	R618269	g925jg	42208 Chinook Drive	2021-01-17 05:51:50	756	2020-06-26 00:18:29
757	L200204	y756ib	1 Twin Pines Way	2021-05-02 18:37:31	757	2020-05-31 15:42:30
758	D927520	n766ib	33 Nova Avenue	2021-02-24 03:01:36	758	2021-02-13 12:48:01
759	U506400	p755fn	51 Anniversary Court	2020-12-16 03:42:14	759	2020-08-14 03:49:07
760	Y755332	g076id	79 Artisan Point	2021-02-21 13:16:31	760	2020-10-22 08:40:01
761	C767709	w460ny	0604 Hollow Ridge Circle	2020-12-18 20:43:04	761	2021-03-06 12:16:13
762	O346148	w852nc	518 Crest Line Way	2020-06-03 04:17:37	762	2021-04-02 11:06:47
763	F607601	t341xq	81773 Rieder Place	2020-12-25 17:46:48	763	2020-11-27 00:46:48
764	Q573119	w467bl	60 Green Junction	2020-12-05 18:33:11	764	2020-10-09 14:21:07
765	L646290	s065ym	3 Eliot Center	2020-07-03 21:13:31	765	2021-01-11 00:20:48
766	V839283	n844ny	091 International Center	2021-02-10 19:50:36	766	2020-07-12 19:52:11
767	W372076	e782ks	5 Anniversary Place	2020-10-02 00:38:35	767	2020-10-08 21:39:42
768	R124906	z509nc	32397 Rusk Trail	2020-08-28 18:01:25	768	2020-06-14 21:44:29
769	D038943	q847fb	2 Utah Place	2020-05-31 03:39:31	769	2020-09-14 03:12:23
770	O318105	v786dg	10081 Mariners Cove Parkway	2020-07-10 08:37:48	770	2020-09-09 07:41:25
771	D892978	z930or	74 Jenna Lane	2021-03-03 09:27:03	771	2020-10-11 16:11:24
772	R476470	d029vp	4 Pine View Drive	2021-04-14 05:15:46	772	2020-09-03 13:47:51
773	G524002	a252xh	61 Manley Place	2021-04-06 02:37:16	773	2021-04-04 05:00:55
774	K844751	n518eg	23430 Roth Junction	2020-07-03 19:26:08	774	2020-07-05 13:19:52
775	T976441	o347ui	5 Wayridge Point	2020-11-24 16:12:19	775	2020-07-31 15:59:09
776	K656324	p185dh	97 Warbler Alley	2020-08-04 23:20:11	776	2021-01-03 17:10:14
777	U475980	f666mn	2683 Lakewood Road	2021-01-05 18:05:50	777	2020-09-02 11:23:22
778	U246327	t334ik	973 Service Court	2021-04-23 11:05:37	778	2020-08-21 18:27:39
779	D929731	o646bv	04991 2nd Hill	2020-07-08 15:56:51	779	2021-04-03 03:06:13
780	A717908	c832mc	69 Buena Vista Avenue	2020-09-05 05:35:23	780	2020-07-31 03:36:07
781	X031659	w457ae	94285 Sachs Crossing	2021-01-06 14:48:26	781	2020-08-29 01:20:34
782	H596379	r432mv	382 Ludington Hill	2020-11-04 01:52:27	782	2021-05-04 03:16:53
783	U013016	o282gl	27 Eagle Crest Road	2020-11-05 10:32:38	783	2020-11-09 09:10:42
784	Z310617	f199lx	7 Anthes Way	2021-05-05 12:15:29	784	2020-06-29 21:25:19
785	U658507	k398fm	3 5th Hill	2020-10-20 02:28:26	785	2021-03-05 17:14:10
786	E062962	f088ur	142 Brown Crossing	2021-02-03 03:14:44	786	2020-08-08 05:08:57
787	P555765	c488xe	050 Katie Avenue	2021-05-03 18:05:37	787	2020-07-26 06:25:55
788	X793002	x209jc	6259 Alpine Alley	2021-03-15 13:27:13	788	2021-02-06 18:28:43
789	U879495	j038wh	089 Colorado Place	2021-01-10 02:44:12	789	2020-11-13 19:28:25
790	A954586	a362ry	866 Scoville Court	2021-03-18 12:01:49	790	2021-03-21 17:53:34
791	D540538	t087uq	72832 Saint Paul Circle	2021-05-10 10:24:06	791	2021-02-06 19:19:05
792	S822108	c837gk	447 Spenser Plaza	2020-12-01 18:09:35	792	2020-12-30 15:17:42
793	K776567	f027rc	59762 Fairfield Park	2020-06-26 21:25:10	793	2020-11-19 00:42:54
794	T387461	j713zu	8 Fremont Court	2020-08-27 18:38:26	794	2021-04-18 22:29:17
795	F354895	e589on	2705 Aberg Terrace	2020-09-01 21:39:05	795	2020-12-29 16:28:22
796	U661652	e426vv	478 Clyde Gallagher Park	2020-09-09 12:28:19	796	2020-06-21 18:20:53
797	T423725	f022uv	83 Gulseth Park	2020-06-10 02:55:44	797	2020-09-09 20:13:33
798	Y538297	d526bv	7595 Old Gate Trail	2021-04-29 11:00:27	798	2020-08-09 23:52:11
799	Y244627	y161lm	01 School Point	2020-10-31 18:30:19	799	2021-03-01 19:52:34
800	T764164	o551ga	0 Steensland Trail	2020-09-07 10:05:57	800	2021-03-10 20:35:46
801	U979269	r662oj	75 Old Shore Crossing	2020-11-03 00:53:23	801	2020-06-21 22:18:28
802	F917264	j151rn	08 Mcbride Avenue	2020-07-15 18:09:58	802	2021-02-19 06:24:15
803	U492569	l556ab	2 Maywood Crossing	2020-08-20 07:11:21	803	2020-06-06 08:38:38
804	U937452	j518ok	692 Orin Point	2020-08-13 19:45:27	804	2020-08-28 21:47:01
805	O377456	k778da	748 Toban Lane	2020-10-31 09:01:28	805	2020-10-24 12:23:17
806	N186697	b224kh	3 Crest Line Terrace	2021-03-14 06:18:37	806	2020-10-26 08:43:27
807	P672504	h378ne	45 Huxley Circle	2020-10-04 16:12:22	807	2021-03-21 21:17:31
808	M606911	e643ks	15392 Del Mar Place	2021-05-15 04:39:47	808	2021-04-19 04:23:59
809	K289882	y290nz	0 Pierstorff Parkway	2020-09-11 14:07:50	809	2020-10-10 19:29:37
810	R683923	q519lg	77598 Texas Avenue	2021-03-09 16:27:35	810	2020-07-03 11:14:38
811	W339153	p079uv	632 Superior Junction	2021-05-20 07:14:29	811	2020-11-17 21:46:25
812	Y782463	a958en	0401 Red Cloud Point	2020-06-13 08:08:04	812	2021-02-12 08:07:34
813	H418000	p251kt	037 Charing Cross Trail	2021-02-20 02:40:24	813	2020-10-11 11:21:31
814	X231965	m421mr	6 Eliot Pass	2020-08-09 14:21:33	814	2020-06-23 23:51:32
815	F631157	i256mq	3392 Hansons Court	2020-06-13 08:29:02	815	2020-06-27 00:56:52
816	T608929	y839ym	576 6th Plaza	2020-07-11 17:46:52	816	2021-05-09 15:11:45
817	G195090	y830nq	769 American Circle	2020-10-14 22:49:19	817	2020-08-06 20:24:58
818	Y794982	m232au	790 Raven Place	2020-10-06 18:16:11	818	2020-11-01 07:07:28
819	C068496	o779un	7 Grayhawk Alley	2021-02-01 15:02:41	819	2020-07-05 15:49:16
820	J154835	x688qf	0325 Scott Crossing	2020-09-20 15:56:40	820	2020-08-06 23:26:30
821	W950255	l655kz	33 Melrose Junction	2021-03-29 22:24:44	821	2021-03-09 19:03:15
822	M839458	u431ca	97 Darwin Road	2020-08-28 19:19:39	822	2021-04-27 07:14:47
823	R579782	p224cc	6 Hermina Terrace	2020-12-11 11:30:45	823	2020-12-10 10:36:47
824	V228665	f087go	986 Rigney Plaza	2021-02-02 04:41:14	824	2021-04-10 20:13:00
825	O788784	v295wr	92 Claremont Alley	2021-05-01 01:39:33	825	2020-11-27 19:59:41
826	V645162	c880mu	9613 Cambridge Hill	2020-12-07 02:42:23	826	2021-03-08 03:03:53
827	A982444	q389bs	3051 Hagan Crossing	2021-04-28 13:05:31	827	2020-05-29 02:13:45
828	Y618108	v336xf	8 Bobwhite Terrace	2021-01-12 16:56:50	828	2020-12-19 14:23:41
829	Z916418	w484ai	87802 Northview Alley	2020-10-30 12:06:04	829	2021-05-07 05:02:25
830	Y567656	k896ko	92 Mendota Point	2020-09-14 13:40:47	830	2020-11-14 20:32:18
831	B436907	p768hs	24102 Helena Trail	2021-03-08 01:55:05	831	2021-02-07 08:33:12
832	S755251	e166le	212 Shelley Crossing	2021-02-14 09:46:28	832	2020-06-02 21:50:19
833	P777805	r350km	7989 Corben Park	2020-07-21 16:15:29	833	2021-04-08 17:52:20
834	M000999	l318dp	78 Granby Terrace	2020-10-29 01:12:44	834	2020-07-25 03:44:00
835	R670802	p768pc	584 Crescent Oaks Junction	2021-03-30 13:19:09	835	2021-05-14 16:22:30
836	W946030	g627ai	84 Linden Hill	2020-05-30 05:36:05	836	2021-03-25 00:33:25
837	D937746	s703pc	8107 Spaight Alley	2021-03-26 04:21:42	837	2020-12-27 18:15:50
838	L324310	h581wg	613 Vera Pass	2021-05-21 23:49:39	838	2020-12-05 21:34:45
839	B170273	r441rd	32898 Huxley Point	2020-12-08 05:50:21	839	2021-05-23 10:53:40
840	X808069	h662fd	9 Eggendart Park	2020-06-26 15:37:13	840	2020-11-14 04:16:44
841	O034871	h904wr	09736 Sheridan Junction	2020-07-13 04:31:53	841	2020-06-01 12:31:40
842	R409442	h155zq	2 Sommers Crossing	2021-05-17 14:10:16	842	2021-04-22 10:04:02
843	K557217	z076an	71742 Sauthoff Drive	2021-05-09 20:33:36	843	2020-11-14 04:32:53
844	Y584447	v132lj	805 Bartelt Avenue	2021-04-18 16:21:34	844	2021-02-16 10:11:52
845	K411448	r385sn	01536 3rd Junction	2020-12-20 09:39:49	845	2020-09-18 00:54:28
846	R455288	p646bt	8 Claremont Plaza	2021-04-02 08:30:02	846	2021-02-27 14:30:56
847	J484787	b132cx	31329 Tony Terrace	2020-07-20 03:46:52	847	2020-05-28 06:54:05
848	P980855	g203fs	2023 Florence Circle	2020-11-19 12:59:05	848	2020-11-01 21:23:54
849	J023469	g888qh	5760 Hayes Avenue	2020-12-17 04:57:32	849	2020-11-03 11:08:34
850	Y561197	w242ef	642 Golf Circle	2020-07-13 20:01:33	850	2020-07-20 03:42:42
851	C442312	j035sh	6 Lunder Avenue	2021-04-13 19:36:39	851	2021-01-21 04:53:30
852	M808209	m946ru	21 Hallows Avenue	2021-03-28 07:36:43	852	2020-10-04 00:11:52
853	U873722	a338tw	90496 South Alley	2021-01-08 04:39:46	853	2021-03-05 17:39:31
854	F718543	i791gn	80 Hanover Drive	2021-05-12 16:32:21	854	2021-03-29 23:26:23
855	T181597	w721hy	973 Veith Alley	2021-01-07 16:04:18	855	2020-10-26 09:12:51
856	D825378	v896nx	9 Hermina Road	2021-01-02 18:30:16	856	2020-09-19 20:21:36
857	E897100	c436zf	9980 Sunfield Terrace	2020-09-04 10:20:50	857	2021-01-20 05:38:22
858	L846867	x929hy	224 Express Trail	2020-11-13 11:37:23	858	2020-12-31 18:21:58
859	I648037	m655ib	707 Ilene Terrace	2021-04-17 20:56:44	859	2021-01-30 06:43:44
860	X838479	m621pl	01 Elka Place	2020-06-08 08:17:47	860	2020-11-19 23:44:26
861	G568163	v785ev	094 Cordelia Plaza	2020-12-04 15:48:10	861	2021-05-15 06:53:34
862	X123540	v396rh	3 Center Court	2021-05-03 13:58:01	862	2021-01-13 08:40:26
863	K040394	w715op	9094 Oak Court	2020-06-10 13:53:58	863	2021-02-15 02:18:48
864	B057798	v515bt	33 Jana Pass	2020-07-29 13:30:54	864	2021-04-29 12:29:23
865	Z817808	z553ee	8661 Dorton Pass	2020-12-11 05:39:07	865	2021-04-30 15:26:13
866	M435950	r603fb	646 Dawn Trail	2020-06-09 09:43:45	866	2021-03-23 02:00:29
867	T108281	g195zh	3 Bobwhite Alley	2020-11-25 22:09:54	867	2020-11-04 19:29:14
868	Z585136	j058bx	3 Summer Ridge Road	2020-11-30 20:04:37	868	2020-12-01 06:40:54
869	F286103	a073gl	97236 Erie Place	2021-02-01 03:06:40	869	2020-07-11 19:42:25
870	V062383	j619xl	5 Alpine Hill	2020-11-21 08:47:46	870	2020-10-04 09:03:43
871	S544650	a068cr	3 Fair Oaks Crossing	2021-05-10 12:06:33	871	2020-06-21 01:05:25
872	O919086	n158kd	22 Schiller Crossing	2020-07-04 16:00:38	872	2020-06-11 01:49:57
873	F632888	l681uo	05228 Fieldstone Trail	2021-01-28 22:42:03	873	2020-11-30 05:21:26
874	A586445	r690rj	7 Morningstar Crossing	2020-12-19 20:50:01	874	2021-01-20 03:23:02
875	K585764	b655ei	626 Debs Pass	2020-09-27 20:19:40	875	2020-10-01 16:59:30
876	X119351	r928bz	06 Knutson Center	2021-01-29 07:38:52	876	2020-05-25 09:49:30
877	P023436	w118dr	3802 Sycamore Lane	2021-05-19 16:58:45	877	2020-05-31 04:35:02
878	T759284	n560uj	2049 Carioca Road	2020-09-06 18:23:11	878	2021-03-12 15:47:10
879	E817570	m714qw	91791 Marquette Park	2020-09-28 00:17:26	879	2021-02-10 13:38:52
880	N762146	t573fw	440 6th Crossing	2021-03-20 00:22:18	880	2021-01-25 15:58:58
881	Q419069	x812cv	34 Ridgeview Place	2021-02-15 03:26:00	881	2020-05-25 20:18:52
882	E589524	r230mi	1930 Kennedy Avenue	2021-04-23 18:41:36	882	2020-06-24 22:01:42
883	B136175	d088yi	4 Merchant Center	2020-08-16 12:43:06	883	2020-06-19 02:22:18
884	W277033	e093tk	66 Prairie Rose Terrace	2021-05-08 03:55:01	884	2021-04-18 12:29:41
885	L740455	b677xx	703 Village Green Terrace	2020-09-28 02:15:24	885	2020-12-09 08:57:09
886	J402714	x867yj	09 Spenser Plaza	2021-05-05 23:59:38	886	2020-09-08 11:57:55
887	Q925947	i802ru	166 Coolidge Alley	2021-01-13 11:44:54	887	2021-05-18 03:05:03
888	K762012	x662nq	21967 Little Fleur Junction	2021-03-03 15:25:05	888	2021-02-28 04:04:35
889	H322400	k532tz	1 Porter Crossing	2020-12-17 04:20:39	889	2021-05-04 21:02:19
890	O661878	p897nu	465 Stoughton Crossing	2020-12-25 04:19:22	890	2020-08-12 19:24:42
891	C174991	m872mg	72 Lindbergh Avenue	2020-11-23 15:27:48	891	2020-09-10 12:20:43
892	C143062	w609kr	752 Nobel Alley	2020-09-19 23:02:18	892	2020-11-11 14:55:08
893	J558611	f361pc	070 Burrows Terrace	2020-06-04 09:36:03	893	2021-01-14 10:52:28
894	P450479	k865zf	10945 Elmside Crossing	2020-11-14 07:00:26	894	2021-01-23 05:14:15
895	Y772101	w101fh	43371 Bay Court	2020-12-21 13:41:25	895	2020-10-30 16:06:45
896	W239281	d904yh	4 Lake View Trail	2020-12-27 19:22:12	896	2020-10-05 21:06:34
897	K591429	c374pf	647 Hoard Hill	2020-07-14 16:19:40	897	2021-05-21 19:20:05
898	L037986	w190yf	5 Vermont Place	2020-11-04 23:44:10	898	2020-11-07 07:58:00
899	I432562	h832kr	55985 Superior Trail	2020-09-16 08:26:34	899	2020-12-30 09:11:41
900	Y022502	e632va	47 Cambridge Alley	2021-02-22 22:29:45	900	2020-10-07 15:43:25
901	J139451	m437zj	828 Hanover Court	2020-07-21 16:28:23	901	2020-08-15 00:03:15
902	Q846619	h662ka	19 Anthes Point	2020-07-26 02:46:42	902	2020-09-17 21:50:45
903	D883813	k176lf	15720 Blackbird Circle	2021-04-04 20:33:57	903	2021-03-18 06:42:40
904	V671986	v925ef	8 Fordem Point	2020-12-08 23:03:05	904	2021-02-06 13:32:07
905	X888308	l398mx	93 Coolidge Park	2021-03-19 15:47:22	905	2021-05-20 16:44:20
906	I105261	h024ac	9 Blaine Lane	2020-11-19 07:01:16	906	2020-08-23 21:38:58
907	P650614	d117eb	50 Mcbride Crossing	2021-05-10 09:14:54	907	2020-12-12 05:25:22
908	Z998871	a881uo	2 Straubel Circle	2021-05-04 04:46:59	908	2020-12-08 12:28:17
909	J711643	n879jj	40 Pleasure Place	2020-06-03 06:58:20	909	2020-06-12 10:44:50
910	K499513	u848np	2211 Norway Maple Point	2021-01-30 07:58:32	910	2021-03-27 06:08:57
911	C368340	h467ws	046 Menomonie Alley	2020-11-11 19:17:10	911	2021-05-07 09:08:24
912	A886895	u689rt	286 Milwaukee Junction	2021-01-14 13:10:42	912	2020-08-19 00:30:09
913	K574237	v093hj	7571 Oak Court	2021-03-28 13:29:34	913	2021-04-18 00:40:28
914	K765877	t733wk	12833 Sunfield Junction	2021-04-17 00:40:37	914	2020-05-28 04:44:24
915	X513167	x381ro	8147 Elka Park	2020-06-12 17:22:46	915	2020-12-28 03:33:43
916	S890129	c937hw	24 Lotheville Hill	2020-09-09 23:26:05	916	2021-03-24 07:05:55
917	Z773156	p910as	882 Service Pass	2021-01-08 15:12:51	917	2021-01-26 14:40:03
918	M492263	s906wd	20 Schiller Junction	2020-12-30 18:37:05	918	2021-01-18 13:55:26
919	I547961	j181ij	00 Thackeray Avenue	2020-08-02 19:29:41	919	2020-06-11 03:56:18
920	G846818	m737ps	20650 Declaration Lane	2020-05-31 18:35:29	920	2020-11-05 11:22:00
921	Y038069	c118op	15 Logan Drive	2020-08-04 00:17:30	921	2020-12-15 09:11:11
922	S807128	y682qs	71 Arizona Trail	2020-08-11 14:38:41	922	2021-03-04 02:49:29
923	R359253	i530ax	95708 Jenifer Alley	2020-09-11 17:56:50	923	2020-10-07 23:42:55
924	U922788	d255dr	65050 Lotheville Park	2020-12-27 06:35:53	924	2020-06-18 02:32:25
925	A267889	c404dj	0625 Portage Plaza	2020-06-02 18:11:11	925	2021-03-17 22:32:35
926	P722809	d674un	0408 Manitowish Crossing	2020-06-02 04:14:39	926	2020-12-26 14:05:58
927	N321769	t957uy	06 Red Cloud Hill	2020-12-12 21:25:33	927	2021-03-28 03:55:04
928	V345403	k058cf	9 John Wall Trail	2021-01-26 12:03:57	928	2021-01-06 11:02:37
929	W415469	y980zx	2654 Kropf Center	2020-11-21 06:58:48	929	2020-09-10 10:10:08
930	H031962	w463nx	95678 Paget Center	2020-06-02 19:34:11	930	2020-06-29 01:59:08
931	S893446	u056zu	4 Kensington Way	2020-09-07 16:52:22	931	2020-06-10 03:01:06
932	K907007	n462hn	82 Maple Wood Plaza	2020-07-14 02:31:14	932	2020-08-08 17:25:19
933	K652606	p276xb	3 New Castle Plaza	2020-06-19 15:02:07	933	2020-09-28 21:05:07
934	P977751	w826no	4730 Northview Center	2020-07-07 04:23:01	934	2020-11-30 20:43:30
935	X734500	w500ck	50 Drewry Pass	2020-09-21 13:51:53	935	2021-02-14 03:56:45
936	I262897	d703yr	21 Toban Trail	2021-02-24 06:14:42	936	2021-05-01 03:59:13
937	K144357	g601lv	52 Truax Court	2020-12-21 14:22:09	937	2021-01-05 21:38:45
938	Z193893	f924fu	5767 Mosinee Center	2021-05-12 11:15:30	938	2021-04-01 14:20:45
939	D890362	x106ih	52281 2nd Center	2021-05-15 18:12:08	939	2020-06-17 17:25:50
940	M334049	a919bd	3 Bluejay Park	2020-12-28 20:04:08	940	2020-11-18 18:11:19
941	Q172600	i113vm	0311 Killdeer Drive	2021-04-23 09:33:02	941	2021-03-13 20:35:55
942	Z351835	y166jw	3 Hovde Street	2021-01-18 06:29:16	942	2020-06-15 16:43:06
943	W632425	x341mu	815 Thompson Place	2021-03-07 17:31:19	943	2021-03-11 07:28:34
944	V160217	o774ba	69492 Towne Parkway	2020-08-19 04:08:48	944	2020-12-08 22:24:09
945	C024862	g938kx	93354 Stuart Terrace	2020-06-24 09:54:22	945	2020-05-26 07:45:21
946	F347060	p764ef	7 Algoma Plaza	2021-01-23 21:43:06	946	2020-10-28 17:01:51
947	R456328	z652kn	76 Anderson Plaza	2021-04-01 16:10:14	947	2020-07-29 17:24:53
948	Z827462	d296vs	370 Hallows Center	2020-12-20 07:48:30	948	2020-08-20 09:05:28
949	X350426	l753kv	714 Bultman Street	2020-06-10 09:43:56	949	2021-01-18 17:10:17
950	U031745	s568rr	631 Dexter Avenue	2020-10-19 10:05:35	950	2020-10-19 22:05:36
951	A170116	u292iu	5345 Mccormick Crossing	2021-02-20 03:29:41	951	2020-09-29 13:58:19
952	N042012	w153pe	388 Crest Line Court	2020-06-05 00:29:34	952	2021-04-29 09:04:34
953	Y731261	b906bo	2858 Chive Lane	2020-11-09 00:50:48	953	2020-09-21 02:30:37
954	J582698	p941wj	569 Nobel Court	2020-05-30 06:35:16	954	2020-07-05 18:25:09
955	G265053	d040fu	94 Eastwood Alley	2021-05-20 09:35:58	955	2020-08-22 14:47:22
956	C456691	h947nm	646 Monterey Place	2021-01-04 07:52:41	956	2020-12-07 13:00:46
957	F981934	q353it	25 East Parkway	2021-05-04 17:47:19	957	2020-09-11 19:16:38
958	C407015	n284tl	142 Hudson Plaza	2021-03-19 23:52:11	958	2020-08-22 04:10:48
959	T187979	o458mo	1 Rutledge Point	2020-08-06 18:05:33	959	2021-01-03 02:58:40
960	C626430	s485jh	67195 David Trail	2021-01-11 15:33:39	960	2021-02-07 14:32:09
961	H818730	j978dd	80657 Oneill Avenue	2020-12-26 22:06:55	961	2020-08-18 05:51:09
962	M094628	g996kq	7375 Mayfield Road	2020-07-31 22:04:42	962	2021-03-23 17:37:10
963	J534560	q349zo	382 4th Crossing	2020-12-07 16:18:19	963	2020-09-30 12:49:56
964	E546679	e950ro	5 Springs Point	2021-01-08 18:57:43	964	2020-10-17 18:37:01
965	M238188	s064it	229 Superior Park	2020-12-06 21:05:24	965	2020-07-11 05:33:32
966	W240042	k939oq	96667 Vidon Terrace	2021-05-11 00:51:46	966	2020-11-18 05:19:34
967	Z302225	k995rh	355 Westridge Junction	2021-02-24 17:55:07	967	2020-09-10 20:36:09
968	E022145	h948wo	3 Alpine Pass	2021-04-01 23:42:20	968	2020-12-12 04:14:48
969	B067044	m624hk	59636 Northview Park	2021-02-10 08:30:34	969	2020-06-21 06:55:29
970	A051688	x229kc	5 Clemons Park	2020-10-30 16:35:22	970	2021-03-16 19:15:34
971	J983142	b711ey	4998 Magdeline Road	2021-03-27 23:53:22	971	2020-10-28 00:58:58
972	W040572	r316kp	6 Pawling Circle	2020-10-03 01:09:09	972	2020-08-02 13:52:12
973	Q404643	t182qa	0156 Nova Alley	2020-11-20 04:27:58	973	2020-09-05 22:53:13
974	J587607	q323wy	29 Kings Drive	2020-08-23 00:53:18	974	2020-09-17 20:51:32
975	U689349	m350vt	6334 Golf Course Junction	2020-05-26 09:20:36	975	2020-11-28 21:20:00
976	N250181	k752yu	1 Maple Wood Terrace	2021-03-06 07:06:17	976	2021-04-10 22:18:56
977	O220210	u931mg	40 Oakridge Crossing	2020-08-03 09:39:12	977	2020-10-24 14:59:39
978	J978701	c215xy	0126 Twin Pines Terrace	2021-01-05 03:18:55	978	2020-08-25 16:48:50
979	H142121	f537mw	89 Mockingbird Drive	2020-11-22 11:32:20	979	2021-01-22 19:38:12
980	Q437318	u672ev	8 Briar Crest Drive	2020-07-05 23:24:54	980	2020-07-25 00:05:38
981	K236036	r193mf	89116 Reindahl Street	2020-09-01 21:21:26	981	2021-01-23 21:39:09
982	O721377	y816af	490 Eliot Lane	2020-12-23 12:47:16	982	2021-01-29 16:18:28
983	D777463	s537vs	7 Oakridge Plaza	2020-08-25 03:41:19	983	2021-03-04 13:43:53
984	R241484	o383qq	20 Sugar Parkway	2020-10-10 17:29:03	984	2020-11-28 06:05:50
985	M890299	k596sc	560 Fuller Point	2021-03-18 04:04:35	985	2020-06-04 15:10:37
986	Q643044	j544an	2 Namekagon Center	2020-07-03 20:59:13	986	2021-01-03 12:47:00
987	K770332	a986ii	2687 Lighthouse Bay Parkway	2020-08-07 15:24:26	987	2020-08-30 10:23:25
988	C708934	z522oc	1106 Orin Pass	2020-08-31 05:27:53	988	2021-03-12 17:09:26
989	U208766	u448el	6 Mandrake Plaza	2020-07-12 21:58:00	989	2021-04-22 09:40:18
990	J835472	y591td	6258 Pine View Plaza	2021-05-18 01:30:22	990	2020-09-08 02:31:46
991	U332725	u212iv	304 Nancy Park	2020-10-08 10:49:42	991	2020-09-12 17:21:39
992	H783655	g932tr	75525 Eagle Crest Way	2020-06-11 11:36:43	992	2020-11-06 08:05:37
993	M421687	v007mc	02092 Merrick Parkway	2021-02-15 04:49:56	993	2020-11-01 14:00:16
994	M603523	o753tp	742 Melvin Way	2020-12-28 02:41:33	994	2021-03-16 12:19:27
995	T197895	l815fk	9471 New Castle Alley	2020-07-11 07:06:30	995	2021-03-09 06:23:14
996	M009160	r707zi	45 Stoughton Way	2020-11-23 15:59:23	996	2021-02-24 00:02:53
997	E695842	c199gi	7 Forest Run Pass	2020-07-21 20:34:53	997	2021-01-25 13:18:38
998	X899914	f450jz	3 Banding Plaza	2021-03-11 16:40:01	998	2020-08-30 10:58:37
999	T368898	u959wi	28937 Scott Trail	2020-09-28 08:35:44	999	2021-04-07 02:53:50
1000	F941131	r102px	1 Veith Trail	2021-03-09 19:43:03	1000	2020-06-10 07:46:58
259	O580345	y521dx	92 Gateway Point	2021-03-21 02:50:07	259	2021-05-15 06:00:00
\.


--
-- TOC entry 3186 (class 0 OID 16648)
-- Dependencies: 224
-- Data for Name: voyage_transports_m_equipment; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.voyage_transports_m_equipment (id_voyage, id_p_warehouse, id_m_equipment, number, in_out) FROM stdin;
1	1	1	1	f
2	1	2	5	t
3	2	3	3	f
4	3	4	10	t
5	5	5	1	f
6	6	6	3	t
7	7	7	1	t
8	8	8	6	f
9	9	9	4	f
10	10	10	12	t
11	11	11	7	t
12	12	12	17	f
13	13	13	30	f
14	14	14	11	t
15	15	15	6	t
16	16	16	40	f
17	17	17	37	f
18	18	18	11	t
19	19	19	6	f
20	20	20	3	f
21	21	21	28	t
22	22	22	10	t
23	23	23	28	f
24	24	24	36	f
25	25	25	6	f
26	26	26	21	t
27	27	27	18	f
28	28	28	21	f
29	29	29	29	f
30	30	30	11	f
31	31	31	18	f
32	32	32	30	f
33	33	33	6	t
34	34	34	5	t
35	35	35	23	t
36	36	36	31	f
37	37	37	38	f
38	38	38	22	f
39	39	39	33	f
40	40	40	18	f
41	41	41	19	f
42	42	42	26	f
43	43	43	24	f
44	44	44	28	f
45	45	45	36	f
46	46	46	10	t
47	47	47	12	t
48	48	48	14	f
49	49	49	21	t
50	50	50	3	f
51	51	51	26	t
52	52	52	26	t
53	53	53	40	f
54	54	54	25	t
55	55	55	31	t
56	56	56	25	f
57	57	57	21	t
58	58	58	35	t
59	59	59	20	t
60	60	60	36	f
61	61	61	9	t
62	62	62	32	f
63	63	63	24	f
64	64	64	36	t
65	65	65	12	f
66	66	66	9	t
67	67	67	4	f
68	68	68	7	t
69	69	69	14	t
70	70	70	6	t
71	71	71	1	t
72	72	72	1	f
73	73	73	15	t
74	74	74	19	t
75	75	75	30	t
76	76	76	4	f
77	77	77	40	f
78	78	78	21	f
79	79	79	25	f
80	80	80	20	f
81	81	81	37	f
82	82	82	28	f
83	83	83	22	f
84	84	84	12	t
85	85	85	30	f
86	86	86	24	f
87	87	87	3	t
88	88	88	5	f
89	89	89	17	f
90	90	90	3	t
91	91	91	15	f
92	92	92	14	f
93	93	93	33	t
94	94	94	32	t
95	95	95	17	f
96	96	96	5	t
97	97	97	25	t
98	98	98	12	t
99	99	99	31	f
100	100	100	27	f
101	101	101	7	t
102	102	102	9	f
103	103	103	32	f
104	104	104	26	f
105	105	105	3	t
106	106	106	12	t
107	107	107	38	t
108	108	108	20	t
109	109	109	10	t
110	110	110	27	t
111	111	111	32	t
112	112	112	32	f
113	113	113	15	t
114	114	114	9	f
115	115	115	39	t
116	116	116	25	f
117	117	117	15	t
118	118	118	6	t
119	119	119	34	f
120	120	120	3	t
121	121	121	28	t
122	122	122	14	t
123	123	123	1	t
124	124	124	33	t
125	125	125	34	f
126	126	126	21	f
127	127	127	40	t
128	128	128	9	t
129	129	129	13	t
130	130	130	22	t
131	131	131	16	f
132	132	132	13	t
133	133	133	11	f
134	134	134	23	f
135	135	135	6	t
136	136	136	33	f
137	137	137	11	f
138	138	138	22	f
139	139	139	37	f
140	140	140	7	f
141	141	141	36	t
142	142	142	12	t
143	143	143	23	f
144	144	144	40	f
145	145	145	16	f
146	146	146	25	f
147	147	147	4	f
148	148	148	15	t
149	149	149	20	f
150	150	150	8	t
151	151	151	37	t
152	152	152	20	f
153	153	153	34	f
154	154	154	34	t
155	155	155	15	t
156	156	156	13	t
157	157	157	23	f
158	158	158	11	f
159	159	159	16	t
160	160	160	2	f
161	161	161	38	f
162	162	162	32	t
163	163	163	2	f
164	164	164	26	f
165	165	165	25	f
166	166	166	40	f
167	167	167	7	f
168	168	168	31	f
169	169	169	35	t
170	170	170	10	f
171	171	171	18	t
172	172	172	15	t
173	173	173	30	t
174	174	174	17	f
175	175	175	10	t
176	176	176	32	f
177	177	177	1	t
178	178	178	20	f
179	179	179	28	t
180	180	180	10	t
181	181	181	6	f
182	182	182	3	t
183	183	183	27	t
184	184	184	10	t
185	185	185	40	f
186	186	186	31	f
187	187	187	5	t
188	188	188	14	f
189	189	189	2	t
190	190	190	1	f
191	191	191	18	f
192	192	192	35	f
193	193	193	10	f
194	194	194	27	t
195	195	195	2	f
196	196	196	39	t
197	197	197	37	t
198	198	198	10	f
199	199	199	1	f
200	200	200	11	f
201	201	201	27	f
202	202	202	38	t
203	203	203	8	f
204	204	204	7	f
205	205	205	36	f
206	206	206	15	f
207	207	207	14	f
208	208	208	27	t
209	209	209	16	f
210	210	210	5	f
211	211	211	28	f
212	212	212	32	t
213	213	213	12	t
214	214	214	1	t
215	215	215	18	f
216	216	216	10	f
217	217	217	27	t
218	218	218	19	t
219	219	219	32	f
220	220	220	28	f
221	221	221	20	t
222	222	222	28	f
223	223	223	16	f
224	224	224	8	f
225	225	225	12	t
226	226	226	11	f
227	227	227	35	f
228	228	228	33	t
229	229	229	6	t
230	230	230	38	t
231	231	231	40	f
232	232	232	31	f
233	233	233	30	f
234	234	234	25	f
235	235	235	25	f
236	236	236	20	f
237	237	237	31	f
238	238	238	22	t
239	239	239	30	f
240	240	240	19	f
241	241	241	16	t
242	242	242	35	f
243	243	243	28	t
244	244	244	39	t
245	245	245	37	t
246	246	246	20	t
247	247	247	16	t
248	248	248	7	f
249	249	249	22	f
250	250	250	29	t
251	251	251	4	f
252	252	252	27	f
253	253	253	8	t
254	254	254	10	t
255	255	255	8	t
256	256	256	4	t
257	257	257	40	t
258	258	258	8	f
259	259	259	10	t
260	260	260	21	f
261	261	261	19	t
262	262	262	1	f
263	263	263	34	t
264	264	264	27	t
265	265	265	2	t
266	266	266	35	f
267	267	267	11	f
268	268	268	26	f
269	269	269	23	f
270	270	270	25	t
271	271	271	14	f
272	272	272	39	t
273	273	273	11	f
274	274	274	37	f
275	275	275	19	t
276	276	276	19	f
277	277	277	9	f
278	278	278	19	f
279	279	279	9	f
280	280	280	3	t
281	281	281	31	t
282	282	282	32	f
283	283	283	5	t
284	284	284	39	t
285	285	285	13	f
286	286	286	37	f
287	287	287	27	f
288	288	288	39	f
289	289	289	25	f
290	290	290	8	f
291	291	291	31	f
292	292	292	32	t
293	293	293	5	f
294	294	294	23	f
295	295	295	25	f
296	296	296	4	f
297	297	297	7	t
298	298	298	25	f
299	299	299	36	f
300	300	300	27	f
301	301	301	16	t
302	302	302	10	f
303	303	303	31	f
304	304	304	34	f
305	305	305	5	f
306	306	306	34	f
307	307	307	26	t
308	308	308	32	t
309	309	309	20	f
310	310	310	12	t
311	311	311	4	f
312	312	312	3	t
313	313	313	7	t
314	314	314	8	f
315	315	315	17	f
316	316	316	33	t
317	317	317	31	f
318	318	318	29	t
319	319	319	14	f
320	320	320	30	f
321	321	321	18	f
322	322	322	12	t
323	323	323	22	f
324	324	324	29	f
325	325	325	21	f
326	326	326	23	f
327	327	327	6	f
328	328	328	2	f
329	329	329	10	f
330	330	330	27	f
331	331	331	34	f
332	332	332	39	f
333	333	333	32	t
334	334	334	11	t
335	335	335	5	t
336	336	336	31	f
337	337	337	36	f
338	338	338	21	f
339	339	339	39	f
340	340	340	11	t
341	341	341	4	t
342	342	342	40	f
343	343	343	17	t
344	344	344	4	t
345	345	345	40	f
346	346	346	26	f
347	347	347	5	t
348	348	348	37	f
349	349	349	7	f
350	350	350	35	f
351	351	351	26	f
352	352	352	29	f
353	353	353	16	f
354	354	354	15	t
355	355	355	12	f
356	356	356	20	f
357	357	357	22	t
358	358	358	23	t
359	359	359	18	t
360	360	360	19	f
361	361	361	18	f
362	362	362	19	t
363	363	363	37	f
364	364	364	40	f
365	365	365	40	t
366	366	366	1	f
367	367	367	32	t
368	368	368	6	f
369	369	369	34	t
370	370	370	40	t
371	371	371	12	t
372	372	372	31	t
373	373	373	11	f
374	374	374	20	f
375	375	375	25	f
376	376	376	5	t
377	377	377	6	t
378	378	378	35	t
379	379	379	1	f
380	380	380	24	f
381	381	381	5	t
382	382	382	15	f
383	383	383	19	t
384	384	384	29	t
385	385	385	15	t
386	386	386	7	f
387	387	387	34	f
388	388	388	3	t
389	389	389	11	f
390	390	390	35	t
391	391	391	4	t
392	392	392	6	t
393	393	393	27	t
394	394	394	34	t
395	395	395	13	t
396	396	396	18	t
397	397	397	38	f
398	398	398	32	t
399	399	399	26	f
400	400	400	27	t
401	401	401	18	f
402	402	402	9	t
403	403	403	27	t
404	404	404	8	t
405	405	405	1	f
406	406	406	5	t
407	407	407	39	t
408	408	408	8	f
409	409	409	29	f
410	410	410	9	t
411	411	411	3	f
412	412	412	20	f
413	413	413	13	f
414	414	414	27	f
415	415	415	16	f
416	416	416	26	t
417	417	417	40	f
418	418	418	2	t
419	419	419	23	t
420	420	420	4	t
421	421	421	1	t
422	422	422	8	t
423	423	423	38	f
424	424	424	21	t
425	425	425	4	f
426	426	426	36	t
427	427	427	16	f
428	428	428	17	f
429	429	429	36	t
430	430	430	39	t
431	431	431	28	f
432	432	432	36	f
433	433	433	12	t
434	434	434	9	f
435	435	435	38	f
436	436	436	23	f
437	437	437	15	t
438	438	438	13	t
439	439	439	31	f
440	440	440	32	f
441	441	441	20	t
442	442	442	10	f
443	443	443	16	t
444	444	444	9	t
445	445	445	1	f
446	446	446	16	t
447	447	447	3	t
448	448	448	6	f
449	449	449	11	t
450	450	450	14	t
451	451	451	28	t
452	452	452	40	f
453	453	453	7	t
454	454	454	36	t
455	455	455	9	f
456	456	456	16	t
457	457	457	26	t
458	458	458	9	t
459	459	459	20	f
460	460	460	12	f
461	461	461	20	t
462	462	462	21	t
463	463	463	17	t
464	464	464	6	t
465	465	465	32	t
466	466	466	16	f
467	467	467	26	f
468	468	468	15	f
469	469	469	25	f
470	470	470	20	t
471	471	471	6	f
472	472	472	24	t
473	473	473	12	f
474	474	474	36	f
475	475	475	5	f
476	476	476	8	f
477	477	477	29	t
478	478	478	34	f
479	479	479	10	f
480	480	480	33	t
481	481	481	29	t
482	482	482	14	t
483	483	483	29	f
484	484	484	18	f
485	485	485	11	t
486	486	486	30	t
487	487	487	33	t
488	488	488	17	t
489	489	489	16	t
490	490	490	20	t
491	491	491	3	f
492	492	492	17	f
493	493	493	18	t
494	494	494	11	f
495	495	495	7	f
496	496	496	33	t
497	497	497	39	t
498	498	498	23	f
499	499	499	19	f
500	500	500	21	f
501	501	501	1	f
502	502	502	20	t
503	503	503	34	t
504	504	504	7	t
505	505	505	9	f
506	506	506	19	f
507	507	507	40	f
508	508	508	9	t
509	509	509	2	f
510	510	510	33	t
511	511	511	40	f
512	512	512	19	t
513	513	513	13	t
514	514	514	22	t
515	515	515	33	f
516	516	516	26	t
517	517	517	21	t
518	518	518	25	f
519	519	519	29	f
520	520	520	19	t
521	521	521	3	f
522	522	522	6	t
523	523	523	3	f
524	524	524	37	f
525	525	525	2	t
526	526	526	20	f
527	527	527	13	t
528	528	528	31	f
529	529	529	29	f
530	530	530	6	f
531	531	531	25	f
532	532	532	39	f
533	533	533	37	f
534	534	534	8	f
535	535	535	16	t
536	536	536	1	t
537	537	537	22	t
538	538	538	29	t
539	539	539	31	t
540	540	540	18	f
541	541	541	1	f
542	542	542	1	t
543	543	543	19	f
544	544	544	30	t
545	545	545	24	t
546	546	546	16	f
547	547	547	6	f
548	548	548	12	t
549	549	549	10	f
550	550	550	37	f
551	551	551	38	t
552	552	552	35	t
553	553	553	1	f
554	554	554	22	t
555	555	555	1	f
556	556	556	25	f
557	557	557	27	f
558	558	558	15	f
559	559	559	28	f
560	560	560	3	t
561	561	561	20	t
562	562	562	34	t
563	563	563	38	t
564	564	564	6	f
565	565	565	12	t
566	566	566	40	f
567	567	567	15	f
568	568	568	5	t
569	569	569	19	f
570	570	570	11	f
571	571	571	4	f
572	572	572	1	f
573	573	573	13	t
574	574	574	26	f
575	575	575	21	t
576	576	576	36	t
577	577	577	25	t
578	578	578	15	t
579	579	579	16	f
580	580	580	2	f
581	581	581	18	t
582	582	582	27	f
583	583	583	26	t
584	584	584	12	t
585	585	585	21	f
586	586	586	31	t
587	587	587	38	f
588	588	588	28	f
589	589	589	26	t
590	590	590	36	t
591	591	591	26	t
592	592	592	23	f
593	593	593	40	t
594	594	594	1	f
595	595	595	27	t
596	596	596	21	t
597	597	597	18	f
598	598	598	35	f
599	599	599	18	t
600	600	600	24	t
601	601	601	11	f
602	602	602	12	f
603	603	603	2	f
604	604	604	9	t
605	605	605	2	t
606	606	606	31	t
607	607	607	3	t
608	608	608	28	t
609	609	609	33	t
610	610	610	15	t
611	611	611	37	t
612	612	612	29	t
613	613	613	24	f
614	614	614	3	f
615	615	615	14	t
616	616	616	40	t
617	617	617	35	t
618	618	618	29	f
619	619	619	11	t
620	620	620	8	f
621	621	621	12	t
622	622	622	32	t
623	623	623	8	f
624	624	624	32	f
625	625	625	30	t
626	626	626	2	f
627	627	627	33	t
628	628	628	15	f
629	629	629	15	f
630	630	630	15	t
631	631	631	4	t
632	632	632	20	t
633	633	633	23	f
634	634	634	29	t
635	635	635	22	f
636	636	636	40	t
637	637	637	13	f
638	638	638	34	f
639	639	639	38	t
640	640	640	30	f
641	641	641	35	t
642	642	642	5	t
643	643	643	31	f
644	644	644	13	t
645	645	645	20	f
646	646	646	12	f
647	647	647	32	t
648	648	648	10	f
649	649	649	35	f
650	650	650	25	f
651	651	651	38	f
652	652	652	36	t
653	653	653	12	t
654	654	654	6	f
655	655	655	27	f
656	656	656	25	f
657	657	657	24	f
658	658	658	16	t
659	659	659	20	f
660	660	660	18	f
661	661	661	23	f
662	662	662	30	f
663	663	663	7	t
664	664	664	30	t
665	665	665	32	t
666	666	666	12	f
667	667	667	17	t
668	668	668	20	f
669	669	669	31	f
670	670	670	5	t
671	671	671	40	t
672	672	672	15	t
673	673	673	5	t
674	674	674	39	f
675	675	675	20	f
676	676	676	15	t
677	677	677	20	t
678	678	678	4	f
679	679	679	23	t
680	680	680	18	t
681	681	681	14	f
682	682	682	30	f
683	683	683	25	f
684	684	684	21	t
685	685	685	38	f
686	686	686	19	f
687	687	687	20	f
688	688	688	28	f
689	689	689	21	t
690	690	690	16	t
691	691	691	17	t
692	692	692	18	f
693	693	693	12	f
694	694	694	18	t
695	695	695	33	f
696	696	696	6	t
697	697	697	11	t
698	698	698	11	t
699	699	699	4	t
700	700	700	34	f
701	701	701	37	t
702	702	702	40	f
703	703	703	7	f
704	704	704	35	f
705	705	705	21	f
706	706	706	25	f
707	707	707	36	t
708	708	708	23	t
709	709	709	36	t
710	710	710	7	t
711	711	711	12	t
712	712	712	1	f
713	713	713	39	f
714	714	714	14	t
715	715	715	6	f
716	716	716	31	f
717	717	717	19	f
718	718	718	10	f
719	719	719	29	t
720	720	720	31	f
721	721	721	36	t
722	722	722	1	t
723	723	723	15	f
724	724	724	33	t
725	725	725	7	f
726	726	726	29	f
727	727	727	4	f
728	728	728	12	t
729	729	729	27	t
730	730	730	31	t
731	731	731	15	t
732	732	732	2	f
733	733	733	8	f
734	734	734	10	t
735	735	735	15	f
736	736	736	2	f
737	737	737	26	t
738	738	738	20	t
739	739	739	6	t
740	740	740	40	f
741	741	741	21	f
742	742	742	23	t
743	743	743	23	f
744	744	744	5	t
745	745	745	10	t
746	746	746	25	t
747	747	747	39	f
748	748	748	5	t
749	749	749	12	f
750	750	750	7	t
751	751	751	32	f
752	752	752	19	t
753	753	753	30	f
754	754	754	7	f
755	755	755	8	t
756	756	756	25	f
757	757	757	22	f
758	758	758	14	t
759	759	759	10	f
760	760	760	25	t
761	761	761	38	f
762	762	762	31	f
763	763	763	34	f
764	764	764	33	t
765	765	765	22	t
766	766	766	14	f
767	767	767	34	t
768	768	768	30	t
769	769	769	26	f
770	770	770	28	t
771	771	771	21	f
772	772	772	25	f
773	773	773	18	f
774	774	774	28	t
775	775	775	36	f
776	776	776	15	t
777	777	777	9	t
778	778	778	25	t
779	779	779	15	t
780	780	780	30	t
781	781	781	20	f
782	782	782	10	t
783	783	783	15	t
784	784	784	24	t
785	785	785	12	t
786	786	786	36	f
787	787	787	2	t
788	788	788	26	f
789	789	789	3	f
790	790	790	35	t
791	791	791	21	t
792	792	792	40	t
793	793	793	8	f
794	794	794	5	f
795	795	795	15	t
796	796	796	34	f
797	797	797	12	f
798	798	798	5	f
799	799	799	9	f
800	800	800	31	t
801	801	801	13	t
802	802	802	27	f
803	803	803	3	t
804	804	804	9	f
805	805	805	38	t
806	806	806	6	t
807	807	807	15	t
808	808	808	3	t
809	809	809	12	t
810	810	810	6	t
811	811	811	6	f
812	812	812	7	f
813	813	813	35	t
814	814	814	25	f
815	815	815	22	t
816	816	816	26	t
817	817	817	20	t
818	818	818	3	t
819	819	819	39	t
820	820	820	38	f
821	821	821	25	f
822	822	822	37	f
823	823	823	27	f
824	824	824	15	t
825	825	825	26	f
826	826	826	22	t
827	827	827	4	f
828	828	828	1	f
829	829	829	28	t
830	830	830	20	f
831	831	831	37	f
832	832	832	29	t
833	833	833	20	f
834	834	834	13	f
835	835	835	20	f
836	836	836	4	t
837	837	837	12	t
838	838	838	8	t
839	839	839	34	t
840	840	840	18	t
841	841	841	9	f
842	842	842	31	f
843	843	843	27	t
844	844	844	28	t
845	845	845	16	f
846	846	846	21	f
847	847	847	40	t
848	848	848	22	f
849	849	849	36	t
850	850	850	11	t
851	851	851	15	t
852	852	852	5	t
853	853	853	34	t
854	854	854	1	t
855	855	855	5	f
856	856	856	10	f
857	857	857	39	t
858	858	858	14	f
859	859	859	15	f
860	860	860	26	t
861	861	861	18	t
862	862	862	7	t
863	863	863	27	t
864	864	864	21	t
865	865	865	34	f
866	866	866	6	t
867	867	867	40	f
868	868	868	14	t
869	869	869	24	t
870	870	870	34	t
871	871	871	22	t
872	872	872	27	f
873	873	873	21	f
874	874	874	34	t
875	875	875	11	t
876	876	876	2	t
877	877	877	24	t
878	878	878	13	t
879	879	879	37	f
880	880	880	9	t
881	881	881	25	f
882	882	882	31	t
883	883	883	32	f
884	884	884	19	t
885	885	885	31	f
886	886	886	23	f
887	887	887	34	f
888	888	888	27	t
889	889	889	1	t
890	890	890	4	f
891	891	891	40	f
892	892	892	17	f
893	893	893	28	t
894	894	894	39	t
895	895	895	37	t
896	896	896	23	f
897	897	897	10	f
898	898	898	31	t
899	899	899	19	f
900	900	900	22	f
901	901	901	6	f
902	902	902	18	t
903	903	903	11	f
904	904	904	8	t
905	905	905	21	f
906	906	906	17	t
907	907	907	16	t
908	908	908	12	f
909	909	909	14	t
910	910	910	34	f
911	911	911	31	t
912	912	912	24	t
913	913	913	8	f
914	914	914	40	f
915	915	915	33	f
916	916	916	15	t
917	917	917	37	f
918	918	918	11	f
919	919	919	24	t
920	920	920	29	f
921	921	921	9	f
922	922	922	1	t
923	923	923	12	f
924	924	924	22	f
925	925	925	40	t
926	926	926	7	f
927	927	927	23	t
928	928	928	27	t
929	929	929	29	f
930	930	930	12	f
931	931	931	25	t
932	932	932	4	t
933	933	933	13	t
934	934	934	26	f
935	935	935	18	f
936	936	936	16	f
937	937	937	34	t
938	938	938	10	t
939	939	939	32	f
940	940	940	27	f
941	941	941	28	f
942	942	942	3	t
943	943	943	15	f
944	944	944	5	f
945	945	945	30	t
946	946	946	17	f
947	947	947	30	t
948	948	948	2	t
949	949	949	37	f
950	950	950	17	f
951	951	951	3	t
952	952	952	1	f
953	953	953	6	f
954	954	954	8	t
955	955	955	20	t
956	956	956	27	t
957	957	957	7	t
958	958	958	29	f
959	959	959	40	t
960	960	960	37	f
961	961	961	28	f
962	962	962	11	f
963	963	963	16	t
964	964	964	26	f
965	965	965	18	t
966	966	966	31	t
967	967	967	13	t
968	968	968	2	f
969	969	969	8	f
970	970	970	34	f
971	971	971	34	t
972	972	972	33	f
973	973	973	26	t
974	974	974	17	t
975	975	975	32	t
976	976	976	14	t
977	977	977	17	f
978	978	978	7	t
979	979	979	8	t
980	980	980	27	f
981	981	981	8	t
982	982	982	7	t
983	983	983	9	t
984	984	984	38	f
985	985	985	35	f
986	986	986	24	f
987	987	987	11	f
988	988	988	1	f
989	989	989	9	t
990	990	990	31	t
991	991	991	14	t
992	992	992	3	f
993	993	993	25	f
994	994	994	5	t
995	995	995	39	f
996	996	996	4	t
997	997	997	15	t
998	998	998	22	t
999	999	999	12	t
1000	1000	1000	21	t
\.


--
-- TOC entry 3187 (class 0 OID 16664)
-- Dependencies: 225
-- Data for Name: voyage_transports_medicine; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.voyage_transports_medicine (id_voyage, id_medicine, id_storage_department, number, in_out) FROM stdin;
2	2	1	20	f
5	5	5	25	t
7	7	3	6	f
8	8	4	13	f
9	9	4	20	f
10	10	5	94	t
13	13	13	46	t
14	14	14	13	f
15	15	15	56	f
16	16	16	16	f
17	17	17	25	f
18	18	18	32	t
19	19	19	62	f
20	20	20	9	t
21	21	21	3	t
22	22	22	25	f
23	23	23	50	t
24	24	24	26	f
25	25	25	26	f
26	26	26	11	f
27	27	27	70	f
28	28	28	53	t
29	29	29	57	t
30	30	30	7	t
31	31	31	49	t
32	32	32	12	t
33	33	33	67	t
34	34	34	34	t
35	35	35	49	f
36	36	36	45	t
37	37	37	56	f
38	38	38	42	f
39	39	39	41	f
40	40	40	9	t
41	41	41	43	t
42	42	42	57	f
43	43	43	35	f
44	44	44	3	f
45	45	45	20	f
46	46	46	63	t
47	47	47	37	t
48	48	48	6	f
49	49	49	39	f
50	50	50	11	f
51	51	51	43	f
52	52	52	39	t
53	53	53	63	t
1	1	4	50	f
3	3	3	30	t
4	4	3	20	f
6	6	5	50	t
11	11	1	13	f
54	54	54	19	t
55	55	55	51	t
56	56	56	29	t
57	57	57	13	t
58	58	58	44	f
59	59	59	55	f
60	60	60	66	t
61	61	61	68	f
62	62	62	61	t
63	63	63	4	t
64	64	64	20	t
65	65	65	24	t
66	66	66	3	t
67	67	67	16	f
68	68	68	64	f
69	69	69	10	t
70	70	70	50	t
71	71	71	57	t
72	72	72	23	t
73	73	73	9	f
74	74	74	68	t
75	75	75	52	t
76	76	76	62	f
77	77	77	3	f
78	78	78	67	t
79	79	79	26	f
80	80	80	19	t
81	81	81	13	t
82	82	82	14	f
83	83	83	69	f
84	84	84	2	f
85	85	85	55	f
86	86	86	1	f
87	87	87	39	t
88	88	88	28	f
89	89	89	30	f
90	90	90	33	f
91	91	91	69	t
92	92	92	68	f
93	93	93	24	f
94	94	94	34	f
95	95	95	13	t
96	96	96	25	t
97	97	97	16	t
98	98	98	25	f
99	99	99	17	f
100	100	100	39	f
101	101	101	17	f
102	102	102	16	t
103	103	103	12	f
104	104	104	44	f
105	105	105	3	f
106	106	106	34	f
107	107	107	18	t
108	108	108	40	t
109	109	109	55	f
110	110	110	55	t
111	111	111	65	t
112	112	112	15	t
113	113	113	64	f
114	114	114	28	f
115	115	115	39	f
116	116	116	25	t
117	117	117	54	t
118	118	118	5	t
119	119	119	46	f
120	120	120	9	t
121	121	121	36	t
122	122	122	60	t
123	123	123	23	f
124	124	124	13	f
125	125	125	18	f
126	126	126	37	f
127	127	127	54	t
128	128	128	53	t
129	129	129	43	f
130	130	130	42	t
131	131	131	59	f
132	132	132	33	t
133	133	133	54	t
134	134	134	63	t
135	135	135	44	f
136	136	136	55	f
137	137	137	14	t
138	138	138	61	t
139	139	139	7	f
140	140	140	22	t
141	141	141	45	f
142	142	142	45	t
143	143	143	23	t
144	144	144	46	f
145	145	145	53	t
146	146	146	70	t
147	147	147	28	f
148	148	148	62	f
149	149	149	17	f
150	150	150	6	f
151	151	151	39	t
152	152	152	14	f
153	153	153	26	t
154	154	154	60	t
155	155	155	12	t
156	156	156	37	t
157	157	157	47	f
158	158	158	58	t
159	159	159	26	f
160	160	160	30	t
161	161	161	28	t
162	162	162	41	t
163	163	163	13	f
164	164	164	11	f
165	165	165	30	f
166	166	166	57	f
167	167	167	5	f
168	168	168	38	f
169	169	169	54	f
170	170	170	3	t
171	171	171	16	t
172	172	172	47	f
173	173	173	56	t
174	174	174	4	t
175	175	175	22	f
176	176	176	11	f
177	177	177	43	f
178	178	178	52	f
179	179	179	52	f
180	180	180	34	f
181	181	181	14	t
182	182	182	17	f
183	183	183	31	t
184	184	184	4	f
185	185	185	32	f
186	186	186	41	t
187	187	187	56	t
188	188	188	19	f
189	189	189	9	f
190	190	190	2	f
191	191	191	22	f
192	192	192	24	f
193	193	193	50	t
194	194	194	9	f
195	195	195	35	t
196	196	196	43	f
197	197	197	55	t
198	198	198	70	t
199	199	199	38	t
200	200	200	34	t
201	201	201	2	f
202	202	202	59	t
203	203	203	38	f
204	204	204	7	f
205	205	205	26	f
206	206	206	6	t
207	207	207	55	t
208	208	208	5	t
209	209	209	30	t
210	210	210	41	t
211	211	211	36	f
212	212	212	4	f
213	213	213	32	t
214	214	214	23	f
215	215	215	60	t
216	216	216	29	t
217	217	217	35	t
218	218	218	1	f
219	219	219	17	t
220	220	220	31	t
221	221	221	13	f
222	222	222	10	f
223	223	223	34	t
224	224	224	59	f
225	225	225	11	f
226	226	226	28	f
227	227	227	58	f
228	228	228	51	f
229	229	229	65	t
230	230	230	17	t
231	231	231	10	f
232	232	232	28	t
233	233	233	58	t
234	234	234	24	f
235	235	235	65	f
236	236	236	25	f
237	237	237	47	t
238	238	238	15	t
239	239	239	6	f
240	240	240	63	f
241	241	241	49	t
242	242	242	15	t
243	243	243	18	t
244	244	244	46	f
245	245	245	18	f
246	246	246	19	t
247	247	247	55	f
248	248	248	26	f
249	249	249	34	t
250	250	250	45	t
251	251	251	69	t
252	252	252	19	f
253	253	253	67	t
254	254	254	9	f
255	255	255	43	f
256	256	256	59	f
257	257	257	30	t
258	258	258	34	f
259	259	259	36	t
260	260	260	9	t
261	261	261	20	f
262	262	262	21	t
263	263	263	43	t
264	264	264	61	t
265	265	265	66	t
266	266	266	45	t
267	267	267	2	f
268	268	268	13	f
269	269	269	45	t
270	270	270	38	t
271	271	271	26	t
272	272	272	62	t
273	273	273	50	f
274	274	274	16	t
275	275	275	69	f
276	276	276	44	t
277	277	277	40	t
278	278	278	8	f
279	279	279	46	f
280	280	280	36	f
281	281	281	21	t
282	282	282	6	f
283	283	283	58	f
284	284	284	66	t
285	285	285	67	t
286	286	286	12	f
287	287	287	23	t
288	288	288	32	f
289	289	289	32	f
290	290	290	61	t
291	291	291	66	f
292	292	292	56	f
293	293	293	43	f
294	294	294	14	t
295	295	295	7	f
296	296	296	46	f
297	297	297	28	t
298	298	298	25	f
299	299	299	52	f
300	300	300	23	f
301	301	301	37	t
302	302	302	38	t
303	303	303	14	t
304	304	304	8	f
305	305	305	25	t
306	306	306	17	t
307	307	307	39	t
308	308	308	51	t
309	309	309	16	f
310	310	310	38	f
311	311	311	30	f
312	312	312	33	t
313	313	313	53	f
314	314	314	5	f
315	315	315	53	f
316	316	316	67	t
317	317	317	24	t
318	318	318	51	f
319	319	319	35	f
320	320	320	70	f
321	321	321	24	f
322	322	322	40	f
323	323	323	54	t
324	324	324	29	f
325	325	325	65	f
326	326	326	37	f
327	327	327	37	f
328	328	328	68	f
329	329	329	35	f
330	330	330	13	t
331	331	331	12	t
332	332	332	9	f
333	333	333	37	t
334	334	334	45	f
335	335	335	49	f
336	336	336	57	t
337	337	337	13	t
338	338	338	44	t
339	339	339	66	f
340	340	340	4	t
341	341	341	26	t
342	342	342	21	t
343	343	343	15	f
344	344	344	66	f
345	345	345	41	t
346	346	346	57	f
347	347	347	54	f
348	348	348	11	t
349	349	349	68	t
350	350	350	50	t
351	351	351	7	t
352	352	352	51	t
353	353	353	11	f
354	354	354	6	f
355	355	355	41	t
356	356	356	55	f
357	357	357	51	t
358	358	358	29	f
359	359	359	61	f
360	360	360	57	f
361	361	361	40	f
362	362	362	18	t
363	363	363	47	f
364	364	364	46	t
365	365	365	10	f
366	366	366	55	f
367	367	367	38	f
368	368	368	20	t
369	369	369	22	f
370	370	370	16	t
371	371	371	70	f
372	372	372	65	t
373	373	373	40	t
374	374	374	60	f
375	375	375	29	t
376	376	376	17	f
377	377	377	65	f
378	378	378	46	f
379	379	379	42	f
380	380	380	67	t
381	381	381	4	f
382	382	382	14	f
383	383	383	10	f
384	384	384	26	t
385	385	385	51	f
386	386	386	66	f
387	387	387	18	f
388	388	388	26	t
389	389	389	63	t
390	390	390	9	f
391	391	391	41	t
392	392	392	21	f
393	393	393	55	t
394	394	394	56	f
395	395	395	31	t
396	396	396	1	f
397	397	397	61	f
398	398	398	37	f
399	399	399	34	t
400	400	400	27	t
401	401	401	31	f
402	402	402	1	t
403	403	403	62	f
404	404	404	13	f
405	405	405	48	f
406	406	406	22	f
407	407	407	39	f
408	408	408	2	t
409	409	409	68	t
410	410	410	21	f
411	411	411	12	f
412	412	412	1	t
413	413	413	53	t
414	414	414	17	t
415	415	415	34	f
416	416	416	23	f
417	417	417	11	t
418	418	418	15	f
419	419	419	39	t
420	420	420	55	f
421	421	421	3	f
422	422	422	61	f
423	423	423	1	t
424	424	424	65	t
425	425	425	32	f
426	426	426	11	f
427	427	427	66	t
428	428	428	24	f
429	429	429	42	f
430	430	430	50	t
431	431	431	3	f
432	432	432	18	f
433	433	433	57	t
434	434	434	31	t
435	435	435	13	t
436	436	436	32	f
437	437	437	38	f
438	438	438	15	f
439	439	439	51	f
440	440	440	56	f
441	441	441	61	f
442	442	442	35	f
443	443	443	13	t
444	444	444	24	t
445	445	445	51	t
446	446	446	62	f
447	447	447	45	t
448	448	448	64	t
449	449	449	60	t
450	450	450	10	f
451	451	451	55	f
452	452	452	61	f
453	453	453	54	f
454	454	454	46	t
455	455	455	8	f
456	456	456	3	t
457	457	457	21	f
458	458	458	56	t
459	459	459	44	t
460	460	460	51	f
461	461	461	36	f
462	462	462	36	t
463	463	463	5	f
464	464	464	30	t
465	465	465	59	f
466	466	466	26	f
467	467	467	34	t
468	468	468	31	f
469	469	469	69	t
470	470	470	14	t
471	471	471	53	t
472	472	472	4	f
473	473	473	10	f
474	474	474	64	t
475	475	475	9	t
476	476	476	53	t
477	477	477	13	t
478	478	478	22	t
479	479	479	1	f
480	480	480	43	f
481	481	481	64	t
482	482	482	38	t
483	483	483	28	t
484	484	484	42	f
485	485	485	51	t
486	486	486	66	f
487	487	487	8	f
488	488	488	65	f
489	489	489	5	t
490	490	490	64	t
491	491	491	64	t
492	492	492	7	t
493	493	493	30	t
494	494	494	24	f
495	495	495	51	t
496	496	496	44	f
497	497	497	36	t
498	498	498	43	t
499	499	499	9	t
500	500	500	43	t
501	501	501	20	f
502	502	502	69	f
503	503	503	47	f
504	504	504	65	t
505	505	505	56	t
506	506	506	67	f
507	507	507	18	f
508	508	508	39	t
509	509	509	54	f
510	510	510	22	f
511	511	511	23	t
512	512	512	70	f
513	513	513	4	t
514	514	514	19	t
515	515	515	44	f
516	516	516	28	t
517	517	517	6	f
518	518	518	46	f
519	519	519	48	f
520	520	520	6	t
521	521	521	61	f
522	522	522	1	t
523	523	523	62	t
524	524	524	39	f
525	525	525	4	t
526	526	526	59	f
527	527	527	17	f
528	528	528	37	f
529	529	529	21	f
530	530	530	53	t
531	531	531	52	f
532	532	532	22	t
533	533	533	11	t
534	534	534	13	t
535	535	535	6	t
536	536	536	22	t
537	537	537	64	t
538	538	538	27	t
539	539	539	36	t
540	540	540	18	f
541	541	541	46	f
542	542	542	46	t
543	543	543	3	t
544	544	544	50	f
545	545	545	68	t
546	546	546	31	t
547	547	547	62	t
548	548	548	12	t
549	549	549	56	f
550	550	550	56	f
551	551	551	5	t
552	552	552	34	f
553	553	553	18	f
554	554	554	24	t
555	555	555	8	t
556	556	556	47	f
557	557	557	27	t
558	558	558	12	t
559	559	559	12	f
560	560	560	4	f
561	561	561	30	f
562	562	562	20	f
563	563	563	52	f
564	564	564	5	t
565	565	565	57	t
566	566	566	45	t
567	567	567	22	t
568	568	568	64	f
569	569	569	24	f
570	570	570	26	t
571	571	571	14	t
572	572	572	41	f
573	573	573	60	t
574	574	574	29	t
575	575	575	35	t
576	576	576	3	f
577	577	577	45	t
578	578	578	52	f
579	579	579	42	f
580	580	580	39	t
581	581	581	41	f
582	582	582	45	f
583	583	583	54	t
584	584	584	61	f
585	585	585	61	t
586	586	586	37	t
587	587	587	16	f
588	588	588	15	t
589	589	589	30	f
590	590	590	22	t
591	591	591	58	f
592	592	592	44	f
593	593	593	70	t
594	594	594	54	f
595	595	595	37	t
596	596	596	55	f
597	597	597	47	t
598	598	598	20	t
599	599	599	2	t
600	600	600	17	f
601	601	601	30	t
602	602	602	6	t
603	603	603	7	t
604	604	604	57	f
605	605	605	45	t
606	606	606	44	f
607	607	607	1	t
608	608	608	54	t
609	609	609	19	t
610	610	610	49	f
611	611	611	6	f
612	612	612	57	t
613	613	613	25	t
614	614	614	21	t
615	615	615	20	t
616	616	616	20	f
617	617	617	64	f
618	618	618	69	t
619	619	619	28	t
620	620	620	20	f
621	621	621	2	f
622	622	622	47	t
623	623	623	30	f
624	624	624	1	f
625	625	625	14	t
626	626	626	61	f
627	627	627	63	t
628	628	628	22	t
629	629	629	37	t
630	630	630	59	t
631	631	631	42	f
632	632	632	6	f
633	633	633	41	f
634	634	634	61	f
635	635	635	70	f
636	636	636	45	f
637	637	637	12	f
638	638	638	50	t
639	639	639	58	t
640	640	640	21	f
641	641	641	38	f
642	642	642	35	t
643	643	643	16	t
644	644	644	63	t
645	645	645	23	t
646	646	646	68	f
647	647	647	13	t
648	648	648	58	t
649	649	649	45	f
650	650	650	18	f
651	651	651	67	t
652	652	652	61	t
653	653	653	13	f
654	654	654	33	t
655	655	655	22	t
656	656	656	66	t
657	657	657	10	f
658	658	658	70	t
659	659	659	17	t
660	660	660	24	f
661	661	661	42	f
662	662	662	17	t
663	663	663	2	t
664	664	664	9	f
665	665	665	66	f
666	666	666	43	t
667	667	667	47	f
668	668	668	39	f
669	669	669	11	t
670	670	670	12	f
671	671	671	47	t
672	672	672	13	t
673	673	673	52	f
674	674	674	9	t
675	675	675	32	t
676	676	676	11	t
677	677	677	55	t
678	678	678	43	t
679	679	679	51	f
680	680	680	4	t
681	681	681	12	f
682	682	682	56	f
683	683	683	46	f
684	684	684	63	t
685	685	685	21	t
686	686	686	5	f
687	687	687	37	f
688	688	688	28	t
689	689	689	60	f
690	690	690	25	f
691	691	691	58	f
692	692	692	7	f
693	693	693	68	f
694	694	694	55	f
695	695	695	8	t
696	696	696	2	f
697	697	697	32	t
698	698	698	59	f
699	699	699	44	f
700	700	700	19	f
701	701	701	39	t
702	702	702	26	t
703	703	703	3	t
704	704	704	37	f
705	705	705	38	t
706	706	706	9	t
707	707	707	5	f
708	708	708	50	t
709	709	709	52	f
710	710	710	46	t
711	711	711	63	t
712	712	712	37	f
713	713	713	32	f
714	714	714	36	f
715	715	715	30	t
716	716	716	53	t
717	717	717	23	f
718	718	718	64	t
719	719	719	57	f
720	720	720	13	t
721	721	721	53	f
722	722	722	8	t
723	723	723	54	f
724	724	724	11	t
725	725	725	41	t
726	726	726	52	t
727	727	727	15	f
728	728	728	68	f
729	729	729	22	t
730	730	730	7	t
731	731	731	13	f
732	732	732	15	t
733	733	733	37	f
734	734	734	47	t
735	735	735	16	t
736	736	736	41	t
737	737	737	10	t
738	738	738	25	t
739	739	739	25	f
740	740	740	39	f
741	741	741	26	t
742	742	742	37	t
743	743	743	38	f
744	744	744	54	t
745	745	745	55	t
746	746	746	39	t
747	747	747	29	t
748	748	748	65	t
749	749	749	8	f
750	750	750	33	f
751	751	751	2	t
752	752	752	46	t
753	753	753	57	t
754	754	754	63	t
755	755	755	45	f
756	756	756	53	t
757	757	757	69	f
758	758	758	59	f
759	759	759	58	f
760	760	760	40	f
761	761	761	14	t
762	762	762	26	f
763	763	763	33	f
764	764	764	7	t
765	765	765	63	f
766	766	766	67	t
767	767	767	11	t
768	768	768	55	f
769	769	769	4	f
770	770	770	22	f
771	771	771	26	t
772	772	772	69	f
773	773	773	68	f
774	774	774	31	t
775	775	775	33	f
776	776	776	57	t
777	777	777	65	t
778	778	778	58	f
779	779	779	12	f
780	780	780	67	t
781	781	781	48	f
782	782	782	59	t
783	783	783	43	t
784	784	784	36	f
785	785	785	18	t
786	786	786	6	t
787	787	787	43	t
788	788	788	64	f
789	789	789	57	f
790	790	790	47	f
791	791	791	36	f
792	792	792	57	t
793	793	793	4	t
794	794	794	66	t
795	795	795	30	t
796	796	796	20	t
797	797	797	4	f
798	798	798	57	t
799	799	799	32	f
800	800	800	70	f
801	801	801	21	t
802	802	802	18	f
803	803	803	35	f
804	804	804	7	f
805	805	805	35	f
806	806	806	17	f
807	807	807	15	t
808	808	808	37	f
809	809	809	47	t
810	810	810	23	f
811	811	811	67	f
812	812	812	2	f
813	813	813	35	f
814	814	814	56	t
815	815	815	67	f
816	816	816	3	f
817	817	817	28	f
818	818	818	47	f
819	819	819	43	t
820	820	820	18	t
821	821	821	35	t
822	822	822	32	f
823	823	823	3	t
824	824	824	15	t
825	825	825	37	t
826	826	826	60	f
827	827	827	57	t
828	828	828	48	f
829	829	829	56	t
830	830	830	6	f
831	831	831	59	t
832	832	832	65	f
833	833	833	62	t
834	834	834	17	t
835	835	835	25	t
836	836	836	25	t
837	837	837	19	t
838	838	838	34	f
839	839	839	40	t
840	840	840	11	f
841	841	841	52	f
842	842	842	51	t
843	843	843	5	t
844	844	844	44	t
845	845	845	44	f
846	846	846	10	f
847	847	847	10	t
848	848	848	51	t
849	849	849	51	f
850	850	850	12	f
851	851	851	10	f
852	852	852	41	f
853	853	853	45	t
854	854	854	2	t
855	855	855	4	t
856	856	856	2	t
857	857	857	26	f
858	858	858	44	t
859	859	859	27	t
860	860	860	6	t
861	861	861	48	f
862	862	862	17	f
863	863	863	39	t
864	864	864	48	t
865	865	865	16	t
866	866	866	23	f
867	867	867	27	t
868	868	868	67	t
869	869	869	31	f
870	870	870	3	t
871	871	871	1	f
872	872	872	6	t
873	873	873	20	t
874	874	874	52	f
875	875	875	52	t
876	876	876	11	f
877	877	877	52	t
878	878	878	42	t
879	879	879	3	f
880	880	880	21	f
881	881	881	19	t
882	882	882	21	f
883	883	883	29	t
884	884	884	14	t
885	885	885	33	f
886	886	886	26	f
887	887	887	68	f
888	888	888	64	t
889	889	889	49	f
890	890	890	10	t
891	891	891	44	f
892	892	892	47	t
893	893	893	70	f
894	894	894	4	t
895	895	895	58	f
896	896	896	66	f
897	897	897	23	t
898	898	898	66	t
899	899	899	5	t
900	900	900	41	f
901	901	901	38	f
902	902	902	19	f
903	903	903	16	f
904	904	904	49	t
905	905	905	60	t
906	906	906	45	f
907	907	907	31	t
908	908	908	47	t
909	909	909	18	f
910	910	910	15	t
911	911	911	44	t
912	912	912	64	t
913	913	913	36	f
914	914	914	1	t
915	915	915	66	f
916	916	916	14	f
917	917	917	13	t
918	918	918	37	t
919	919	919	16	t
920	920	920	26	f
921	921	921	39	t
922	922	922	51	f
923	923	923	7	t
924	924	924	42	f
925	925	925	18	f
926	926	926	36	t
927	927	927	57	t
928	928	928	44	f
929	929	929	45	t
930	930	930	2	t
931	931	931	53	t
932	932	932	43	t
933	933	933	63	f
934	934	934	66	f
935	935	935	34	f
936	936	936	70	t
937	937	937	48	t
938	938	938	55	t
939	939	939	57	f
940	940	940	28	t
941	941	941	12	f
942	942	942	26	f
943	943	943	31	f
944	944	944	32	t
945	945	945	3	t
946	946	946	35	f
947	947	947	59	f
948	948	948	65	t
949	949	949	48	f
950	950	950	3	f
951	951	951	29	t
952	952	952	38	f
953	953	953	70	t
954	954	954	22	f
955	955	955	48	t
956	956	956	69	f
957	957	957	14	t
958	958	958	11	f
959	959	959	41	t
960	960	960	70	t
961	961	961	34	f
962	962	962	48	f
963	963	963	37	t
964	964	964	70	t
965	965	965	23	f
966	966	966	3	t
967	967	967	7	t
968	968	968	40	f
969	969	969	54	t
970	970	970	62	f
971	971	971	10	f
972	972	972	16	f
973	973	973	16	f
974	974	974	6	f
975	975	975	48	t
976	976	976	25	f
977	977	977	40	f
978	978	978	35	t
979	979	979	1	t
980	980	980	40	f
981	981	981	39	t
982	982	982	23	f
983	983	983	70	t
984	984	984	34	f
985	985	985	52	t
986	986	986	62	f
987	987	987	30	f
988	988	988	68	t
989	989	989	57	f
990	990	990	11	t
991	991	991	5	t
992	992	992	33	f
993	993	993	5	f
994	994	994	3	t
995	995	995	6	f
996	996	996	37	f
997	997	997	58	f
998	998	998	8	f
999	999	999	13	f
1000	1000	1000	8	f
\.


--
-- TOC entry 3179 (class 0 OID 16537)
-- Dependencies: 217
-- Data for Name: warhouse_stores_m_equipment; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.warhouse_stores_m_equipment (id_pharmacy_warhouse, id_medicine_equipment, number) FROM stdin;
1	1	2
1	2	3
2	3	4
3	4	5
5	5	3
6	6	5
7	7	7
8	8	6
9	9	10
10	10	25
11	11	27
12	12	38
13	13	47
14	14	57
15	15	4
16	16	51
17	17	10
18	18	5
19	19	58
20	20	19
21	21	60
22	22	48
23	23	15
24	24	34
25	25	3
26	26	43
27	27	11
28	28	17
29	29	52
30	30	32
31	31	25
32	32	23
33	33	46
34	34	21
35	35	8
36	36	58
37	37	38
38	38	27
39	39	45
40	40	57
41	41	36
42	42	51
43	43	31
44	44	40
45	45	35
46	46	37
47	47	53
48	48	43
49	49	7
50	50	35
51	51	22
52	52	59
53	53	55
54	54	24
55	55	32
56	56	18
57	57	41
58	58	34
59	59	38
60	60	44
61	61	6
62	62	58
63	63	12
64	64	19
65	65	50
66	66	44
67	67	60
68	68	41
69	69	13
70	70	60
71	71	29
72	72	46
73	73	54
74	74	47
75	75	26
76	76	7
77	77	55
78	78	9
79	79	10
80	80	22
81	81	18
82	82	59
83	83	3
84	84	55
85	85	58
86	86	21
87	87	36
88	88	26
89	89	1
90	90	21
91	91	9
92	92	34
93	93	42
94	94	56
95	95	33
96	96	27
97	97	8
98	98	12
99	99	11
100	100	26
101	101	55
102	102	5
103	103	28
104	104	23
105	105	28
106	106	23
107	107	21
108	108	20
109	109	41
110	110	31
111	111	6
112	112	29
113	113	18
114	114	55
115	115	9
116	116	45
117	117	52
118	118	40
119	119	19
120	120	5
121	121	27
122	122	38
123	123	5
124	124	39
125	125	42
126	126	55
127	127	22
128	128	29
129	129	40
130	130	12
131	131	14
132	132	54
133	133	59
134	134	2
135	135	39
136	136	29
137	137	20
138	138	26
139	139	48
140	140	25
141	141	56
142	142	30
143	143	26
144	144	17
145	145	15
146	146	14
147	147	3
148	148	46
149	149	48
150	150	6
151	151	2
152	152	49
153	153	38
154	154	45
155	155	4
156	156	35
157	157	8
158	158	51
159	159	41
160	160	54
161	161	52
162	162	34
163	163	7
164	164	2
165	165	44
166	166	13
167	167	47
168	168	3
169	169	16
170	170	14
171	171	7
172	172	43
173	173	26
174	174	23
175	175	9
176	176	12
177	177	42
178	178	50
179	179	20
180	180	56
181	181	23
182	182	59
183	183	11
184	184	16
185	185	36
186	186	58
187	187	52
188	188	4
189	189	4
190	190	57
191	191	19
192	192	36
193	193	43
194	194	24
195	195	37
196	196	27
197	197	10
198	198	21
199	199	26
200	200	19
201	201	10
202	202	2
203	203	55
204	204	48
205	205	57
206	206	37
207	207	34
208	208	59
209	209	35
210	210	6
211	211	50
212	212	5
213	213	2
214	214	22
215	215	59
216	216	9
217	217	28
218	218	30
219	219	15
220	220	8
221	221	60
222	222	22
223	223	42
224	224	31
225	225	60
226	226	14
227	227	13
228	228	1
229	229	47
230	230	32
231	231	18
232	232	16
233	233	26
234	234	56
235	235	57
236	236	53
237	237	13
238	238	45
239	239	60
240	240	24
241	241	8
242	242	39
243	243	40
244	244	25
245	245	56
246	246	13
247	247	30
248	248	56
249	249	45
250	250	29
251	251	9
252	252	24
253	253	32
254	254	28
255	255	20
256	256	21
257	257	11
258	258	5
259	259	52
260	260	23
261	261	12
262	262	23
263	263	19
264	264	33
265	265	46
266	266	10
267	267	45
268	268	52
269	269	44
270	270	28
271	271	6
272	272	16
273	273	38
274	274	57
275	275	30
276	276	53
277	277	7
278	278	41
279	279	37
280	280	20
281	281	2
282	282	41
283	283	54
284	284	21
285	285	33
286	286	55
287	287	9
288	288	47
289	289	40
290	290	58
291	291	41
292	292	57
293	293	30
294	294	19
295	295	20
296	296	21
297	297	51
298	298	4
299	299	56
300	300	12
301	301	4
302	302	21
303	303	36
304	304	41
305	305	60
306	306	20
307	307	54
308	308	16
309	309	20
310	310	46
311	311	23
312	312	17
313	313	19
314	314	57
315	315	8
316	316	8
317	317	28
318	318	41
319	319	46
320	320	44
321	321	27
322	322	19
323	323	23
324	324	13
325	325	42
326	326	24
327	327	52
328	328	56
329	329	59
330	330	14
331	331	13
332	332	23
333	333	52
334	334	8
335	335	52
336	336	9
337	337	14
338	338	5
339	339	47
340	340	15
341	341	58
342	342	26
343	343	6
344	344	33
345	345	3
346	346	12
347	347	33
348	348	52
349	349	25
350	350	3
351	351	14
352	352	13
353	353	46
354	354	54
355	355	13
356	356	45
357	357	31
358	358	47
359	359	49
360	360	52
361	361	19
362	362	32
363	363	5
364	364	36
365	365	33
366	366	22
367	367	46
368	368	25
369	369	52
370	370	31
371	371	31
372	372	23
373	373	48
374	374	15
375	375	1
376	376	22
377	377	49
378	378	56
379	379	47
380	380	59
381	381	34
382	382	37
383	383	38
384	384	49
385	385	31
386	386	56
387	387	3
388	388	43
389	389	7
390	390	11
391	391	41
392	392	21
393	393	59
394	394	34
395	395	14
396	396	18
397	397	50
398	398	50
399	399	4
400	400	44
401	401	33
402	402	22
403	403	36
404	404	35
405	405	20
406	406	26
407	407	45
408	408	27
409	409	52
410	410	42
411	411	16
412	412	25
413	413	26
414	414	19
415	415	45
416	416	48
417	417	16
418	418	41
419	419	13
420	420	32
421	421	14
422	422	36
423	423	46
424	424	12
425	425	16
426	426	52
427	427	12
428	428	10
429	429	30
430	430	25
431	431	39
432	432	55
433	433	41
434	434	9
435	435	33
436	436	9
437	437	50
438	438	11
439	439	26
440	440	29
441	441	40
442	442	3
443	443	38
444	444	56
445	445	37
446	446	54
447	447	33
448	448	11
449	449	14
450	450	22
451	451	26
452	452	21
453	453	60
454	454	36
455	455	31
456	456	51
457	457	47
458	458	18
459	459	27
460	460	10
461	461	30
462	462	59
463	463	19
464	464	32
465	465	30
466	466	11
467	467	29
468	468	18
469	469	40
470	470	26
471	471	34
472	472	34
473	473	45
474	474	14
475	475	19
476	476	37
477	477	41
478	478	29
479	479	5
480	480	19
481	481	31
482	482	28
483	483	52
484	484	54
485	485	40
486	486	10
487	487	58
488	488	21
489	489	19
490	490	60
491	491	6
492	492	10
493	493	25
494	494	17
495	495	19
496	496	15
497	497	40
498	498	21
499	499	1
500	500	46
501	501	53
502	502	37
503	503	34
504	504	1
505	505	17
506	506	1
507	507	43
508	508	40
509	509	35
510	510	60
511	511	31
512	512	37
513	513	59
514	514	38
515	515	16
516	516	5
517	517	52
518	518	5
519	519	2
520	520	52
521	521	21
522	522	5
523	523	50
524	524	34
525	525	41
526	526	53
527	527	7
528	528	25
529	529	34
530	530	8
531	531	33
532	532	52
533	533	59
534	534	36
535	535	42
536	536	26
537	537	30
538	538	48
539	539	40
540	540	28
541	541	44
542	542	39
543	543	8
544	544	36
545	545	42
546	546	3
547	547	18
548	548	15
549	549	15
550	550	4
551	551	23
552	552	39
553	553	51
554	554	42
555	555	8
556	556	35
557	557	36
558	558	31
559	559	35
560	560	13
561	561	25
562	562	4
563	563	9
564	564	57
565	565	51
566	566	17
567	567	3
568	568	24
569	569	24
570	570	29
571	571	50
572	572	48
573	573	50
574	574	43
575	575	11
576	576	44
577	577	50
578	578	38
579	579	58
580	580	44
581	581	57
582	582	36
583	583	30
584	584	19
585	585	43
586	586	11
587	587	51
588	588	54
589	589	7
590	590	45
591	591	50
592	592	11
593	593	6
594	594	47
595	595	14
596	596	38
597	597	11
598	598	57
599	599	51
600	600	7
601	601	39
602	602	35
603	603	53
604	604	3
605	605	13
606	606	50
607	607	30
608	608	26
609	609	18
610	610	25
611	611	37
612	612	53
613	613	37
614	614	16
615	615	1
616	616	16
617	617	55
618	618	2
619	619	41
620	620	36
621	621	1
622	622	46
623	623	16
624	624	20
625	625	5
626	626	14
627	627	21
628	628	39
629	629	31
630	630	59
631	631	11
632	632	2
633	633	4
634	634	55
635	635	25
636	636	37
637	637	53
638	638	1
639	639	7
640	640	30
641	641	15
642	642	26
643	643	49
644	644	6
645	645	46
646	646	12
647	647	44
648	648	3
649	649	29
650	650	1
651	651	9
652	652	45
653	653	13
654	654	51
655	655	57
656	656	15
657	657	54
658	658	11
659	659	11
660	660	6
661	661	58
662	662	38
663	663	50
664	664	10
665	665	45
666	666	17
667	667	52
668	668	44
669	669	20
670	670	20
671	671	47
672	672	45
673	673	9
674	674	49
675	675	21
676	676	48
677	677	24
678	678	35
679	679	41
680	680	30
681	681	50
682	682	40
683	683	54
684	684	7
685	685	8
686	686	18
687	687	38
688	688	30
689	689	58
690	690	24
691	691	30
692	692	53
693	693	19
694	694	44
695	695	21
696	696	51
697	697	22
698	698	7
699	699	52
700	700	34
701	701	30
702	702	30
703	703	6
704	704	45
705	705	27
706	706	43
707	707	59
708	708	41
709	709	26
710	710	20
711	711	42
712	712	17
713	713	18
714	714	34
715	715	2
716	716	8
717	717	44
718	718	14
719	719	40
720	720	28
721	721	35
722	722	46
723	723	56
724	724	27
725	725	15
726	726	23
727	727	40
728	728	22
729	729	50
730	730	20
731	731	51
732	732	9
733	733	4
734	734	47
735	735	60
736	736	12
737	737	21
738	738	32
739	739	23
740	740	26
741	741	10
742	742	44
743	743	46
744	744	30
745	745	6
746	746	45
747	747	3
748	748	22
749	749	55
750	750	52
751	751	13
752	752	6
753	753	33
754	754	4
755	755	38
756	756	50
757	757	54
758	758	6
759	759	4
760	760	60
761	761	49
762	762	15
763	763	15
764	764	23
765	765	8
766	766	26
767	767	37
768	768	40
769	769	22
770	770	38
771	771	14
772	772	47
773	773	28
774	774	55
775	775	44
776	776	53
777	777	15
778	778	30
779	779	30
780	780	39
781	781	43
782	782	40
783	783	7
784	784	7
785	785	19
786	786	9
787	787	31
788	788	50
789	789	57
790	790	40
791	791	4
792	792	59
793	793	52
794	794	13
795	795	33
796	796	45
797	797	6
798	798	9
799	799	23
800	800	34
801	801	36
802	802	17
803	803	48
804	804	43
805	805	11
806	806	51
807	807	29
808	808	37
809	809	57
810	810	60
811	811	12
812	812	36
813	813	32
814	814	6
815	815	31
816	816	53
817	817	18
818	818	37
819	819	23
820	820	1
821	821	38
822	822	7
823	823	51
824	824	48
825	825	55
826	826	44
827	827	59
828	828	23
829	829	19
830	830	40
831	831	38
832	832	37
833	833	14
834	834	58
835	835	35
836	836	21
837	837	26
838	838	36
839	839	42
840	840	50
841	841	22
842	842	17
843	843	8
844	844	35
845	845	36
846	846	51
847	847	11
848	848	9
849	849	17
850	850	41
851	851	21
852	852	18
853	853	43
854	854	27
855	855	38
856	856	5
857	857	18
858	858	24
859	859	3
860	860	18
861	861	39
862	862	9
863	863	37
864	864	6
865	865	21
866	866	29
867	867	10
868	868	41
869	869	42
870	870	34
871	871	24
872	872	47
873	873	53
874	874	44
875	875	1
876	876	29
877	877	60
878	878	25
879	879	49
880	880	52
881	881	52
882	882	24
883	883	57
884	884	42
885	885	47
886	886	8
887	887	55
888	888	13
889	889	11
890	890	48
891	891	9
892	892	53
893	893	28
894	894	60
895	895	13
896	896	54
897	897	14
898	898	37
899	899	13
900	900	31
901	901	30
902	902	38
903	903	28
904	904	56
905	905	60
906	906	36
907	907	56
908	908	21
909	909	39
910	910	28
911	911	30
912	912	35
913	913	58
914	914	57
915	915	38
916	916	52
917	917	49
918	918	58
919	919	13
920	920	30
921	921	3
922	922	7
923	923	26
924	924	26
925	925	9
926	926	9
927	927	19
928	928	17
929	929	18
930	930	35
931	931	55
932	932	20
933	933	35
934	934	59
935	935	22
936	936	34
937	937	29
938	938	55
939	939	22
940	940	4
941	941	57
942	942	12
943	943	27
944	944	8
945	945	4
946	946	7
947	947	55
948	948	17
949	949	16
950	950	40
951	951	34
952	952	43
953	953	37
954	954	28
955	955	50
956	956	8
957	957	54
958	958	37
959	959	56
960	960	19
961	961	13
962	962	55
963	963	28
964	964	8
965	965	39
966	966	22
967	967	9
968	968	57
969	969	41
970	970	16
971	971	33
972	972	9
973	973	49
974	974	22
975	975	54
976	976	11
977	977	8
978	978	12
979	979	45
980	980	39
981	981	6
982	982	58
983	983	21
984	984	19
985	985	30
986	986	50
987	987	28
988	988	10
989	989	51
990	990	5
991	991	1
992	992	60
993	993	44
994	994	39
995	995	38
996	996	60
997	997	47
998	998	11
999	999	10
1000	1000	18
\.


--
-- TOC entry 3181 (class 0 OID 16555)
-- Dependencies: 219
-- Data for Name: worker; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.worker (id, name, surname, id_warhouse, id_position) FROM stdin;
1	Иван	Андреев	1	1
2	Николай	Рыбков	2	1
3	Артём	Ларук	3	2
4	Геннадий	Гаманюк	4	1
5	Александр	Ларуина	5	1
7	Вадим	Гуртов	7	1
8	Кирилл	Фадеев	8	1
9	Юрий	Демедович	9	1
10	Дмитрий	Биркин	10	1
6	Олег	Цыкиль	6	2
11	Guthrie	Corrington	11	2
12	Deny	Brownsall	12	1
13	Britni	Stainbridge	13	1
14	Maddalena	Cage	14	1
15	Karoly	Cundey	15	1
16	Mitchel	Pittson	16	2
17	Crichton	Ladbury	17	1
18	Rey	Phalip	18	2
19	Leanor	Georghiou	19	1
20	Floria	Haddinton	20	1
21	Nellie	Korlat	21	2
22	Emilio	Kemitt	22	2
23	Kathi	Goare	23	1
24	Hilarius	Cardnell	24	2
25	Sigfried	Conti	25	1
26	Reuben	Fabbri	26	2
27	Donielle	Lowthorpe	27	1
28	Nita	Schimpke	28	1
29	Herold	Rohlfing	29	1
30	Carin	Tewkesbury	30	2
31	Mattie	Danilovic	31	2
32	Patty	Ingleton	32	1
33	Jess	Vellender	33	1
34	Lorrin	Ravelus	34	1
35	Blair	Timcke	35	1
36	Silvan	Sturney	36	1
37	Joni	Peagrim	37	1
38	Dee	Riley	38	1
39	Celine	Lelande	39	2
40	Paco	Sillars	40	2
41	Rollie	Smidmore	41	1
42	Reuven	Hrinishin	42	2
43	Nikaniki	Wynch	43	2
44	Nerti	Lovie	44	1
45	Shermie	MacCaffery	45	1
46	Dallon	Ashtonhurst	46	1
47	Bonnie	Brimble	47	1
48	Mathilde	Kibbel	48	1
49	Wallas	Pabel	49	1
50	Doretta	Chatto	50	1
51	Midge	Bruckman	51	1
52	Ripley	Searsby	52	1
53	Rosina	Shaughnessy	53	2
54	Merrel	Belmont	54	1
55	Ruddy	Chevin	55	1
56	Northrup	Brookton	56	1
57	Natty	Grenter	57	1
58	Yule	Kropach	58	1
59	Marcelline	Madison	59	2
60	Galvin	Brockelsby	60	1
61	Basilio	Timmis	61	1
62	Maddie	Crolly	62	1
63	Erv	Cota	63	1
64	Aline	Jellman	64	1
65	Marty	Kelley	65	2
66	Alva	Speek	66	1
67	Roseanne	Bockmann	67	1
68	Mason	Exter	68	1
69	Murry	Romei	69	1
70	Elihu	Tambling	70	2
71	Cass	Wiles	71	1
72	Kalil	Knowling	72	2
73	Tonie	Grinnov	73	2
74	Margarita	Elford	74	2
75	Lanette	Thornbarrow	75	1
76	Sherye	von Hagt	76	1
77	Max	Seale	77	1
78	Tomi	Haddy	78	2
79	Gerri	Thornborrow	79	1
80	Hagan	Maffetti	80	2
81	Leonhard	Fahey	81	1
82	Claudette	Aguirre	82	1
83	Feodora	MacCurley	83	2
84	Liesa	Cahani	84	1
85	Devon	Astell	85	2
86	Tremain	Yoodall	86	1
87	Skippie	Rubroe	87	1
88	Amanda	Kynett	88	1
89	Ralf	Burrage	89	1
90	Derril	Bruniges	90	1
91	Dru	Bubbings	91	1
92	Celie	Achurch	92	1
93	Arleta	Henrie	93	1
94	Violet	Stapleton	94	1
95	Floria	Lardnar	95	1
96	Violet	Fordyce	96	1
97	Ferrell	Smythin	97	1
98	Francine	Donhardt	98	1
99	Alexi	Summerhayes	99	1
100	Cherey	Kaliszewski	100	1
101	Romain	Matthius	101	1
102	Lilian	Barz	102	1
103	Ludovico	Geffcock	103	1
104	Alice	Flode	104	1
105	Aura	Luker	105	2
106	Emilee	Kuhndel	106	1
107	Goldia	Tutt	107	1
108	Colleen	Crack	108	1
109	Holt	Stenyng	109	2
110	Nicole	Woofinden	110	2
111	Mellicent	Ogbourne	111	1
112	Melosa	Redon	112	1
113	Charles	Snaith	113	1
114	Phelia	Snipe	114	2
115	Aubrette	Djekovic	115	1
116	Melisent	Hawney	116	1
117	Ingrim	Awdry	117	1
118	Darleen	Collingham	118	1
119	Alexander	Micheu	119	1
120	Celestine	Krugmann	120	1
121	Zebulon	Cops	121	2
122	Erena	Dumini	122	1
123	Elvis	Guise	123	1
124	Anissa	Keneford	124	1
125	Sawyere	Banyard	125	2
126	Gabi	Marley	126	1
127	Jodie	Gayler	127	1
128	Johannes	Mallinar	128	1
129	Neddy	McAsgill	129	1
130	Jermaine	Servante	130	2
131	Elijah	Mathou	131	1
132	Bradan	Hunnable	132	1
133	Paul	Atkirk	133	1
134	Jocko	Gokes	134	2
135	Shaylyn	Mayor	135	2
136	Ritchie	Udden	136	1
137	Golda	McDonand	137	1
138	Rolland	Garmanson	138	2
139	Leann	MacGorrie	139	1
140	Karolina	Cameron	140	2
141	Lillis	De Cruce	141	1
142	Rockey	Finlan	142	1
143	Sanson	Drillingcourt	143	2
144	Kearney	Eagleton	144	1
145	Elijah	Benet	145	1
146	Kristos	Heaford	146	1
147	Royall	Stollenberg	147	1
148	Margaretta	Wolfit	148	1
149	Mikel	Lehrahan	149	1
150	Aurelia	Vivash	150	1
151	Larisa	Djordjevic	151	1
152	Vera	Baford	152	1
153	Netty	Phidgin	153	2
154	Hagen	D'Aeth	154	2
155	Somerset	Verlander	155	1
156	Dion	Bossom	156	2
157	Odette	Kliner	157	1
158	Dulcine	Joost	158	1
159	Eolande	Antal	159	1
160	Vernon	Ricardin	160	1
161	Elmer	Iuorio	161	1
162	Faustine	Bixley	162	2
163	Hank	MacGillicuddy	163	2
164	Jo ann	Bradder	164	1
165	Nanice	Cacacie	165	1
166	Carrol	Blackburne	166	1
167	Garek	Jinkins	167	1
168	Kristien	Mealiffe	168	1
169	Jess	Kilbride	169	2
170	Goddart	Newlyn	170	1
171	Joline	Lillow	171	2
172	Minetta	Hanbury	172	1
173	Noll	Dimitriou	173	1
174	Richy	Hobble	174	1
175	Joice	Forty	175	1
176	Merry	Filtness	176	1
177	Morgana	Hadwin	177	1
178	Harv	Kezourec	178	1
179	Tammie	Gomby	179	1
180	Rolf	Haward	180	1
181	Courtnay	Baynham	181	1
182	Elberta	Bennitt	182	1
183	Jennifer	Soall	183	1
184	Gwendolin	O'Fogarty	184	2
185	Genevieve	Tyrrell	185	2
186	Beatrix	Cello	186	1
187	Raimundo	Kleinstein	187	1
188	Alene	Guyton	188	1
189	Nata	Eite	189	1
190	Wynnie	Marzelo	190	2
191	Fair	Corssen	191	2
192	King	Whitter	192	1
193	Helaine	Iggo	193	1
194	Carroll	Steinham	194	1
195	Chase	Grewar	195	1
196	Pail	Pabst	196	1
197	Sibel	Truse	197	2
198	Nelly	Aronsohn	198	1
199	Jorge	Loude	199	1
200	Jammie	Garret	200	2
201	Burlie	Brokenshaw	201	2
202	Alessandro	Cameron	202	1
203	Pepi	Dugald	203	1
204	Sauveur	Carmichael	204	1
205	Raven	Horsted	205	1
206	Charity	Smithyman	206	1
207	Koo	Shearston	207	2
208	Davidson	Revans	208	1
209	Lorri	Moy	209	1
210	Herrick	Hatz	210	1
211	Royall	Pettecrew	211	1
212	Burnard	Bouda	212	1
213	Silvain	Holley	213	1
214	Michele	Kenton	214	1
215	Annette	Dimitrescu	215	2
216	Desdemona	De'Vere - Hunt	216	1
217	Kienan	Gwyer	217	1
218	Zak	Lyvon	218	2
219	Licha	Worvell	219	1
220	Regine	Collete	220	1
221	Elvin	Herche	221	1
222	Shurlock	Arndt	222	2
223	Vladimir	Gogan	223	2
224	Emalee	Estabrook	224	1
225	Berthe	Kellie	225	1
226	Rorke	Duxbury	226	1
227	Alessandro	Golds	227	1
228	Scot	McGorley	228	1
229	Bary	Starton	229	1
230	Madalyn	Boyford	230	1
231	Lorette	Toxell	231	1
232	Kit	Marjot	232	1
233	Ethel	Roseveare	233	1
234	Hogan	Heugel	234	1
235	Amelie	Slaney	235	1
236	Renate	Dobbin	236	1
237	Nellie	Faithfull	237	2
238	Lyndsey	Noddle	238	1
239	Prisca	Edinborough	239	1
240	Adriana	Jadczak	240	2
241	Abra	Shiell	241	1
242	Lanita	Hurleston	242	1
243	Mac	Duplan	243	1
244	Melisent	Dell Casa	244	1
245	Ogdon	Hewell	245	1
246	Cecilia	Sandal	246	1
247	Aguste	Vernau	247	1
248	Corby	Killingworth	248	1
249	Redd	Nother	249	2
250	Kimberly	Copley	250	1
251	Sandra	Arnett	251	1
252	Babb	Marnes	252	1
253	Coretta	Connow	253	1
254	Evangelia	Sainthill	254	1
255	Nananne	Anthes	255	1
256	Vanny	Carnihan	256	1
257	Bessie	Karpol	257	1
258	Goran	Sprague	258	1
259	Lanae	Maciocia	259	1
260	Aubrette	Branigan	260	1
261	Elvera	Stapleford	261	2
262	Cletus	Gimblett	262	2
263	Janine	Nesby	263	1
264	Timmi	Shyres	264	1
265	Tammie	Stoppard	265	1
266	Cairistiona	MacIlurick	266	1
267	Bernarr	Breazeall	267	2
268	Levin	Slimm	268	1
269	Anastasia	Silverton	269	2
270	Emmery	MacArdle	270	1
271	Pattie	Terne	271	2
272	Lanette	Olliff	272	1
273	Othello	Fick	273	1
274	Trent	Gregan	274	1
275	Goldie	Storrie	275	1
276	Theodoric	Bartzen	276	1
277	Samara	Coolahan	277	1
278	Krishnah	Gosson	278	1
279	Mignon	Dinzey	279	1
280	Leigh	MacElharge	280	1
281	Shandra	Ishchenko	281	1
282	Davide	Bartolomivis	282	1
283	Benedikt	Shillum	283	1
284	Van	Norwich	284	1
285	Averil	Drioli	285	1
286	Leona	Davidescu	286	2
287	Zaria	Maryon	287	1
288	Melicent	Littlemore	288	2
289	Noam	Chaldecott	289	1
290	Faydra	Daubeny	290	1
291	Swen	Bartoszek	291	1
292	Bernelle	Hackwell	292	1
293	Shelagh	Tures	293	1
294	Benjy	Goodchild	294	1
295	Yetta	Le Galle	295	1
296	Ronald	Danovich	296	1
297	Findley	Chater	297	1
298	Fayette	Obispo	298	1
299	Mord	Dymocke	299	1
300	Joell	Sheran	300	1
301	Bunnie	Lerven	301	1
302	Richardo	Lexa	302	1
303	Trip	Mainz	303	1
304	Myrtice	Gaywood	304	1
305	Felicle	Sutherns	305	2
306	Caryl	Tejero	306	1
307	Keith	Coniff	307	2
308	Consalve	Campbell-Dunlop	308	1
309	Tracee	Krale	309	2
310	Ferrel	Magog	310	2
311	Aleen	Sandcraft	311	1
312	Jenn	Goulborn	312	1
313	Giraud	Libero	313	1
314	Justus	Mytton	314	1
315	Cyndi	Ostler	315	1
316	Maryjane	Chiles	316	2
317	Inigo	Fenna	317	1
318	Tiffany	Larver	318	2
319	Irvine	Dmitr	319	1
320	Pietro	Petrolli	320	1
321	Antonie	Dallmann	321	2
322	Josephina	MacCome	322	2
323	Albert	Machen	323	2
324	Katuscha	Ondrus	324	1
325	Zaria	Crawforth	325	2
326	Gabriello	Dinesen	326	1
327	Calvin	Eddowes	327	1
328	Tasha	Dundendale	328	2
329	Heidie	Barrowcliffe	329	1
330	Kassie	Harkes	330	1
331	Victoir	Jouannot	331	2
332	Salaidh	Konzel	332	1
333	Townsend	Joslyn	333	1
334	Jayson	McDiarmid	334	1
335	Jedediah	Farnhill	335	1
336	Dirk	Lyall	336	1
337	Row	Maria	337	1
338	Osmond	Duligal	338	1
339	Olvan	Shattock	339	2
340	Caprice	Camelli	340	2
341	Guinevere	Worrill	341	2
342	Raymond	Barras	342	1
343	Omero	Fashion	343	1
344	Tatiana	Stapford	344	1
345	Karine	Goburn	345	1
346	Hobard	Shimon	346	1
347	Carolina	Moar	347	2
348	Jethro	Jaumet	348	1
349	Jarrett	Sudell	349	1
350	Ulla	Cropper	350	1
351	Vite	Archdeacon	351	1
352	Gweneth	Ortzen	352	1
353	Tera	Pledger	353	2
354	Fee	Freckelton	354	2
355	Oona	Lymbourne	355	1
356	Una	Brede	356	1
357	Nicolas	Moggach	357	2
358	Montague	Limpenny	358	1
359	Sid	Haslock	359	1
360	Mirabelle	Mantle	360	1
361	Georgette	Scarse	361	1
362	Maegan	Chipping	362	1
363	Harriot	Maddocks	363	1
364	Payton	Portt	364	1
365	Marvin	Cullip	365	1
366	Dall	Ather	366	1
367	Cad	Meron	367	2
368	Reamonn	Hakonsen	368	1
369	Xymenes	Whitcher	369	1
370	Bree	MacGinney	370	1
371	Tarrance	Huckster	371	1
372	Al	Willman	372	2
373	Trev	Maffei	373	1
374	Alidia	Easman	374	1
375	Edgard	Gothup	375	2
376	Marrissa	Atcock	376	1
377	Dom	Slatten	377	1
378	Jacquie	Angelini	378	1
379	Ertha	Conew	379	2
380	Ingunna	Lafee	380	1
381	Leona	Carpenter	381	2
382	Ariela	Summerly	382	1
383	Juliet	Hallgate	383	1
384	Reggie	Demongeot	384	1
385	Aldon	Baugham	385	1
386	Bethanne	Jirsa	386	1
387	Pattie	Buncher	387	1
388	Bryn	Oxtoby	388	1
389	Loy	Sandbach	389	1
390	Drake	Emmanueli	390	2
391	Lenka	Giblett	391	1
392	Sherry	Crim	392	1
393	Maxwell	Richichi	393	1
394	Berte	Flucks	394	1
395	Emalee	Greenig	395	1
396	Dean	Crankshaw	396	1
397	Nicolea	Reyna	397	1
398	Aubrette	Beilby	398	1
399	Dominick	Janu	399	1
400	Wendie	Syrett	400	1
401	Margarethe	Bignall	401	1
402	Netty	Kilgrove	402	2
403	Bambie	Mulcahy	403	1
404	Selby	Bwye	404	1
405	Jasmin	Haylands	405	1
406	Lorita	Cominoli	406	1
407	Aksel	Gurnett	407	1
408	Row	Ambrogiotti	408	1
409	Maximo	Maffucci	409	1
410	Nannette	Hamm	410	1
411	Malynda	Barneville	411	1
412	Berte	Hyams	412	1
413	Ambrosius	Battany	413	1
414	Vincenz	Elderfield	414	2
415	Linn	Vitall	415	1
416	Kenon	Coatham	416	1
417	Jobina	Viel	417	1
418	Ronni	Stormes	418	1
419	Lanie	Kiebes	419	1
420	Jeanna	Greet	420	2
421	Emlyn	Pinson	421	1
422	Anatol	Bellinger	422	2
423	Flory	Bignall	423	1
424	Alexander	Nairn	424	1
425	Con	Coolahan	425	1
426	Romonda	McFade	426	1
427	Sashenka	Melville	427	1
428	Bradly	Simson	428	1
429	Mia	Burnside	429	2
430	Max	Shuttell	430	1
431	Immanuel	Crosskill	431	1
432	Dinnie	Willey	432	2
433	Keene	Bollini	433	1
434	Hewie	Doubrava	434	1
435	Merline	Sadat	435	1
436	Fayina	Dell 'Orto	436	2
437	Daniele	Mayward	437	1
438	Bernarr	Kornyakov	438	1
439	Melantha	Spackman	439	1
440	Starlene	Keates	440	1
441	Buiron	Durman	441	2
442	Stephan	Marvelley	442	2
443	Lucius	Strowthers	443	1
444	Tina	Rissen	444	2
445	Deidre	Eyre	445	1
446	Oren	Oager	446	1
447	Delia	Bardsley	447	1
448	Dino	Suttle	448	1
449	Colas	Bozier	449	1
450	Aurelia	Gouldthorpe	450	2
451	Kally	McGorley	451	1
452	Rafe	Yeats	452	2
453	Natasha	Lamberton	453	1
454	Corabella	Edland	454	2
455	Tomasina	Rosoni	455	1
456	Antons	Brasher	456	2
457	Nessi	Leeson	457	1
458	Abbe	Gindghill	458	2
459	Maurene	Mears	459	2
460	Pail	Tanfield	460	1
461	Elladine	Ronaldson	461	1
462	Claudell	Ballston	462	1
463	Row	Cunrado	463	1
464	Mariel	McHenry	464	1
465	Bari	Frail	465	2
466	Ahmad	Klug	466	1
467	Row	Austen	467	1
468	Catharina	Feaver	468	1
469	Janessa	Mundford	469	1
470	Clari	Keitley	470	1
471	Hoebart	Sussams	471	1
472	Lily	Terzza	472	1
473	Hannah	Keyzman	473	1
474	Orton	Kempton	474	2
475	Cordi	Brenneke	475	1
476	Chelsey	Phittiplace	476	1
477	Chandler	Balfre	477	1
478	Brennen	Lodwig	478	2
479	Sheree	Gimert	479	1
480	Cacilie	Wason	480	1
481	Krisha	Schermick	481	1
482	Lydon	Huckin	482	2
483	Roxanna	Danzelman	483	1
484	Helge	Jest	484	1
485	Flemming	Boulsher	485	1
486	Piggy	Grange	486	1
487	Carlos	Breedy	487	1
488	Mirabella	Duchant	488	1
489	Monro	McFadden	489	1
490	Emmeline	La Padula	490	2
491	Erinna	Sherringham	491	1
492	Frederich	Rouby	492	1
493	Nelli	Glennon	493	1
494	Astra	Gamblin	494	1
495	Evelyn	Ofer	495	2
496	Geoff	Goode	496	1
497	Silvanus	Sutehall	497	1
498	Dora	Gratten	498	1
499	Connie	Silverthorn	499	1
500	Fleur	Govett	500	1
501	Auberta	Kelsall	501	1
502	Gonzalo	Straffon	502	1
503	Kiersten	Gwilt	503	1
504	Morey	Wrangle	504	1
505	Daron	Kilban	505	1
506	Carolyne	Croizier	506	1
507	Karleen	Anscombe	507	1
508	Kristin	Knowlys	508	1
509	Waylen	Shale	509	1
510	Arthur	Adicot	510	1
511	Clevie	Dartnall	511	1
512	Alwyn	Grandison	512	1
513	Bastian	Mattiuzzi	513	1
514	Katerine	Minette	514	2
515	Ruthi	Di Domenico	515	1
516	Jeremie	Dencs	516	2
517	Berry	Archibald	517	1
518	Gabbie	Kermode	518	1
519	Hillery	Clitherow	519	1
520	Tybi	Veschi	520	1
521	Wallie	Rate	521	1
522	Marcel	Arthurs	522	1
523	Sibley	Schoolcroft	523	1
524	Henrie	Causier	524	1
525	Barby	Filipowicz	525	1
526	Kathlin	Knowlton	526	1
527	Talya	Muirden	527	1
528	Sandro	Scandrett	528	2
529	Kimbell	Porker	529	1
530	Dorelle	Jenkinson	530	2
531	Idette	Wisbey	531	1
532	Scarlet	Peche	532	2
533	Skipper	Yakushkin	533	2
534	Hynda	Moberley	534	2
535	Marion	Harnes	535	2
536	Arabella	Ellyatt	536	1
537	Patrizia	Musico	537	1
538	Charline	Mayworth	538	1
539	Dannye	Astall	539	2
540	Alysa	Turnell	540	1
541	Syman	Heustice	541	1
542	Gustave	Winter	542	1
543	Delcine	OIlier	543	1
544	Kermit	Altamirano	544	1
545	Michelina	Brussels	545	1
546	Lukas	Beardon	546	1
547	Nikolaos	Peotz	547	1
548	Basilius	Stanistrete	548	1
549	Elisa	Larwood	549	1
550	Randolph	Windmill	550	2
551	Janet	Kilvington	551	1
552	Juli	Kristufek	552	1
553	Leopold	Morphey	553	2
554	Ignacius	Preedy	554	2
555	Correna	Smidmor	555	1
556	Damita	Grant	556	1
557	Guy	Friatt	557	1
558	Edi	Doughton	558	1
559	Jakie	Yter	559	2
560	Abey	Ratchford	560	2
561	Maryanna	Sire	561	1
562	Wiley	Domican	562	1
563	Marvin	Perot	563	2
564	Eloise	Polglase	564	1
565	Maribelle	Gathercole	565	1
566	Bernadine	Bottle	566	1
567	Liuka	Samper	567	1
568	Phebe	Noulton	568	1
569	Seline	Vaun	569	1
570	Dickie	Warrior	570	1
571	Bessie	Filyushkin	571	1
572	Rutter	Fiske	572	1
573	Meryl	Cattlow	573	1
574	Cobbie	Dickerline	574	1
575	Dix	Freiberg	575	1
576	Cammie	Juden	576	1
577	Drusy	Greensall	577	1
578	Rachel	Grimwood	578	1
579	Ofelia	Pepper	579	1
580	Archie	Hanford	580	2
581	Monique	Lerohan	581	1
582	Imogen	Nekrews	582	1
583	Ode	Doige	583	1
584	Meggi	McGrotty	584	1
585	Elsinore	Bothen	585	2
586	Daphna	Ballinghall	586	1
587	Gertie	Piatek	587	1
588	Pietra	Mulrenan	588	1
589	Jemimah	Almeida	589	2
590	Wilmar	Drakeley	590	1
591	Darcey	Swetland	591	1
592	Arturo	Minshaw	592	2
593	Hermine	Wealleans	593	1
594	Jaquelin	Lording	594	1
595	Kaylil	Lait	595	1
596	Shell	Pepin	596	1
597	Harmony	Malarkey	597	1
598	Milissent	Townrow	598	1
599	Cal	Baldi	599	1
600	Dalenna	Oakman	600	1
601	Boniface	Vaillant	601	1
602	Nike	Bownass	602	1
603	Farrell	Birtonshaw	603	2
604	Camilla	Pill	604	1
605	Liam	Tink	605	1
606	Ely	Rubertelli	606	2
607	Jethro	Harrismith	607	1
608	Simon	Saipy	608	1
609	Elijah	Trowel	609	1
610	Russ	Clace	610	1
611	Lissa	Rodder	611	1
612	Daisie	Dashkovich	612	2
613	Garfield	Bricksey	613	2
614	Alvie	Port	614	1
615	Tybie	Figgs	615	2
616	Donny	Wackley	616	2
617	Marven	Lampkin	617	1
618	Connie	Zoanetti	618	1
619	Simone	Ducastel	619	1
620	Sullivan	Peppett	620	1
621	Doyle	Demer	621	1
622	Nicolais	Buller	622	1
623	Nerty	Glassopp	623	1
624	Giffy	Merfin	624	1
625	Benedict	Chatten	625	2
626	Shina	Dodds	626	1
627	Lanna	Surmeyers	627	2
628	Fanchette	Aubray	628	1
629	Herbert	Filip	629	1
630	Fiorenze	Mariet	630	1
631	Debbie	Byard	631	1
632	Kara	Haylor	632	1
633	Ryan	Whitrod	633	2
634	Johnathan	Rennolds	634	1
635	Arabella	Seedull	635	1
636	Wiley	Pickerill	636	1
637	Oralee	Peart	637	1
638	Dolley	Marvel	638	2
639	Karna	Yegorchenkov	639	2
640	Shina	Fairham	640	1
641	Giorgia	Humbert	641	1
642	Lynna	Mathwen	642	2
643	Trstram	Kirley	643	1
644	Lem	Adolfson	644	2
645	Bud	Brunn	645	1
646	Netti	Bellhouse	646	2
647	Janine	Cobon	647	1
648	Mikel	Kepp	648	1
649	Charlot	Leasor	649	2
650	Gar	Duke	650	1
651	Bambie	Hankey	651	1
652	Jobyna	Ayrs	652	1
653	Bobby	McRonald	653	1
654	Pall	Dietmar	654	2
655	Gerrilee	Clutram	655	1
656	Ilsa	Athowe	656	1
657	Mahala	Kershaw	657	1
658	Petrina	Massei	658	1
659	Carole	Rollitt	659	1
660	Betsey	Knowling	660	1
661	Maynard	Joselson	661	2
662	Sadella	Dobrovolny	662	1
663	Brook	Sime	663	1
664	Rollins	Creeboe	664	2
665	Harrison	Vasilik	665	1
666	Yelena	Forsythe	666	2
667	Grace	Goatcher	667	1
668	Ariadne	Salasar	668	1
669	Ayn	Phillips	669	1
670	Mikey	Fenelon	670	1
671	Amargo	McCully	671	1
672	Nikki	Dust	672	2
673	Candra	Dobbinson	673	1
674	Austine	Feek	674	2
675	Christiane	Bannard	675	2
676	Lanie	Walshaw	676	1
677	Cyrille	Maass	677	1
678	Niall	MacVicar	678	1
679	Bianka	Tallboy	679	1
680	Tamara	Whitnell	680	1
681	Kaycee	Smeeton	681	2
682	Bentlee	Griggs	682	2
683	Augustine	Tiltman	683	1
684	Schuyler	Robard	684	1
685	Jamey	Manners	685	2
686	Sosanna	Cay	686	1
687	Coletta	Ballinghall	687	1
688	King	Dingsdale	688	1
689	Morly	Howard - Gater	689	1
690	Booth	Blanchard	690	1
691	Tam	Corneck	691	2
692	Lorne	Kerner	692	1
693	Laureen	Skedgell	693	1
694	Yvette	Georgeson	694	1
695	Missy	Peizer	695	2
696	Eveleen	Duigenan	696	1
697	Hedi	O'Kinedy	697	1
698	Felicio	Breinl	698	1
699	Britta	Gilyott	699	1
700	Mahala	Velasquez	700	1
701	Karry	Brosi	701	2
702	Corrie	Appleford	702	1
703	Carole	Fidoe	703	1
704	Kristopher	Cardenas	704	1
705	Beryle	Chiene	705	1
706	Abbey	Wallwood	706	1
707	Sol	Szymanek	707	1
708	Eunice	Camplen	708	1
709	Averell	Sabbatier	709	1
710	Staci	Belleny	710	1
711	Mikael	Kennerley	711	1
712	Shadow	Sheehan	712	2
713	Cathy	Henker	713	1
714	Sallyann	O' Molan	714	1
715	Ernaline	Luscombe	715	2
716	Kristofor	Ashborne	716	1
717	Bell	Grcic	717	1
718	Corri	Baudacci	718	1
719	Edmon	Erley	719	1
720	Cassandre	Ulster	720	1
721	Oby	Petters	721	1
722	Warden	Cabrera	722	1
723	Reggie	Groll	723	1
724	Buckie	Itzcovichch	724	1
725	Genni	Earsman	725	1
726	Valma	Milham	726	1
727	Jocelyne	Reppaport	727	2
728	Brynna	Keeton	728	1
729	Krisha	Duiguid	729	1
730	Artair	Harflete	730	1
731	Tremain	Coppins	731	1
732	Wilbert	Jakoviljevic	732	1
733	Octavia	Elcomb	733	1
734	Gilbertine	Gong	734	1
735	Teddy	Fawlks	735	2
736	Sherwynd	Martello	736	1
737	Fiona	Elsegood	737	1
738	Gale	Baiden	738	1
739	Olav	Dunmuir	739	2
740	Sheryl	Brideaux	740	2
741	Elora	Vreede	741	2
742	Bronson	Upston	742	2
743	Constancia	Backshill	743	2
744	Velma	Thirst	744	2
745	Jojo	Richardet	745	1
746	Micaela	Taft	746	1
747	Debbi	McMurty	747	1
748	Ally	Tabord	748	2
749	Madelin	Blind	749	1
750	Anatole	Everest	750	2
751	Gabriele	Harpham	751	2
752	Walton	Ortzen	752	2
753	Teresina	MacCook	753	1
754	Onfre	Pennock	754	1
755	Hildegaard	Lillyman	755	2
756	Edee	Mattschas	756	1
757	Cammie	Meric	757	1
758	Keenan	Santello	758	2
759	Bartolomeo	Fabler	759	1
760	Ardeen	Ruddiforth	760	1
761	Amerigo	Lockley	761	1
762	Herb	Harriss	762	1
763	Aleda	Ellington	763	2
764	Burtie	Bredes	764	1
765	George	Whenman	765	1
766	Angelique	Cadney	766	1
767	Melisa	Keates	767	2
768	Calli	Causey	768	1
769	Carri	Macauley	769	2
770	Vikki	Washington	770	1
771	Chiquia	Roblou	771	1
772	Berty	Briggdale	772	1
773	Kristin	Brill	773	1
774	Kylie	Rochford	774	1
775	Elenore	Bour	775	1
776	Letisha	Huniwall	776	1
777	Zacharie	Powlesland	777	1
778	Mike	Treadgold	778	1
779	Troy	Bassford	779	1
780	Matilda	Sealey	780	1
781	Romola	Eayrs	781	1
782	Beverley	Striker	782	1
783	Ethel	Happs	783	1
784	Erika	Wannes	784	1
785	Myranda	Gillison	785	1
786	Cleveland	Inglesant	786	2
787	Petrina	McCaghan	787	1
788	Gradeigh	Dalyiel	788	1
789	Pancho	Appleyard	789	1
790	Burlie	Eefting	790	2
791	Marya	Poolton	791	1
792	Darby	Vassie	792	2
793	Haroun	Riolfo	793	1
794	Shelden	Tsar	794	1
795	Mordecai	Tomasek	795	1
796	Nobe	Stowell	796	1
797	Janka	Bendix	797	1
798	Philipa	Klaes	798	1
799	Gael	Stoneley	799	1
800	Niko	Test	800	1
801	Rosco	Mignot	801	1
802	Geoff	Daft	802	1
803	Inge	Lipmann	803	1
804	Allin	Engledow	804	2
805	Abba	Burford	805	1
806	Karon	Notley	806	1
807	Giavani	Lithgow	807	1
808	Giffie	Brookwood	808	2
809	Odille	Linder	809	1
810	Winifred	Blenkinsop	810	1
811	Hugo	Brigstock	811	1
812	Ike	Gee	812	1
813	Jerrie	Le Frank	813	1
814	Stacia	Gilbride	814	1
815	Emalia	Hellwig	815	1
816	Nehemiah	Bault	816	1
817	Chadwick	Aindrais	817	1
818	Antony	Greenway	818	1
819	Maximilian	Bunting	819	2
820	Lemmy	Smalman	820	1
821	Babb	Pauel	821	1
822	Schuyler	Jeanesson	822	1
823	Nessy	Woodyatt	823	1
824	Fionna	Busch	824	1
825	Lay	Blackborow	825	1
826	Adams	Pryer	826	1
827	Joella	Scad	827	1
828	Felic	Pedler	828	1
829	Wain	Breckwell	829	1
830	Melessa	Fassbender	830	1
831	Godwin	Vannozzii	831	1
832	Lanny	Whorall	832	1
833	Samantha	Annets	833	1
834	Nadeen	Deverill	834	2
835	Lemmy	Isabell	835	1
836	Marlane	Kelston	836	1
837	Barnie	Pitrelli	837	1
838	Norris	Zeale	838	1
839	Sharl	Skipsea	839	1
840	Eileen	McCue	840	1
841	Danice	Liddington	841	2
842	Lucine	Airds	842	1
843	Sawyer	Tufts	843	2
844	Sven	Lynagh	844	1
845	Winne	Cleen	845	2
846	Gabriele	Blue	846	2
847	Orella	Rigler	847	1
848	Madlen	Nyssen	848	1
849	Kristine	Goor	849	1
850	Jeniffer	Belison	850	1
851	Eydie	Artinstall	851	1
852	Ambrosi	Cheves	852	1
853	Arley	Spellicy	853	1
854	Margit	Jeandel	854	1
855	Annalee	Seleway	855	1
856	Shawna	Pentercost	856	1
857	Christy	Urwen	857	1
858	Ives	Kempton	858	1
859	Lorettalorna	Knocker	859	1
860	Tabbitha	Neumann	860	1
861	Morley	Yanyushkin	861	1
862	Langsdon	Gawthorp	862	1
863	Baryram	Iacobassi	863	1
864	Elvyn	Hovenden	864	2
865	Zebadiah	Muller	865	1
866	Lothaire	Crick	866	1
867	Kip	Ugoni	867	1
868	Marie-jeanne	Saggs	868	1
869	Tabitha	Woosnam	869	1
870	Reine	Freke	870	1
871	Valentijn	Spiniello	871	1
872	Ange	Reiners	872	1
873	Annmarie	Pifford	873	1
874	Derek	Magee	874	1
875	Wolf	McKeighan	875	2
876	Rufus	Gegay	876	1
877	Kaylil	Jamme	877	1
878	Sandie	Tolliday	878	1
879	Harriette	Danielis	879	1
880	Adrien	Krop	880	1
881	Karoly	Barrick	881	1
882	Dennis	Banasik	882	1
883	Greggory	Giacomuzzi	883	1
884	Letisha	Sonschein	884	1
885	Hurley	Kamienski	885	1
886	Caresse	Lawtie	886	1
887	Ermengarde	Polk	887	1
888	Hyatt	Viel	888	1
889	Judon	Simmers	889	1
890	Whitman	Stephenson	890	1
891	Dre	Pepperrall	891	1
892	Xena	Dadge	892	2
893	Harrie	Donnersberg	893	1
894	Merna	Czajkowski	894	1
895	Jerrine	Woodhead	895	1
896	Avrom	Verrico	896	2
897	Clari	Lytell	897	1
898	Dal	Stanley	898	1
899	Nolie	Sutterfield	899	1
900	Nonna	Gregon	900	1
901	Lorraine	Brand	901	1
902	Verla	Gannicott	902	1
903	Meriel	Dennick	903	1
904	Jammie	Radeliffe	904	1
905	Inna	Poundsford	905	1
906	Immanuel	Lofty	906	1
907	Somerset	Grigson	907	2
908	Aylmar	Linturn	908	1
909	Wash	Horry	909	1
910	Geoffry	Ewen	910	1
911	Brittney	Delue	911	1
912	Fraze	Grumley	912	1
913	Raffarty	Hilhouse	913	1
914	Elisa	Kelsow	914	1
915	Ottilie	Tunniclisse	915	2
916	Darbee	Dudson	916	1
917	Edee	Newband	917	1
918	Gabbi	Leyburn	918	1
919	Willie	Lugg	919	1
920	Nickie	Kunisch	920	1
921	Annabela	Cootes	921	1
922	Alia	Carnihan	922	1
923	Carter	Latour	923	1
924	Jimmy	Flett	924	1
925	Gris	Patullo	925	1
926	Enrico	Huard	926	1
927	Sherlocke	Schindler	927	1
928	Hamlen	De la Yglesia	928	1
929	Cordey	Leete	929	1
930	Marta	Stollhofer	930	1
931	Nobie	Brunotti	931	1
932	Dode	Laight	932	1
933	Arvy	Lipscomb	933	2
934	Anthea	Tytcomb	934	1
935	Lethia	McCafferty	935	1
936	Winni	Kilduff	936	1
937	Arvy	Jenton	937	1
938	Lyn	Ragborne	938	2
939	Farrel	Evered	939	1
940	Horatius	Vida	940	1
941	Kylen	Perford	941	1
942	Even	Salzburg	942	1
943	Nani	Toffoletto	943	2
944	Inge	Arminger	944	1
945	Kermie	Wedgbrow	945	1
946	Zackariah	Foxley	946	1
947	Emilee	Bigland	947	2
948	Bibi	Goroni	948	1
949	Dex	Marmon	949	1
950	Thaddeus	Licciardi	950	2
951	Duffy	Dodsley	951	1
952	Marrissa	Malin	952	1
953	Gale	Houndesome	953	1
954	Thorny	Lemin	954	1
955	Zia	Fedder	955	2
956	Jolynn	Tether	956	1
957	Bern	Destouche	957	2
958	Paxon	Danielski	958	1
959	Alicia	Imlock	959	1
960	Lorettalorna	Warbey	960	2
961	Amalie	Beamand	961	1
962	Kasper	Ormesher	962	1
963	Zorine	Campling	963	1
964	Noami	Hancox	964	1
965	Brade	Braiden	965	1
966	Larissa	Keetley	966	1
967	Osmond	Paoloni	967	2
968	Fidela	Dory	968	1
969	Amandi	Barfford	969	1
970	Othella	Plowes	970	1
971	Tades	Prosek	971	2
972	Kristine	Palister	972	1
973	Charles	Bahike	973	2
974	Quillan	McKane	974	2
975	Myles	Rosenstock	975	2
976	Vania	Salzberg	976	1
977	Annadiane	Tristram	977	1
978	Chaunce	Rousby	978	1
979	Maribeth	Froome	979	1
980	Abraham	Delamere	980	1
981	Brantley	Hedon	981	1
982	Vasili	Hannaford	982	1
983	Sianna	Oglethorpe	983	1
984	Delilah	Cattermole	984	1
985	Genny	Mayston	985	1
986	Ilka	Leisk	986	2
987	Hamil	Tingley	987	1
988	Axe	Tant	988	1
989	Chris	Ingleston	989	2
990	Brynna	Way	990	1
991	Shanda	McShea	991	1
992	Carmon	Andras	992	1
993	Barney	Driscoll	993	1
994	Tito	Yedall	994	2
995	Terri	Avramovitz	995	1
996	Karoline	Amphlett	996	1
997	Netti	Ayers	997	1
998	Joellen	Wakeford	998	2
999	Elsworth	Blackmuir	999	1
1000	Rikki	Keetley	1000	2
\.


--
-- TOC entry 3189 (class 0 OID 16936)
-- Dependencies: 227
-- Data for Name: worker_position; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.worker_position (id, "position") FROM stdin;
1	Провизор
2	Охраник
\.


--
-- TOC entry 3207 (class 0 OID 0)
-- Dependencies: 220
-- Name: contract_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.contract_id_seq', 12, true);


--
-- TOC entry 3208 (class 0 OID 0)
-- Dependencies: 206
-- Name: manufacturer_firm_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.manufacturer_firm_id_seq', 10, true);


--
-- TOC entry 3209 (class 0 OID 0)
-- Dependencies: 215
-- Name: medicine_equipment_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.medicine_equipment_id_seq', 11, true);


--
-- TOC entry 3210 (class 0 OID 0)
-- Dependencies: 202
-- Name: medicine_form_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.medicine_form_id_seq', 7, true);


--
-- TOC entry 3211 (class 0 OID 0)
-- Dependencies: 212
-- Name: medicine_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.medicine_id_seq', 12, true);


--
-- TOC entry 3212 (class 0 OID 0)
-- Dependencies: 210
-- Name: pharmacological_group_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.pharmacological_group_id_seq', 12, true);


--
-- TOC entry 3213 (class 0 OID 0)
-- Dependencies: 200
-- Name: pharmacy_warhouse_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.pharmacy_warhouse_id_seq', 12, true);


--
-- TOC entry 3214 (class 0 OID 0)
-- Dependencies: 204
-- Name: storage_department_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.storage_department_id_seq', 10, true);


--
-- TOC entry 3215 (class 0 OID 0)
-- Dependencies: 208
-- Name: storage_method_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.storage_method_id_seq', 4, true);


--
-- TOC entry 3216 (class 0 OID 0)
-- Dependencies: 222
-- Name: voyage_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.voyage_id_seq', 13, true);


--
-- TOC entry 3217 (class 0 OID 0)
-- Dependencies: 218
-- Name: worker_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.worker_id_seq', 11, true);


--
-- TOC entry 3218 (class 0 OID 0)
-- Dependencies: 226
-- Name: worker_position_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.worker_position_id_seq', 2, true);


--
-- TOC entry 2999 (class 2606 OID 16583)
-- Name: contract contract_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.contract
    ADD CONSTRAINT contract_pkey PRIMARY KEY (id);


--
-- TOC entry 2988 (class 2606 OID 16518)
-- Name: department_stores_medicine department_stores_medicine_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.department_stores_medicine
    ADD CONSTRAINT department_stores_medicine_pkey PRIMARY KEY (id_medicine, id_storage_department);


--
-- TOC entry 2978 (class 2606 OID 16468)
-- Name: manufacturer_firm manufacturer_firm_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.manufacturer_firm
    ADD CONSTRAINT manufacturer_firm_pkey PRIMARY KEY (id);


--
-- TOC entry 2990 (class 2606 OID 16536)
-- Name: medicine_equipment medicine_equipment_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.medicine_equipment
    ADD CONSTRAINT medicine_equipment_pkey PRIMARY KEY (id);


--
-- TOC entry 2973 (class 2606 OID 16442)
-- Name: medicine_form medicine_form_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.medicine_form
    ADD CONSTRAINT medicine_form_pkey PRIMARY KEY (id);


--
-- TOC entry 2985 (class 2606 OID 16492)
-- Name: medicine medicine_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.medicine
    ADD CONSTRAINT medicine_pkey PRIMARY KEY (id);


--
-- TOC entry 2982 (class 2606 OID 16484)
-- Name: pharmacological_group pharmacological_group_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pharmacological_group
    ADD CONSTRAINT pharmacological_group_pkey PRIMARY KEY (id);


--
-- TOC entry 2971 (class 2606 OID 16434)
-- Name: pharmacy_warhouse pharmacy_warhouse_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pharmacy_warhouse
    ADD CONSTRAINT pharmacy_warhouse_pkey PRIMARY KEY (id);


--
-- TOC entry 2980 (class 2606 OID 16476)
-- Name: storage_method storage_method_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.storage_method
    ADD CONSTRAINT storage_method_pkey PRIMARY KEY (id);


--
-- TOC entry 2976 (class 2606 OID 16450)
-- Name: storage_department storage_separtment_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.storage_department
    ADD CONSTRAINT storage_separtment_pkey PRIMARY KEY (id);


--
-- TOC entry 3002 (class 2606 OID 16596)
-- Name: voyage voyage_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.voyage
    ADD CONSTRAINT voyage_pkey PRIMARY KEY (id);


--
-- TOC entry 3005 (class 2606 OID 16653)
-- Name: voyage_transports_m_equipment voyage_transports_m_equipment_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.voyage_transports_m_equipment
    ADD CONSTRAINT voyage_transports_m_equipment_pkey PRIMARY KEY (id_voyage, id_p_warehouse, id_m_equipment);


--
-- TOC entry 3008 (class 2606 OID 16670)
-- Name: voyage_transports_medicine voyage_transports_medicine_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.voyage_transports_medicine
    ADD CONSTRAINT voyage_transports_medicine_pkey PRIMARY KEY (id_voyage, id_medicine, id_storage_department);


--
-- TOC entry 2992 (class 2606 OID 16625)
-- Name: warhouse_stores_m_equipment warhouse_stores_m_equipment_id_pharmacy_warhouse_id_medicin_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.warhouse_stores_m_equipment
    ADD CONSTRAINT warhouse_stores_m_equipment_id_pharmacy_warhouse_id_medicin_key UNIQUE (id_pharmacy_warhouse, id_medicine_equipment);


--
-- TOC entry 2994 (class 2606 OID 16542)
-- Name: warhouse_stores_m_equipment warhouse_stores_m_equipment_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.warhouse_stores_m_equipment
    ADD CONSTRAINT warhouse_stores_m_equipment_pkey PRIMARY KEY (id_pharmacy_warhouse, id_medicine_equipment);


--
-- TOC entry 2996 (class 2606 OID 16560)
-- Name: worker worker_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.worker
    ADD CONSTRAINT worker_pkey PRIMARY KEY (id);


--
-- TOC entry 3010 (class 2606 OID 16941)
-- Name: worker_position worker_position_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.worker_position
    ADD CONSTRAINT worker_position_pkey PRIMARY KEY (id);


--
-- TOC entry 2997 (class 1259 OID 17009)
-- Name: contract_complete; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX contract_complete ON public.contract USING btree (complete);


--
-- TOC entry 2986 (class 1259 OID 17010)
-- Name: dep_stor_med_id_stor_dep; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX dep_stor_med_id_stor_dep ON public.department_stores_medicine USING btree (id_storage_department);


--
-- TOC entry 2983 (class 1259 OID 17015)
-- Name: medicine_name_series; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX medicine_name_series ON public.medicine USING btree (name, series);


--
-- TOC entry 2974 (class 1259 OID 17011)
-- Name: storage_department_name; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX storage_department_name ON public.storage_department USING btree (name);


--
-- TOC entry 3000 (class 1259 OID 17014)
-- Name: voyage_number; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX voyage_number ON public.voyage USING btree (voyage_number);


--
-- TOC entry 3003 (class 1259 OID 17013)
-- Name: voyage_st_dt_t; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX voyage_st_dt_t ON public.voyage USING btree (start_date_time);


--
-- TOC entry 3006 (class 1259 OID 17012)
-- Name: voyage_tran_med_in_out; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX voyage_tran_med_in_out ON public.voyage_transports_medicine USING btree (in_out);


--
-- TOC entry 3023 (class 2606 OID 16584)
-- Name: contract contract_id_worker_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.contract
    ADD CONSTRAINT contract_id_worker_fkey FOREIGN KEY (id_worker) REFERENCES public.worker(id);


--
-- TOC entry 3017 (class 2606 OID 16519)
-- Name: department_stores_medicine department_stores_medicine_id_medicine_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.department_stores_medicine
    ADD CONSTRAINT department_stores_medicine_id_medicine_fkey FOREIGN KEY (id_medicine) REFERENCES public.medicine(id);


--
-- TOC entry 3018 (class 2606 OID 16524)
-- Name: department_stores_medicine department_stores_medicine_id_storage_department_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.department_stores_medicine
    ADD CONSTRAINT department_stores_medicine_id_storage_department_fkey FOREIGN KEY (id_storage_department) REFERENCES public.storage_department(id);


--
-- TOC entry 3014 (class 2606 OID 16498)
-- Name: medicine medicine_id_manufacturer_firm_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.medicine
    ADD CONSTRAINT medicine_id_manufacturer_firm_fkey FOREIGN KEY (id_manufacturer_firm) REFERENCES public.manufacturer_firm(id);


--
-- TOC entry 3013 (class 2606 OID 16493)
-- Name: medicine medicine_id_medicine_form_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.medicine
    ADD CONSTRAINT medicine_id_medicine_form_fkey FOREIGN KEY (id_medicine_form) REFERENCES public.medicine_form(id);


--
-- TOC entry 3016 (class 2606 OID 16508)
-- Name: medicine medicine_id_pharmacological_group_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.medicine
    ADD CONSTRAINT medicine_id_pharmacological_group_fkey FOREIGN KEY (id_pharmacological_group) REFERENCES public.pharmacological_group(id);


--
-- TOC entry 3015 (class 2606 OID 16503)
-- Name: medicine medicine_id_storage_method_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.medicine
    ADD CONSTRAINT medicine_id_storage_method_fkey FOREIGN KEY (id_storage_method) REFERENCES public.storage_method(id);


--
-- TOC entry 3011 (class 2606 OID 16451)
-- Name: storage_department storage_separtment_id_medicine_form_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.storage_department
    ADD CONSTRAINT storage_separtment_id_medicine_form_fkey FOREIGN KEY (id_medicine_form) REFERENCES public.medicine_form(id);


--
-- TOC entry 3012 (class 2606 OID 16456)
-- Name: storage_department storage_separtment_id_pharmacy_warhouse_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.storage_department
    ADD CONSTRAINT storage_separtment_id_pharmacy_warhouse_fkey FOREIGN KEY (id_pharmacy_warhouse) REFERENCES public.pharmacy_warhouse(id);


--
-- TOC entry 3024 (class 2606 OID 16597)
-- Name: voyage voyage_id_contract_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.voyage
    ADD CONSTRAINT voyage_id_contract_fkey FOREIGN KEY (id_contract) REFERENCES public.contract(id);


--
-- TOC entry 3026 (class 2606 OID 16659)
-- Name: voyage_transports_m_equipment voyage_transports_m_equipment_id_p_warehouse_id_m_equipmen_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.voyage_transports_m_equipment
    ADD CONSTRAINT voyage_transports_m_equipment_id_p_warehouse_id_m_equipmen_fkey FOREIGN KEY (id_p_warehouse, id_m_equipment) REFERENCES public.warhouse_stores_m_equipment(id_pharmacy_warhouse, id_medicine_equipment);


--
-- TOC entry 3025 (class 2606 OID 16654)
-- Name: voyage_transports_m_equipment voyage_transports_m_equipment_id_voyage_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.voyage_transports_m_equipment
    ADD CONSTRAINT voyage_transports_m_equipment_id_voyage_fkey FOREIGN KEY (id_voyage) REFERENCES public.voyage(id);


--
-- TOC entry 3028 (class 2606 OID 16676)
-- Name: voyage_transports_medicine voyage_transports_medicine_id_medicine_id_storage_departme_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.voyage_transports_medicine
    ADD CONSTRAINT voyage_transports_medicine_id_medicine_id_storage_departme_fkey FOREIGN KEY (id_medicine, id_storage_department) REFERENCES public.department_stores_medicine(id_medicine, id_storage_department);


--
-- TOC entry 3027 (class 2606 OID 16671)
-- Name: voyage_transports_medicine voyage_transports_medicine_id_voyage_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.voyage_transports_medicine
    ADD CONSTRAINT voyage_transports_medicine_id_voyage_fkey FOREIGN KEY (id_voyage) REFERENCES public.voyage(id);


--
-- TOC entry 3020 (class 2606 OID 16548)
-- Name: warhouse_stores_m_equipment warhouse_stores_m_equipment_id_medicine_equipment_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.warhouse_stores_m_equipment
    ADD CONSTRAINT warhouse_stores_m_equipment_id_medicine_equipment_fkey FOREIGN KEY (id_medicine_equipment) REFERENCES public.medicine_equipment(id);


--
-- TOC entry 3019 (class 2606 OID 16543)
-- Name: warhouse_stores_m_equipment warhouse_stores_m_equipment_id_pharmacy_warhouse_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.warhouse_stores_m_equipment
    ADD CONSTRAINT warhouse_stores_m_equipment_id_pharmacy_warhouse_fkey FOREIGN KEY (id_pharmacy_warhouse) REFERENCES public.pharmacy_warhouse(id);


--
-- TOC entry 3022 (class 2606 OID 16993)
-- Name: worker worker_id_position_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.worker
    ADD CONSTRAINT worker_id_position_fkey FOREIGN KEY (id_position) REFERENCES public.worker_position(id);


--
-- TOC entry 3021 (class 2606 OID 16570)
-- Name: worker worker_id_warhouse_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.worker
    ADD CONSTRAINT worker_id_warhouse_fkey FOREIGN KEY (id_warhouse) REFERENCES public.pharmacy_warhouse(id);


-- Completed on 2021-05-27 21:55:19

--
-- PostgreSQL database dump complete
--

