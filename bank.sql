PGDMP     !    '    	            y            bank    13.2    13.2 m    =           0    0    ENCODING    ENCODING        SET client_encoding = 'UTF8';
                      false            >           0    0 
   STDSTRINGS 
   STDSTRINGS     (   SET standard_conforming_strings = 'on';
                      false            ?           0    0 
   SEARCHPATH 
   SEARCHPATH     8   SELECT pg_catalog.set_config('search_path', '', false);
                      false            @           1262    16681    bank    DATABASE     a   CREATE DATABASE bank WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE = 'Russian_Russia.1251';
    DROP DATABASE bank;
                postgres    false            �            1259    16751    bank_department    TABLE     �   CREATE TABLE public.bank_department (
    id integer NOT NULL,
    address character varying(80) NOT NULL,
    hours_work character varying(11) NOT NULL
);
 #   DROP TABLE public.bank_department;
       public         heap    postgres    false            �            1259    16749    bank_department_id_seq    SEQUENCE     �   CREATE SEQUENCE public.bank_department_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 -   DROP SEQUENCE public.bank_department_id_seq;
       public          postgres    false    209            A           0    0    bank_department_id_seq    SEQUENCE OWNED BY     Q   ALTER SEQUENCE public.bank_department_id_seq OWNED BY public.bank_department.id;
          public          postgres    false    208            �            1259    16763    card    TABLE     #  CREATE TABLE public.card (
    id integer NOT NULL,
    account_number character varying(16) NOT NULL,
    ammount real NOT NULL,
    root_number character varying(8) NOT NULL,
    bic character varying(8) NOT NULL,
    id_client integer NOT NULL,
    id_bank_department integer NOT NULL
);
    DROP TABLE public.card;
       public         heap    postgres    false            �            1259    16761    card_id_seq    SEQUENCE     �   CREATE SEQUENCE public.card_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 "   DROP SEQUENCE public.card_id_seq;
       public          postgres    false    211            B           0    0    card_id_seq    SEQUENCE OWNED BY     ;   ALTER SEQUENCE public.card_id_seq OWNED BY public.card.id;
          public          postgres    false    210            �            1259    16807    card_transaction    TABLE     �   CREATE TABLE public.card_transaction (
    id integer NOT NULL,
    id_card integer NOT NULL,
    id_transaction integer NOT NULL
);
 $   DROP TABLE public.card_transaction;
       public         heap    postgres    false            �            1259    16805    card_transaction_id_seq    SEQUENCE     �   CREATE SEQUENCE public.card_transaction_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 .   DROP SEQUENCE public.card_transaction_id_seq;
       public          postgres    false    217            C           0    0    card_transaction_id_seq    SEQUENCE OWNED BY     S   ALTER SEQUENCE public.card_transaction_id_seq OWNED BY public.card_transaction.id;
          public          postgres    false    216            �            1259    16684    client    TABLE     �   CREATE TABLE public.client (
    id integer NOT NULL,
    fio character varying(60) NOT NULL,
    address_home character varying(50) NOT NULL,
    address_work character varying(80) NOT NULL,
    birth date NOT NULL
);
    DROP TABLE public.client;
       public         heap    postgres    false            �            1259    16682    client_id_seq    SEQUENCE     �   CREATE SEQUENCE public.client_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 $   DROP SEQUENCE public.client_id_seq;
       public          postgres    false    201            D           0    0    client_id_seq    SEQUENCE OWNED BY     ?   ALTER SEQUENCE public.client_id_seq OWNED BY public.client.id;
          public          postgres    false    200            �            1259    16692    contribution    TABLE       CREATE TABLE public.contribution (
    id integer NOT NULL,
    type character varying(70) NOT NULL,
    end_date date NOT NULL,
    create_date date NOT NULL,
    amount real NOT NULL,
    percent real NOT NULL,
    income real NOT NULL,
    id_client integer NOT NULL
);
     DROP TABLE public.contribution;
       public         heap    postgres    false            �            1259    16690    contribution_id_seq    SEQUENCE     �   CREATE SEQUENCE public.contribution_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 *   DROP SEQUENCE public.contribution_id_seq;
       public          postgres    false    203            E           0    0    contribution_id_seq    SEQUENCE OWNED BY     K   ALTER SEQUENCE public.contribution_id_seq OWNED BY public.contribution.id;
          public          postgres    false    202            �            1259    16721    credit    TABLE       CREATE TABLE public.credit (
    id integer NOT NULL,
    number_credit_card character varying(19) NOT NULL,
    ammount real NOT NULL,
    percent real NOT NULL,
    remainder real NOT NULL,
    indebtedness real NOT NULL,
    id_client integer NOT NULL
);
    DROP TABLE public.credit;
       public         heap    postgres    false            �            1259    16719    credit_id_seq    SEQUENCE     �   CREATE SEQUENCE public.credit_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 $   DROP SEQUENCE public.credit_id_seq;
       public          postgres    false    205            F           0    0    credit_id_seq    SEQUENCE OWNED BY     ?   ALTER SEQUENCE public.credit_id_seq OWNED BY public.credit.id;
          public          postgres    false    204            �            1259    16825    credit_transaction    TABLE     �   CREATE TABLE public.credit_transaction (
    id integer NOT NULL,
    id_credit integer NOT NULL,
    id_transaction integer NOT NULL
);
 &   DROP TABLE public.credit_transaction;
       public         heap    postgres    false            �            1259    16823    credit_transaction_id_seq    SEQUENCE     �   CREATE SEQUENCE public.credit_transaction_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 0   DROP SEQUENCE public.credit_transaction_id_seq;
       public          postgres    false    219            G           0    0    credit_transaction_id_seq    SEQUENCE OWNED BY     W   ALTER SEQUENCE public.credit_transaction_id_seq OWNED BY public.credit_transaction.id;
          public          postgres    false    218            �            1259    16734 	   insurance    TABLE     �   CREATE TABLE public.insurance (
    id integer NOT NULL,
    type character varying(80) NOT NULL,
    create_date timestamp without time zone NOT NULL,
    id_client integer NOT NULL
);
    DROP TABLE public.insurance;
       public         heap    postgres    false            �            1259    16732    insurance_id_seq    SEQUENCE     �   CREATE SEQUENCE public.insurance_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 '   DROP SEQUENCE public.insurance_id_seq;
       public          postgres    false    207            H           0    0    insurance_id_seq    SEQUENCE OWNED BY     E   ALTER SEQUENCE public.insurance_id_seq OWNED BY public.insurance.id;
          public          postgres    false    206            �            1259    16856 	   mini_cafe    TABLE     �   CREATE TABLE public.mini_cafe (
    id integer NOT NULL,
    tables_number smallint NOT NULL,
    chairs_number smallint NOT NULL,
    id_bank_department integer NOT NULL
);
    DROP TABLE public.mini_cafe;
       public         heap    postgres    false            �            1259    16854    mini_cafe_id_seq    SEQUENCE     �   CREATE SEQUENCE public.mini_cafe_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 '   DROP SEQUENCE public.mini_cafe_id_seq;
       public          postgres    false    223            I           0    0    mini_cafe_id_seq    SEQUENCE OWNED BY     E   ALTER SEQUENCE public.mini_cafe_id_seq OWNED BY public.mini_cafe.id;
          public          postgres    false    222            �            1259    16869    order_mini_cafe    TABLE     �   CREATE TABLE public.order_mini_cafe (
    id integer NOT NULL,
    type character varying(50) NOT NULL,
    date_time timestamp without time zone NOT NULL,
    ammount real NOT NULL,
    id_mini_cafe integer NOT NULL,
    id_client integer NOT NULL
);
 #   DROP TABLE public.order_mini_cafe;
       public         heap    postgres    false            �            1259    16867    order_mini_cafe_id_seq    SEQUENCE     �   CREATE SEQUENCE public.order_mini_cafe_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 -   DROP SEQUENCE public.order_mini_cafe_id_seq;
       public          postgres    false    225            J           0    0    order_mini_cafe_id_seq    SEQUENCE OWNED BY     Q   ALTER SEQUENCE public.order_mini_cafe_id_seq OWNED BY public.order_mini_cafe.id;
          public          postgres    false    224            �            1259    16843    receipt    TABLE     t  CREATE TABLE public.receipt (
    id integer NOT NULL,
    client_type character varying(40) NOT NULL,
    create_date_time timestamp without time zone NOT NULL,
    payment_date_time timestamp without time zone NOT NULL,
    ammount real NOT NULL,
    number character varying(6) NOT NULL,
    receipt_link character varying(50) NOT NULL,
    id_card integer NOT NULL
);
    DROP TABLE public.receipt;
       public         heap    postgres    false            �            1259    16841    receipt_id_seq    SEQUENCE     �   CREATE SEQUENCE public.receipt_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 %   DROP SEQUENCE public.receipt_id_seq;
       public          postgres    false    221            K           0    0    receipt_id_seq    SEQUENCE OWNED BY     A   ALTER SEQUENCE public.receipt_id_seq OWNED BY public.receipt.id;
          public          postgres    false    220            �            1259    16789    transaction    TABLE     �   CREATE TABLE public.transaction (
    id integer NOT NULL,
    ammount real NOT NULL,
    date_time timestamp without time zone NOT NULL,
    id_type_transaction integer NOT NULL
);
    DROP TABLE public.transaction;
       public         heap    postgres    false            �            1259    16787    transaction_id_seq    SEQUENCE     �   CREATE SEQUENCE public.transaction_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 )   DROP SEQUENCE public.transaction_id_seq;
       public          postgres    false    215            L           0    0    transaction_id_seq    SEQUENCE OWNED BY     I   ALTER SEQUENCE public.transaction_id_seq OWNED BY public.transaction.id;
          public          postgres    false    214            �            1259    16781    transaction_type    TABLE     k   CREATE TABLE public.transaction_type (
    id integer NOT NULL,
    name character varying(40) NOT NULL
);
 $   DROP TABLE public.transaction_type;
       public         heap    postgres    false            �            1259    16779    transaction_type_id_seq    SEQUENCE     �   CREATE SEQUENCE public.transaction_type_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 .   DROP SEQUENCE public.transaction_type_id_seq;
       public          postgres    false    213            M           0    0    transaction_type_id_seq    SEQUENCE OWNED BY     S   ALTER SEQUENCE public.transaction_type_id_seq OWNED BY public.transaction_type.id;
          public          postgres    false    212            n           2604    16754    bank_department id    DEFAULT     x   ALTER TABLE ONLY public.bank_department ALTER COLUMN id SET DEFAULT nextval('public.bank_department_id_seq'::regclass);
 A   ALTER TABLE public.bank_department ALTER COLUMN id DROP DEFAULT;
       public          postgres    false    208    209    209            o           2604    16766    card id    DEFAULT     b   ALTER TABLE ONLY public.card ALTER COLUMN id SET DEFAULT nextval('public.card_id_seq'::regclass);
 6   ALTER TABLE public.card ALTER COLUMN id DROP DEFAULT;
       public          postgres    false    211    210    211            r           2604    16810    card_transaction id    DEFAULT     z   ALTER TABLE ONLY public.card_transaction ALTER COLUMN id SET DEFAULT nextval('public.card_transaction_id_seq'::regclass);
 B   ALTER TABLE public.card_transaction ALTER COLUMN id DROP DEFAULT;
       public          postgres    false    216    217    217            j           2604    16687 	   client id    DEFAULT     f   ALTER TABLE ONLY public.client ALTER COLUMN id SET DEFAULT nextval('public.client_id_seq'::regclass);
 8   ALTER TABLE public.client ALTER COLUMN id DROP DEFAULT;
       public          postgres    false    201    200    201            k           2604    16695    contribution id    DEFAULT     r   ALTER TABLE ONLY public.contribution ALTER COLUMN id SET DEFAULT nextval('public.contribution_id_seq'::regclass);
 >   ALTER TABLE public.contribution ALTER COLUMN id DROP DEFAULT;
       public          postgres    false    203    202    203            l           2604    16724 	   credit id    DEFAULT     f   ALTER TABLE ONLY public.credit ALTER COLUMN id SET DEFAULT nextval('public.credit_id_seq'::regclass);
 8   ALTER TABLE public.credit ALTER COLUMN id DROP DEFAULT;
       public          postgres    false    204    205    205            s           2604    16828    credit_transaction id    DEFAULT     ~   ALTER TABLE ONLY public.credit_transaction ALTER COLUMN id SET DEFAULT nextval('public.credit_transaction_id_seq'::regclass);
 D   ALTER TABLE public.credit_transaction ALTER COLUMN id DROP DEFAULT;
       public          postgres    false    218    219    219            m           2604    16737    insurance id    DEFAULT     l   ALTER TABLE ONLY public.insurance ALTER COLUMN id SET DEFAULT nextval('public.insurance_id_seq'::regclass);
 ;   ALTER TABLE public.insurance ALTER COLUMN id DROP DEFAULT;
       public          postgres    false    207    206    207            u           2604    16859    mini_cafe id    DEFAULT     l   ALTER TABLE ONLY public.mini_cafe ALTER COLUMN id SET DEFAULT nextval('public.mini_cafe_id_seq'::regclass);
 ;   ALTER TABLE public.mini_cafe ALTER COLUMN id DROP DEFAULT;
       public          postgres    false    223    222    223            v           2604    16872    order_mini_cafe id    DEFAULT     x   ALTER TABLE ONLY public.order_mini_cafe ALTER COLUMN id SET DEFAULT nextval('public.order_mini_cafe_id_seq'::regclass);
 A   ALTER TABLE public.order_mini_cafe ALTER COLUMN id DROP DEFAULT;
       public          postgres    false    224    225    225            t           2604    16846 
   receipt id    DEFAULT     h   ALTER TABLE ONLY public.receipt ALTER COLUMN id SET DEFAULT nextval('public.receipt_id_seq'::regclass);
 9   ALTER TABLE public.receipt ALTER COLUMN id DROP DEFAULT;
       public          postgres    false    220    221    221            q           2604    16792    transaction id    DEFAULT     p   ALTER TABLE ONLY public.transaction ALTER COLUMN id SET DEFAULT nextval('public.transaction_id_seq'::regclass);
 =   ALTER TABLE public.transaction ALTER COLUMN id DROP DEFAULT;
       public          postgres    false    215    214    215            p           2604    16784    transaction_type id    DEFAULT     z   ALTER TABLE ONLY public.transaction_type ALTER COLUMN id SET DEFAULT nextval('public.transaction_type_id_seq'::regclass);
 B   ALTER TABLE public.transaction_type ALTER COLUMN id DROP DEFAULT;
       public          postgres    false    212    213    213            *          0    16751    bank_department 
   TABLE DATA           B   COPY public.bank_department (id, address, hours_work) FROM stdin;
    public          postgres    false    209   ��       ,          0    16763    card 
   TABLE DATA           l   COPY public.card (id, account_number, ammount, root_number, bic, id_client, id_bank_department) FROM stdin;
    public          postgres    false    211   �       2          0    16807    card_transaction 
   TABLE DATA           G   COPY public.card_transaction (id, id_card, id_transaction) FROM stdin;
    public          postgres    false    217   ]�       "          0    16684    client 
   TABLE DATA           L   COPY public.client (id, fio, address_home, address_work, birth) FROM stdin;
    public          postgres    false    201   ��       $          0    16692    contribution 
   TABLE DATA           k   COPY public.contribution (id, type, end_date, create_date, amount, percent, income, id_client) FROM stdin;
    public          postgres    false    203   �       &          0    16721    credit 
   TABLE DATA           n   COPY public.credit (id, number_credit_card, ammount, percent, remainder, indebtedness, id_client) FROM stdin;
    public          postgres    false    205   ��       4          0    16825    credit_transaction 
   TABLE DATA           K   COPY public.credit_transaction (id, id_credit, id_transaction) FROM stdin;
    public          postgres    false    219   ƃ       (          0    16734 	   insurance 
   TABLE DATA           E   COPY public.insurance (id, type, create_date, id_client) FROM stdin;
    public          postgres    false    207   �       8          0    16856 	   mini_cafe 
   TABLE DATA           Y   COPY public.mini_cafe (id, tables_number, chairs_number, id_bank_department) FROM stdin;
    public          postgres    false    223   9�       :          0    16869    order_mini_cafe 
   TABLE DATA           `   COPY public.order_mini_cafe (id, type, date_time, ammount, id_mini_cafe, id_client) FROM stdin;
    public          postgres    false    225   ^�       6          0    16843    receipt 
   TABLE DATA              COPY public.receipt (id, client_type, create_date_time, payment_date_time, ammount, number, receipt_link, id_card) FROM stdin;
    public          postgres    false    221   ��       0          0    16789    transaction 
   TABLE DATA           R   COPY public.transaction (id, ammount, date_time, id_type_transaction) FROM stdin;
    public          postgres    false    215   #�       .          0    16781    transaction_type 
   TABLE DATA           4   COPY public.transaction_type (id, name) FROM stdin;
    public          postgres    false    213   Z�       N           0    0    bank_department_id_seq    SEQUENCE SET     D   SELECT pg_catalog.setval('public.bank_department_id_seq', 1, true);
          public          postgres    false    208            O           0    0    card_id_seq    SEQUENCE SET     9   SELECT pg_catalog.setval('public.card_id_seq', 1, true);
          public          postgres    false    210            P           0    0    card_transaction_id_seq    SEQUENCE SET     E   SELECT pg_catalog.setval('public.card_transaction_id_seq', 1, true);
          public          postgres    false    216            Q           0    0    client_id_seq    SEQUENCE SET     ;   SELECT pg_catalog.setval('public.client_id_seq', 1, true);
          public          postgres    false    200            R           0    0    contribution_id_seq    SEQUENCE SET     A   SELECT pg_catalog.setval('public.contribution_id_seq', 1, true);
          public          postgres    false    202            S           0    0    credit_id_seq    SEQUENCE SET     ;   SELECT pg_catalog.setval('public.credit_id_seq', 1, true);
          public          postgres    false    204            T           0    0    credit_transaction_id_seq    SEQUENCE SET     G   SELECT pg_catalog.setval('public.credit_transaction_id_seq', 1, true);
          public          postgres    false    218            U           0    0    insurance_id_seq    SEQUENCE SET     >   SELECT pg_catalog.setval('public.insurance_id_seq', 1, true);
          public          postgres    false    206            V           0    0    mini_cafe_id_seq    SEQUENCE SET     >   SELECT pg_catalog.setval('public.mini_cafe_id_seq', 1, true);
          public          postgres    false    222            W           0    0    order_mini_cafe_id_seq    SEQUENCE SET     D   SELECT pg_catalog.setval('public.order_mini_cafe_id_seq', 1, true);
          public          postgres    false    224            X           0    0    receipt_id_seq    SEQUENCE SET     <   SELECT pg_catalog.setval('public.receipt_id_seq', 1, true);
          public          postgres    false    220            Y           0    0    transaction_id_seq    SEQUENCE SET     @   SELECT pg_catalog.setval('public.transaction_id_seq', 1, true);
          public          postgres    false    214            Z           0    0    transaction_type_id_seq    SEQUENCE SET     E   SELECT pg_catalog.setval('public.transaction_type_id_seq', 1, true);
          public          postgres    false    212            �           2606    16756 $   bank_department bank_department_pkey 
   CONSTRAINT     b   ALTER TABLE ONLY public.bank_department
    ADD CONSTRAINT bank_department_pkey PRIMARY KEY (id);
 N   ALTER TABLE ONLY public.bank_department DROP CONSTRAINT bank_department_pkey;
       public            postgres    false    209            �           2606    16768    card card_pkey 
   CONSTRAINT     L   ALTER TABLE ONLY public.card
    ADD CONSTRAINT card_pkey PRIMARY KEY (id);
 8   ALTER TABLE ONLY public.card DROP CONSTRAINT card_pkey;
       public            postgres    false    211            �           2606    16812 &   card_transaction card_transaction_pkey 
   CONSTRAINT     d   ALTER TABLE ONLY public.card_transaction
    ADD CONSTRAINT card_transaction_pkey PRIMARY KEY (id);
 P   ALTER TABLE ONLY public.card_transaction DROP CONSTRAINT card_transaction_pkey;
       public            postgres    false    217            x           2606    16689    client client_pkey 
   CONSTRAINT     P   ALTER TABLE ONLY public.client
    ADD CONSTRAINT client_pkey PRIMARY KEY (id);
 <   ALTER TABLE ONLY public.client DROP CONSTRAINT client_pkey;
       public            postgres    false    201            z           2606    16697    contribution contribution_pkey 
   CONSTRAINT     \   ALTER TABLE ONLY public.contribution
    ADD CONSTRAINT contribution_pkey PRIMARY KEY (id);
 H   ALTER TABLE ONLY public.contribution DROP CONSTRAINT contribution_pkey;
       public            postgres    false    203            |           2606    16726    credit credit_pkey 
   CONSTRAINT     P   ALTER TABLE ONLY public.credit
    ADD CONSTRAINT credit_pkey PRIMARY KEY (id);
 <   ALTER TABLE ONLY public.credit DROP CONSTRAINT credit_pkey;
       public            postgres    false    205            �           2606    16830 *   credit_transaction credit_transaction_pkey 
   CONSTRAINT     h   ALTER TABLE ONLY public.credit_transaction
    ADD CONSTRAINT credit_transaction_pkey PRIMARY KEY (id);
 T   ALTER TABLE ONLY public.credit_transaction DROP CONSTRAINT credit_transaction_pkey;
       public            postgres    false    219            ~           2606    16739    insurance insurance_pkey 
   CONSTRAINT     V   ALTER TABLE ONLY public.insurance
    ADD CONSTRAINT insurance_pkey PRIMARY KEY (id);
 B   ALTER TABLE ONLY public.insurance DROP CONSTRAINT insurance_pkey;
       public            postgres    false    207            �           2606    16861    mini_cafe mini_cafe_pkey 
   CONSTRAINT     V   ALTER TABLE ONLY public.mini_cafe
    ADD CONSTRAINT mini_cafe_pkey PRIMARY KEY (id);
 B   ALTER TABLE ONLY public.mini_cafe DROP CONSTRAINT mini_cafe_pkey;
       public            postgres    false    223            �           2606    16874 $   order_mini_cafe order_mini_cafe_pkey 
   CONSTRAINT     b   ALTER TABLE ONLY public.order_mini_cafe
    ADD CONSTRAINT order_mini_cafe_pkey PRIMARY KEY (id);
 N   ALTER TABLE ONLY public.order_mini_cafe DROP CONSTRAINT order_mini_cafe_pkey;
       public            postgres    false    225            �           2606    16848    receipt receipt_pkey 
   CONSTRAINT     R   ALTER TABLE ONLY public.receipt
    ADD CONSTRAINT receipt_pkey PRIMARY KEY (id);
 >   ALTER TABLE ONLY public.receipt DROP CONSTRAINT receipt_pkey;
       public            postgres    false    221            �           2606    16794    transaction transaction_pkey 
   CONSTRAINT     Z   ALTER TABLE ONLY public.transaction
    ADD CONSTRAINT transaction_pkey PRIMARY KEY (id);
 F   ALTER TABLE ONLY public.transaction DROP CONSTRAINT transaction_pkey;
       public            postgres    false    215            �           2606    16786 &   transaction_type transaction_type_pkey 
   CONSTRAINT     d   ALTER TABLE ONLY public.transaction_type
    ADD CONSTRAINT transaction_type_pkey PRIMARY KEY (id);
 P   ALTER TABLE ONLY public.transaction_type DROP CONSTRAINT transaction_type_pkey;
       public            postgres    false    213            �           2606    16774 !   card card_id_bank_department_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.card
    ADD CONSTRAINT card_id_bank_department_fkey FOREIGN KEY (id_bank_department) REFERENCES public.bank_department(id);
 K   ALTER TABLE ONLY public.card DROP CONSTRAINT card_id_bank_department_fkey;
       public          postgres    false    2944    209    211            �           2606    16769    card card_id_client_fkey    FK CONSTRAINT     z   ALTER TABLE ONLY public.card
    ADD CONSTRAINT card_id_client_fkey FOREIGN KEY (id_client) REFERENCES public.client(id);
 B   ALTER TABLE ONLY public.card DROP CONSTRAINT card_id_client_fkey;
       public          postgres    false    201    2936    211            �           2606    16813 .   card_transaction card_transaction_id_card_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.card_transaction
    ADD CONSTRAINT card_transaction_id_card_fkey FOREIGN KEY (id_card) REFERENCES public.card(id);
 X   ALTER TABLE ONLY public.card_transaction DROP CONSTRAINT card_transaction_id_card_fkey;
       public          postgres    false    2946    217    211            �           2606    16818 5   card_transaction card_transaction_id_transaction_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.card_transaction
    ADD CONSTRAINT card_transaction_id_transaction_fkey FOREIGN KEY (id_transaction) REFERENCES public.transaction(id);
 _   ALTER TABLE ONLY public.card_transaction DROP CONSTRAINT card_transaction_id_transaction_fkey;
       public          postgres    false    215    217    2950            �           2606    16698 (   contribution contribution_id_client_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.contribution
    ADD CONSTRAINT contribution_id_client_fkey FOREIGN KEY (id_client) REFERENCES public.client(id);
 R   ALTER TABLE ONLY public.contribution DROP CONSTRAINT contribution_id_client_fkey;
       public          postgres    false    2936    203    201            �           2606    16727    credit credit_id_client_fkey    FK CONSTRAINT     ~   ALTER TABLE ONLY public.credit
    ADD CONSTRAINT credit_id_client_fkey FOREIGN KEY (id_client) REFERENCES public.client(id);
 F   ALTER TABLE ONLY public.credit DROP CONSTRAINT credit_id_client_fkey;
       public          postgres    false    201    205    2936            �           2606    16836 4   credit_transaction credit_transaction_id_credit_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.credit_transaction
    ADD CONSTRAINT credit_transaction_id_credit_fkey FOREIGN KEY (id_credit) REFERENCES public.credit(id);
 ^   ALTER TABLE ONLY public.credit_transaction DROP CONSTRAINT credit_transaction_id_credit_fkey;
       public          postgres    false    205    219    2940            �           2606    16831 9   credit_transaction credit_transaction_id_transaction_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.credit_transaction
    ADD CONSTRAINT credit_transaction_id_transaction_fkey FOREIGN KEY (id_transaction) REFERENCES public.transaction(id);
 c   ALTER TABLE ONLY public.credit_transaction DROP CONSTRAINT credit_transaction_id_transaction_fkey;
       public          postgres    false    2950    215    219            �           2606    16740 "   insurance insurance_id_client_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.insurance
    ADD CONSTRAINT insurance_id_client_fkey FOREIGN KEY (id_client) REFERENCES public.client(id);
 L   ALTER TABLE ONLY public.insurance DROP CONSTRAINT insurance_id_client_fkey;
       public          postgres    false    201    2936    207            �           2606    16862 +   mini_cafe mini_cafe_id_bank_department_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.mini_cafe
    ADD CONSTRAINT mini_cafe_id_bank_department_fkey FOREIGN KEY (id_bank_department) REFERENCES public.bank_department(id);
 U   ALTER TABLE ONLY public.mini_cafe DROP CONSTRAINT mini_cafe_id_bank_department_fkey;
       public          postgres    false    223    209    2944            �           2606    16880 .   order_mini_cafe order_mini_cafe_id_client_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.order_mini_cafe
    ADD CONSTRAINT order_mini_cafe_id_client_fkey FOREIGN KEY (id_client) REFERENCES public.client(id);
 X   ALTER TABLE ONLY public.order_mini_cafe DROP CONSTRAINT order_mini_cafe_id_client_fkey;
       public          postgres    false    2936    225    201            �           2606    16875 1   order_mini_cafe order_mini_cafe_id_mini_cafe_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.order_mini_cafe
    ADD CONSTRAINT order_mini_cafe_id_mini_cafe_fkey FOREIGN KEY (id_mini_cafe) REFERENCES public.mini_cafe(id);
 [   ALTER TABLE ONLY public.order_mini_cafe DROP CONSTRAINT order_mini_cafe_id_mini_cafe_fkey;
       public          postgres    false    2958    225    223            �           2606    16849    receipt receipt_id_card_fkey    FK CONSTRAINT     z   ALTER TABLE ONLY public.receipt
    ADD CONSTRAINT receipt_id_card_fkey FOREIGN KEY (id_card) REFERENCES public.card(id);
 F   ALTER TABLE ONLY public.receipt DROP CONSTRAINT receipt_id_card_fkey;
       public          postgres    false    221    211    2946            �           2606    16795 0   transaction transaction_id_type_transaction_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.transaction
    ADD CONSTRAINT transaction_id_type_transaction_fkey FOREIGN KEY (id_type_transaction) REFERENCES public.transaction_type(id);
 Z   ALTER TABLE ONLY public.transaction DROP CONSTRAINT transaction_id_type_transaction_fkey;
       public          postgres    false    213    215    2948            *   R   x�3估YO�¤�.쾰Hn��paÅ-:
�/��L��pq�=�^�{aׅ}:
��)qXX�I�=... >M$#      ,   1   x�3�4426153��4404442�4250 ���1'�'r��qqq ��      2      x�3�4�4����� �X      "   �   x����0C��)2@[!Q�� � �H�$���6���܍��˖�cox�F��LD��F �˖��q!ɉ�?���A�W�+�f���X8ٓ�&+?�\8��y�H��pU�u�׬��4�ƯWu�X�����Z�{�[      $   a   x�-�A
� �ᵞ�(>-�L�	mj�IZTb^aލRh���!�2$����Qpqĉ�
��*�xyig�(�u^[�)t�Oo��`F�B��H)?3�.�      &   .   x�3�4426Q053�P�440T0442�45 NS(m�i����� �.      4      x�3�4�4����� �X      (   @   x�3估�b�ņ.�^�waӅ]6( �}�.l�4202�50�56P04�20 "NC�=... t��      8      x�3�4�4�4����� ��      :   G   x�3�0�¾�.6_�aׅ
���M6\l�������P��H��P��������(f�i�i����� ��      6   ^   x�3估��/��~a����.컰U��n�@ۅ}�FF��F�F
��V��V�F(bfVF&V�朆f��F�fƆ�9�yٜ�\1z\\\ /�!N      0   '   x�3�4450�4202�50"CS+S+��!W� f!�      .      x�3�0��֋�^�ta߅-\1z\\\ �xK     