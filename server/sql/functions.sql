
-- WITH Person AS (
--         SELECT email, password, role FROM shop.Job J JOIN shop.Employee E ON J.id = E.id_role
--         UNION
--         SELECT email, password, 'klient' FROM shop.Client
-- )


-- WITH AllClientData AS (
--     SELECT C.id, name, surname, email, password, age, gender, country FROM shop.Client C
--     JOIN shop.Nationality N ON C.id_country = N.id
--     JOIN shop.Gender G ON G.id = C.id_gender
-- )



DROP FUNCTION authenticate;
DROP FUNCTION register_client;
DROP FUNCTION register_employee;

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
    (SELECT id FROM shop.Gender G WHERE G.gender = in_gender),
    (SELECT id FROM shop.Nationality N WHERE N.country = in_country));
END;
$$
LANGUAGE plpgsql;


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

