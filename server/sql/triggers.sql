DROP TRIGGER status ON shop.Order;
DROP FUNCTION order_state;
DROP TRIGGER magazine_status ON shop.Order_item;
DROP FUNCTION magazine;
DROP TRIGGER fire_employee ON shop.Employee;
DROP FUNCTION fire;



-- 
-- Trigger załącza się przed wstawieniem nowego zamówienia. Wtedy ustawia status zamówienia na 'Nie opłacone'.
-- Uruchamia się też przed zaktualizowaniem danych. Jeśli klient opłacił zamówienie to zmieni się jego status na 'Przygotowywane' i
-- w tym momencie trigger wyszukuje magazyniera z najmniejszą ilościa zamówień i przypisuje go do tego zamówienia.
-- Kiedy magazynier przygotuje zamówienie, status zmieni się na 'Oczekuje na kuriera', CTE wyszuka kuriera z najmniejszą ilością przesyłek i
-- przypnie do niego paczkę. Kiedy kurier dostarczy pczkę to zamowienie przestaje mieć przypiętego pracownika.
-- 
CREATE OR REPLACE FUNCTION order_state() RETURNS TRIGGER AS $$
DECLARE
    new_id INTEGER;
BEGIN
    IF TG_OP = 'INSERT' THEN
        NEW.status := 'Nie opłacone';
        NEW.date := NOW();
    ELSIF TG_OP = 'UPDATE' AND OLD.status != NEW.status THEN
        IF NEW.status = 'Przygotowywane' THEN
            WITH warehouseman AS (SELECT E.id AS id, COUNT(O.id_employee) AS count FROM shop.Employee E JOIN shop.Job J ON E.id_role = J.id
                                LEFT JOIN shop.Order O ON O.id_employee = E.id WHERE J.role = 'Magazynier' GROUP BY E.id ORDER BY count LIMIT 1)
            SELECT id INTO new_id FROM warehouseman;
            NEW.id_employee := new_id;

        ELSIF NEW.status = 'Oczekuje na kuriera' THEN
            WITH deliverer AS (SELECT E.id AS id, COUNT(O.id_employee) AS count FROM shop.Employee E JOIN shop.Job J ON E.id_role = J.id
                                LEFT JOIN shop.Order O ON O.id_employee = E.id WHERE J.role = 'Dostawca' GROUP BY E.id ORDER BY count LIMIT 1)
            SELECT id INTO new_id FROM deliverer;
            NEW.id_employee := new_id;

        ELSIF NEW.status = 'Dostarczone' THEN
            NEW.id_employee := NULL;
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

CREATE TRIGGER status
BEFORE INSERT OR UPDATE ON shop.Order
FOR EACH ROW EXECUTE PROCEDURE order_state();



-- 
-- Trigger uruchamia się po wstawieniu produktu z zamówienia do bazy danych.
-- Wtedy to odejmuje zamówioną ilość tego produktu od ilości na magazynie.
-- 
CREATE OR REPLACE FUNCTION magazine() RETURNS TRIGGER AS $$
BEGIN
    UPDATE shop.Item SET number = number - NEW.quantity WHERE id = NEW.id_item;
    RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

CREATE TRIGGER magazine_status
AFTER INSERT ON shop.Order_item
FOR EACH ROW EXECUTE PROCEDURE magazine();



-- 
-- Trigger załącza się przed zwolnieniem pracownika. Ma na celu przypisać innych pracowników na tym samym stanowisku do zamówień.
-- Stosujemy pętle aby nie przerzucić wszystkich zamówień na jednego pracownika.
-- Za każda iteracją szukamy pracownika o najmniejszej ilości zamówień, służy nam do tego CTE.
-- 
CREATE OR REPLACE FUNCTION fire() RETURNS TRIGGER AS $$
DECLARE
    rows INTEGER;
BEGIN
    WHILE true
    LOOP
        SELECT COUNT(*) INTO rows FROM shop.Order O WHERE O.id_employee = OLD.id;
        IF rows = 0 THEN
            EXIT;
        END IF;
        WITH employee AS (SELECT E.id AS id, COUNT(O.id_employee) AS count FROM shop.Employee E LEFT JOIN shop.Order O ON O.id_employee = E.id
                        WHERE E.id_role = OLD.id_role AND E.id != OLD.id GROUP BY E.id ORDER BY count LIMIT 1)
        UPDATE shop.Order O SET id_employee = employee.id FROM employee WHERE O.id = (SELECT id FROM shop.Order O WHERE O.id_employee = OLD.id LIMIT 1);
    END LOOP;

    RETURN OLD;
END;
$$ LANGUAGE 'plpgsql';

CREATE TRIGGER fire_employee
BEFORE DELETE ON shop.Employee
FOR EACH ROW EXECUTE PROCEDURE fire();