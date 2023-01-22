INSERT INTO shop.Job (role) VALUES
('Admin'),
('Magazynier'),
('Dostawca');


INSERT INTO shop.Employee (name, surname, email, password, id_role) VALUES
('Adam', 'Jakiś', 'adam@gmail.com', 'a', 1),
('Pan', 'Ktoś', 'adam1@gmail.com', 'a', 2),
('Klaudia', 'Beż', 'adam2@gmail.com', 'a', 2),
('Michał', 'Też', 'adam3@gmail.com', 'a', 2),
('Jan', 'Kowal', 'adam4@gmail.com', 'a', 3),
('Jacek', 'Taki', 'adam5@gmail.com', 'a', 3);



INSERT INTO shop.Nationality (country) VALUES
('Polska'), ('Niemcy'),
('Włochy'), ('Ukraina'), 
('Francja'), ('Grecja'),
('Szwecja'), ('Finlandia');


INSERT INTO shop.Gender (gender) VALUES
('Mężczyzna'), ('Kobieta'), ('Inny'), ('Brak');


INSERT INTO shop.Item (name, price, number) VALUES
('Karta graficzna', 1499, 4),
('Płyta główna', 999, 12),
('Dysk twardy', 249, 76),
('Dysk SSD', 359, 34),
('Monitor', 999, 8),
('Zasilacz', 550, 12),
('Procesor', 1229, 9),
('Klawiatura', 139, 178),
('Myszka', 150, 99);
