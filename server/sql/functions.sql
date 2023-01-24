DROP FUNCTION authenticate;
DROP FUNCTION register_client;
DROP FUNCTION register_employee;
DROP FUNCTION new_item;
DROP FUNCTION list_clients;
DROP FUNCTION country_buy_item;
DROP FUNCTION country_stats;


-- 
-- Funkcja autoryzuje kleintów oraz pracowników używając przy tym CTE do połączenia relacji Pracownik z Klientem.
-- Jeśli zostanie znaleziony użytkownik to zostaje zwrócone jego id oraz rola.
-- Jeśli dane nie zostaną znalezione to rzucamy wyjątek.
-- 
CREATE OR REPLACE FUNCTION authenticate(in_email VARCHAR(50), in_pass VARCHAR(40))
RETURNS TABLE(id INTEGER, role VARCHAR(15)) AS
$$
BEGIN
    RETURN QUERY
    WITH Person AS (
            SELECT E.id, E.email, E.password, J.role FROM shop.Job J JOIN shop.Employee E ON J.id = E.id_role
            UNION
            SELECT C.id, C.email, C.password, 'Klient' FROM shop.Client C
    )
    SELECT P.id, P.role FROM Person P WHERE P.email = in_email AND P.password = in_pass;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Nie poprawne dane';
    END IF;
END;
$$
LANGUAGE plpgsql;


-- 
-- Funkcja służy do stworzenia nowego konta klienta. Sprawdza przed tym poprawność danych, takich jak email i wiek klienta.
-- Sprawdzane jest również czy email znajduje się już w bazie czy to w relacji Klient czy to w Pracownik.
-- Funkcja rzuca wyjątek jeśli format emailu, wiek się nie zgadzają lub email jest już w bazie.
-- 
CREATE OR REPLACE FUNCTION register_client(name VARCHAR(20), surname VARCHAR(30), email VARCHAR(50), pass VARCHAR(40), age INTEGER, in_gender VARCHAR(10), in_country VARCHAR(50))
RETURNS void AS
$$
DECLARE
    result INTEGER;
BEGIN
    IF email !~ '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$' THEN
        RAISE EXCEPTION 'Niepoprawny email';
    END IF;

        IF email IN (SELECT E.email FROM shop.Employee E UNION SELECT C.email FROM shop.Client C) THEN
        RAISE EXCEPTION 'Konto na dany email juz istnieje';
    END IF;

    IF age NOT BETWEEN 0 AND 110 THEN
        RAISE EXCEPTION 'Niepoprawny wiek';
    END IF;
    INSERT INTO shop.Client (name, surname, email, password, age, id_gender, id_country)
    VALUES (name, surname, email, pass, age,
    (SELECT id FROM shop.Gender G WHERE G.gender::VARCHAR = in_gender),
    (SELECT id FROM shop.Nationality N WHERE N.country = in_country));
END;
$$
LANGUAGE plpgsql;


-- 
-- Funkcja służy do stworzenia nowego konta pracownika. Sprawdza przed tym poprawność danych, takich jak email i stanowisko.
-- Sprawdzane jest również czy email znajduje się już w bazie czy to w relacji Klient czy to w Pracownik.
-- Funkcja rzuca wyjątek jeśli format emailu, stanowisko się nie zgadzają lub email jest już w bazie.
-- 
CREATE OR REPLACE FUNCTION register_employee(name VARCHAR(20), surname VARCHAR(30), in_email VARCHAR(50), pass VARCHAR(40), in_role VARCHAR(15))
RETURNS void AS
$$
DECLARE
    result INTEGER;
BEGIN
    IF in_email !~ '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$' THEN
        RAISE EXCEPTION 'Niepoprawny email';
    END IF;

    IF in_email IN (SELECT email FROM shop.Employee UNION SELECT email FROM shop.Client) THEN
        RAISE EXCEPTION 'Konto na dany email juz istnieje';
    END IF;

    SELECT id INTO result FROM shop.Job J WHERE J.role = in_role;
    IF result IS NULL THEN
        RAISE EXCEPTION 'Brak danej roli';
    END IF;
    INSERT INTO shop.Employee (name, surname, email, password, id_role) VALUES (name, surname, in_email, pass, result);
