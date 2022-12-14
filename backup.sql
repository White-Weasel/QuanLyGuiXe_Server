PGDMP                         z            QuanLyGuiXe    14.2    14.4                 0    0    ENCODING    ENCODING        SET client_encoding = 'UTF8';
                      false                       0    0 
   STDSTRINGS 
   STDSTRINGS     (   SET standard_conforming_strings = 'on';
                      false                       0    0 
   SEARCHPATH 
   SEARCHPATH     8   SELECT pg_catalog.set_config('search_path', '', false);
                      false                       1262    36240    QuanLyGuiXe    DATABASE     q   CREATE DATABASE "QuanLyGuiXe" WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE = 'English_United States.1252';
    DROP DATABASE "QuanLyGuiXe";
                postgres    false            ?            1255    36431 -   check_no_active_ticket(text, bigint, boolean)    FUNCTION     ?  CREATE FUNCTION public.check_no_active_ticket(input_plate text, input_ticket bigint, input_inside boolean) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE
	f_result bool;
BEGIN
	if input_inside then
		select exists(select parking_id from parking 
			where ticket=input_ticket
			and plate=input_plate
			and inside=true )
			into f_result;
		return not f_result;
	ELSE
		return True;
	end if;
END;
$$;
 j   DROP FUNCTION public.check_no_active_ticket(input_plate text, input_ticket bigint, input_inside boolean);
       public          postgres    false            ?            1255    36424 E   correctly_formated_parking_info(timestamp without time zone, boolean)    FUNCTION     O  CREATE FUNCTION public.correctly_formated_parking_info(input_out_time timestamp without time zone, input_inside boolean) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
BEGIN
	if (input_inside and input_out_time is NULL) 
	or (not input_inside and not input_out_time is NULL) then
		return true;
	ELSE
		return false;
	end if;
END;
$$;
 x   DROP FUNCTION public.correctly_formated_parking_info(input_out_time timestamp without time zone, input_inside boolean);
       public          postgres    false            ?            1255    36267    gate_status()    FUNCTION     ?   CREATE FUNCTION public.gate_status() RETURNS boolean
    LANGUAGE sql
    AS $$SELECT status
FROM public.gate_log
ORDER by "timestamp" DESC
LIMIT 1$$;
 $   DROP FUNCTION public.gate_status();
       public          postgres    false            ?            1255    36429    has_active_ticket(text, bigint)    FUNCTION     @  CREATE FUNCTION public.has_active_ticket(input_plate text, input_ticket bigint) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE
	f_result bool;
BEGIN
	select exists(select parking_id from parking 
		where ticket=input_ticket
		and plate=input_plate
		and inside=true )
		into f_result;
	return f_result;
END;
$$;
 O   DROP FUNCTION public.has_active_ticket(input_plate text, input_ticket bigint);
       public          postgres    false            ?            1255    36368    randint(bigint, bigint)    FUNCTION     ?   CREATE FUNCTION public.randint(min_i bigint DEFAULT 1, max_i bigint DEFAULT 10) RETURNS bigint
    LANGUAGE plpgsql
    AS $$
DECLARE
	res bigint;
BEGIN
	SELECT floor(random() * (max_i - min_i) + min_i)::bigint into res;
	return res;
END;
$$;
 :   DROP FUNCTION public.randint(min_i bigint, max_i bigint);
       public          postgres    false            ?            1255    36409    random_char()    FUNCTION     ?  CREATE FUNCTION public.random_char() RETURNS "char"
    LANGUAGE sql
    RETURN (ARRAY['A'::text, 'B'::text, 'C'::text, 'D'::text, 'E'::text, 'F'::text, 'G'::text, 'H'::text, 'I'::text, 'J'::text, 'K'::text, 'L'::text, 'M'::text, 'N'::text, 'O'::text, 'P'::text, 'Q'::text, 'R'::text, 'S'::text, 'T'::text, 'U'::text, 'V'::text, 'W'::text, 'X'::text, 'Y'::text, 'Z'::text])[floor(((random() * (26)::double precision) + (1)::double precision))];
 $   DROP FUNCTION public.random_char();
       public          postgres    false            ?            1255    36369    random_ean13()    FUNCTION     ?   CREATE FUNCTION public.random_ean13() RETURNS bigint
    LANGUAGE sql
    RETURN public.randint('1000000000000'::bigint, '9999999999999'::bigint);
 %   DROP FUNCTION public.random_ean13();
       public          postgres    false    234            ?            1255    36410    random_plate()    FUNCTION     ?   CREATE FUNCTION public.random_plate() RETURNS text
    LANGUAGE sql
    RETURN lower(concat((public.randint((10)::bigint, (99)::bigint))::text, public.random_char(), (public.randint((10000)::bigint, (999999)::bigint))::text));
 %   DROP FUNCTION public.random_plate();
       public          postgres    false    236    234            ?            1255    36408    random_str(integer)    FUNCTION     |   CREATE FUNCTION public.random_str(len integer) RETURNS text
    LANGUAGE sql
    RETURN "left"(md5((random())::text), len);
 .   DROP FUNCTION public.random_str(len integer);
       public          postgres    false            ?            1255    36385    vehicle_in(text)    FUNCTION     ?  CREATE FUNCTION public.vehicle_in(input_plate text) RETURNS jsonb
    LANGUAGE plpgsql
    AS $$
DECLARE
	f_result bool;
	tmp_ticket bigint;
	vehicle_in bool;
BEGIN
	--Checking and preparing data
	select random_ean13() into tmp_ticket;
	WHILE EXISTS(select * from ticket where "id" = tmp_ticket) LOOP
		select random_ean13() into tmp_ticket;
	end loop;
	
	-- Insert datas
	IF not EXISTS(select * from public.vehicle where plate=input_plate) then
		INSERT INTO public.vehicle(plate) VALUES (input_plate);
	ELSE
		select inside from public.vehicle where plate=input_plate into vehicle_in;
		if vehicle_in THEN
			RETURN 0;
		END IF;
	END IF;
	
	INSERT INTO public.ticket(id, plate) VALUES (tmp_ticket, input_plate);
	INSERT INTO public.parking(ticket, plate) VALUES (tmp_ticket, input_plate) RETURNING FOUND into f_result;
	
	if f_result THEN
		UPDATE public.vehicle set inside=true WHERE plate=input_plate;
		return jsonb_build_object('ticket', tmp_ticket);
	ELSE
		return 0;
	end if;
END;
$$;
 3   DROP FUNCTION public.vehicle_in(input_plate text);
       public          postgres    false            ?            1255    36386    vehicle_in(text, bigint)    FUNCTION     ?  CREATE FUNCTION public.vehicle_in(input_plate text, input_ticket bigint) RETURNS jsonb
    LANGUAGE plpgsql
    AS $$
DECLARE
	f_result bool;
BEGIN
	INSERT INTO public.parking(ticket, plate, inside)
	VALUES (input_ticket, input_plate, true)
	RETURNING TRUE INTO f_result;
	if f_result then
		return jsonb_build_object('ticket', input_ticket, 
								  'result', f_result);
	ELSE
		return jsonb_build_object('result', f_result);
	end if;
END;
$$;
 H   DROP FUNCTION public.vehicle_in(input_plate text, input_ticket bigint);
       public          postgres    false            ?            1255    36395    vehicle_out(text, bigint)    FUNCTION     ?  CREATE FUNCTION public.vehicle_out(input_plate text, input_ticket bigint) RETURNS jsonb
    LANGUAGE plpgsql
    AS $$
DECLARE
	f_result bool;
	t_in TIMESTAMP;
	v_type int;
	cur TIMESTAMP;
	p_price float;
	park_time int;
	p_cost float;
BEGIN
	select CURRENT_TIMESTAMP into cur;
	UPDATE public.parking SET time_out=cur, inside=false
	WHERE ticket=input_ticket
	AND plate=input_plate
	AND inside=TRUE
	RETURNING TRUE, time_in, vehicle_type INTO f_result, t_in, v_type;
	
	if f_result then
		-- TODO: tinh gia theo gio va loai xe
		SELECT price from public.parking_price where id=v_type into p_price;
		if v_type = 1 THEN
			p_cost = p_price;
		ELSE
			SELECT EXTRACT(EPOCH FROM current_timestamp-t_in)/3600 + 1 into park_time;
			p_cost = p_price * park_time;
		end if;
		return jsonb_build_object('cost', p_cost, 'result', f_result);
	ELSE
		return jsonb_build_object('result', f_result);
	end if;
END;
$$;
 I   DROP FUNCTION public.vehicle_out(input_plate text, input_ticket bigint);
       public          postgres    false            ?            1259    36398    parking    TABLE     ?  CREATE TABLE public.parking (
    parking_id integer NOT NULL,
    ticket bigint NOT NULL,
    plate character varying NOT NULL,
    time_in timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    time_out timestamp with time zone,
    inside boolean DEFAULT true NOT NULL,
    vehicle_type integer DEFAULT 1 NOT NULL,
    CONSTRAINT correctly_formated_check CHECK (public.correctly_formated_parking_info((time_out)::timestamp without time zone, inside))
);
    DROP TABLE public.parking;
       public         heap    postgres    false    230            ?            1259    36433    Currently Parking Vehicle    VIEW     ?   CREATE VIEW public."Currently Parking Vehicle" AS
 SELECT parking.plate
   FROM public.parking
  WHERE (parking.inside = true);
 .   DROP VIEW public."Currently Parking Vehicle";
       public          postgres    false    214    214            ?            1259    36262    gate_log    TABLE     ?   CREATE TABLE public.gate_log (
    status boolean NOT NULL,
    "timestamp" timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);
    DROP TABLE public.gate_log;
       public         heap    postgres    false            ?            1259    36397    parking_parking_id_seq    SEQUENCE     ?   CREATE SEQUENCE public.parking_parking_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 -   DROP SEQUENCE public.parking_parking_id_seq;
       public          postgres    false    214                       0    0    parking_parking_id_seq    SEQUENCE OWNED BY     Q   ALTER SEQUENCE public.parking_parking_id_seq OWNED BY public.parking.parking_id;
          public          postgres    false    213            ?            1259    36388    parking_price    TABLE     ?   CREATE TABLE public.parking_price (
    id integer NOT NULL,
    name character varying,
    range int4range,
    price double precision NOT NULL
);
 !   DROP TABLE public.parking_price;
       public         heap    postgres    false            ?            1259    36387    parking_price_id_seq    SEQUENCE     ?   CREATE SEQUENCE public.parking_price_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 +   DROP SEQUENCE public.parking_price_id_seq;
       public          postgres    false    212                       0    0    parking_price_id_seq    SEQUENCE OWNED BY     M   ALTER SEQUENCE public.parking_price_id_seq OWNED BY public.parking_price.id;
          public          postgres    false    211            ?            1259    36281    vehicle_types    TABLE     d   CREATE TABLE public.vehicle_types (
    id integer NOT NULL,
    name character varying NOT NULL
);
 !   DROP TABLE public.vehicle_types;
       public         heap    postgres    false            {           2604    36401    parking parking_id    DEFAULT     x   ALTER TABLE ONLY public.parking ALTER COLUMN parking_id SET DEFAULT nextval('public.parking_parking_id_seq'::regclass);
 A   ALTER TABLE public.parking ALTER COLUMN parking_id DROP DEFAULT;
       public          postgres    false    213    214    214            z           2604    36391    parking_price id    DEFAULT     t   ALTER TABLE ONLY public.parking_price ALTER COLUMN id SET DEFAULT nextval('public.parking_price_id_seq'::regclass);
 ?   ALTER TABLE public.parking_price ALTER COLUMN id DROP DEFAULT;
       public          postgres    false    212    211    212            ?           2606    36407    parking Parking_pkey 
   CONSTRAINT     \   ALTER TABLE ONLY public.parking
    ADD CONSTRAINT "Parking_pkey" PRIMARY KEY (parking_id);
 @   ALTER TABLE ONLY public.parking DROP CONSTRAINT "Parking_pkey";
       public            postgres    false    214            ?           2606    36437 "   parking no_dup_active_ticket_check    CHECK CONSTRAINT     ?   ALTER TABLE public.parking
    ADD CONSTRAINT no_dup_active_ticket_check CHECK (public.check_no_active_ticket((plate)::text, ticket, inside)) NOT VALID;
 G   ALTER TABLE public.parking DROP CONSTRAINT no_dup_active_ticket_check;
       public          postgres    false    214    214    214    214    214    229    214            ?           2606    36300 $   vehicle_types vehicle_types_name_key 
   CONSTRAINT     _   ALTER TABLE ONLY public.vehicle_types
    ADD CONSTRAINT vehicle_types_name_key UNIQUE (name);
 N   ALTER TABLE ONLY public.vehicle_types DROP CONSTRAINT vehicle_types_name_key;
       public            postgres    false    210            ?           2606    36287     vehicle_types vehicle_types_pkey 
   CONSTRAINT     ^   ALTER TABLE ONLY public.vehicle_types
    ADD CONSTRAINT vehicle_types_pkey PRIMARY KEY (id);
 J   ALTER TABLE ONLY public.vehicle_types DROP CONSTRAINT vehicle_types_pkey;
       public            postgres    false    210            ?           2606    36440 !   parking parking_vehicle_type_fkey    FK CONSTRAINT     ?   ALTER TABLE ONLY public.parking
    ADD CONSTRAINT parking_vehicle_type_fkey FOREIGN KEY (vehicle_type) REFERENCES public.vehicle_types(id) ON UPDATE CASCADE ON DELETE RESTRICT;
 K   ALTER TABLE ONLY public.parking DROP CONSTRAINT parking_vehicle_type_fkey;
       public          postgres    false    214    210    3204           