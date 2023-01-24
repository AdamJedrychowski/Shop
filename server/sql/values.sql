INSERT INTO shop.Job (role) VALUES
('Admin'),
('Magazynier'),
('Dostawca');


INSERT INTO shop.Employee (name, surname, email, password, id_role) VALUES
('Adam', 'Jakiś', 'admin@gmail.com', 'a', 1),
('Pan', 'Ktoś', 'mag1@gmail.com', 'a', 2),
('Klaudia', 'Beż', 'mag2@gmail.com', 'a', 2),
('Michał', 'Też', 'mag3@gmail.com', 'a', 2),
('Jan', 'Kowal', 'dostawca1@gmail.com', 'a', 3),
('Jacek', 'Taki', 'dostawca2@gmail.com', 'a', 3),
('Julia', 'Laka', 'dostawca3@gmail.com', 'a', 3);



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