END;
$$
LANGUAGE plpgsql;


-- 
-- Funkcja dodaje nowy produkt do bazy, sprawdzając przed tym czy admin nie wpisał ujemnej wartości dla ilości produktu lub jego ceny.
-- W takim przypadku rzuca odpowiedni wyjątek. Jeżeli nazwa produktu znajduje się już w bazie funckja również rzuca wyjątek.
-- Funkcja dostępna tylko dla admina.
-- 
CREATE OR REPLACE FUNCTION new_item(in_name VARCHAR(30), in_price INTEGER, in_number INTEGER)
RETURNS void AS
$$
DECLARE
    result VARCHAR(30);
BEGIN
    IF in_number <= 0 THEN
        RAISE EXCEPTION 'Ilość nie może być ujemna';
    END IF;

    IF in_price <= 0 THEN
        RAISE EXCEPTION 'Cena nie może być ujemna';
    END IF;

    SELECT I.name INTO result FROM shop.Item I WHERE I.name = in_name;
    IF result IS NOT NULL THEN
        RAISE EXCEPTION 'Produkt o danej nazwie już istnieje';
    END IF;
    INSERT INTO shop.Item (name, price, number) VALUES (in_name, in_price, in_number);
END;
$$
LANGUAGE plpgsql;


-- 
-- Funkcja wyisuje wszystkie informacje na temat klientów, takie jak id, imie, nazwisko, email, wiek, płeć i kraj pochodzenia
-- Funkcja dostępna tylko dla admina.
-- 
CREATE OR REPLACE FUNCTION list_clients()
RETURNS TABLE (id INTEGER, name VARCHAR(20), surname VARCHAR(30), email VARCHAR(50), age INTEGER, gender GENDER_TYPE, country VARCHAR(50)) AS
$$
BEGIN
    RETURN QUERY SELECT C.id, C.name, C.surname, C.email, C.age, G.gender, N.country FROM shop.Client C
    JOIN shop.Gender G ON C.id_gender = G.id JOIN shop.Nationality N ON C.id_country = N.id;
END;
$$
LANGUAGE plpgsql;


DROP VIEW country_data;
CREATE VIEW country_data AS SELECT N.country, OI.quantity, I.name, I.price FROM shop.Nationality N LEFT JOIN shop.Client C ON N.id = C.id_country LEFT JOIN shop.Order O ON C.id = O.id_client
        LEFT JOIN shop.Order_item OI ON O.id = OI.id_order LEFT JOIN shop.Item I ON OI.id_item = I.id;


-- 
-- Funckja zwraca nazwy produktów jakie zakupiono w danym państwie oraz ich ilość.
-- Jeśli klienci z danego państwa nic nie kupili to zostaje zwrócona informacja 'Nic nie kupiono'
-- Funkcja dostępna tylko dla admina.
-- 
CREATE OR REPLACE FUNCTION country_buy_item()
RETURNS TABLE (out_country VARCHAR(20), out_name VARCHAR(30), count BIGINT) AS
$$
BEGIN
    RETURN QUERY SELECT CD.country, COALESCE(CD.name, 'Nic nie kupiono'), COALESCE(SUM(CD.quantity), 0) AS sum_quantity FROM country_data CD GROUP BY CD.country, CD.name ORDER BY country, sum_quantity DESC;
END;
$$
LANGUAGE plpgsql;


-- 
-- Funkcja zwraca liczbę sprzedanych produktów w danym państwie oraz łączną ich cenę.
-- Jeśli klienci z danego państwa nie kupili nic zostanie zwrócone 0.
-- Funkcja dostępna tylko dla admina.
-- 
CREATE OR REPLACE FUNCTION country_stats()
RETURNS TABLE (out_country VARCHAR(20), count BIGINT, total_price BIGINT) AS
$$
BEGIN
    RETURN QUERY SELECT CD.country, COALESCE(SUM(CD.quantity), 0) AS sum_quantity, COALESCE(SUM(CD.price), 0) AS total_price FROM country_data CD GROUP BY CD.country ORDER BY sum_quantity DESC;
END;
$$
LANGUAGE plpgsql;