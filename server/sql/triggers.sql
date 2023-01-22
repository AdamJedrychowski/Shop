DROP TRIGGER status ON shop.Order;
DROP FUNCTION order_state;
DROP TRIGGER magazine_status ON shop.Order_item;
DROP FUNCTION magazine;


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

        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

CREATE TRIGGER status
BEFORE INSERT OR UPDATE ON shop.Order
FOR EACH ROW EXECUTE PROCEDURE order_state();




CREATE OR REPLACE FUNCTION magazine() RETURNS TRIGGER AS $$
BEGIN
    UPDATE shop.Item SET number = number - NEW.quantity WHERE id = NEW.id_item;
    RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

CREATE TRIGGER magazine_status
AFTER INSERT ON shop.Order_item
FOR EACH ROW EXECUTE PROCEDURE magazine();


