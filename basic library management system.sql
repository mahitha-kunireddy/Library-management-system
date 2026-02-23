CREATE DATABASE Library;
USE Library;
CREATE TABLE Authors (
    author_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL
);

CREATE TABLE Publishers (
    publisher_id INT PRIMARY KEY AUTO_INCREMENT,
    full_name VARCHAR(100) NOT NULL
);

CREATE TABLE Books (
    book_id INT PRIMARY KEY AUTO_INCREMENT,
    title VARCHAR(200) NOT NULL,
    author_id INT,
    publisher_id INT,
    genre VARCHAR(50),
    year_published INT,
    FOREIGN KEY (author_id) REFERENCES Authors(author_id),
    FOREIGN KEY (publisher_id) REFERENCES Publishers(publisher_id)
);

CREATE TABLE BookCopies (
    copy_id INT PRIMARY KEY AUTO_INCREMENT,
    book_id INT,
    status ENUM('available', 'issued') DEFAULT 'available',
    FOREIGN KEY (book_id) REFERENCES Books(book_id)
);

CREATE TABLE Members (
    member_id INT PRIMARY KEY AUTO_INCREMENT,
    full_name VARCHAR(100),
    email VARCHAR(150),
    join_date DATE
);

CREATE TABLE Loans (
    loan_id INT PRIMARY KEY AUTO_INCREMENT,
    copy_id INT,
    member_id INT,
    issue_date DATE,
    due_date DATE,
    return_date DATE,
    FOREIGN KEY (copy_id) REFERENCES BookCopies(copy_id),
    FOREIGN KEY (member_id) REFERENCES Members(member_id)
);

CREATE TABLE Fines (
    fine_id INT PRIMARY KEY AUTO_INCREMENT,
    loan_id INT,
    amount DECIMAL(5,2),
    FOREIGN KEY (loan_id) REFERENCES Loans(loan_id)
);

CREATE TABLE Staff (
    staff_id INT PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(50) UNIQUE,
    password_hash VARCHAR(200)
);

INSERT INTO Authors (name) VALUES 
('J.K. Rowling'), ('George Orwell'), ('Dan Brown');

INSERT INTO Publishers (full_name) VALUES
('Bloomsbury'), ('Penguin'), ('Random House');

INSERT INTO Books (title, author_id, publisher_id, genre, year_published) VALUES
('Harry Potter', 1, 1, 'Fantasy', 1997),
('1984', 2, 2, 'Dystopian', 1949),
('The Da Vinci Code', 3, 3, 'Thriller', 2003);

INSERT INTO BookCopies (book_id, status) VALUES
(1, 'available'), (1, 'available'), (1, 'issued'),
(2, 'available'),
(3, 'issued');

INSERT INTO Members (full_name, email, join_date) VALUES
('Alice', 'alice@mail.com', '2023-01-10'),
('Bob', 'bob@mail.com', '2023-02-12');

INSERT INTO Loans (copy_id, member_id, issue_date, due_date, return_date) VALUES
(3, 1, '2023-03-01', '2023-03-10', NULL),
(5, 2, '2023-03-02', '2023-03-12', '2023-03-11');

SELECT * FROM Books;

SELECT * FROM BookCopies WHERE status='available';

SELECT full_name FROM Members WHERE join_date > '2023-02-01';

SELECT b.title, a.name AS author, p.full_name AS publisher
FROM Books b
JOIN Authors a ON b.author_id=a.author_id
JOIN Publishers p ON b.publisher_id=p.publisher_id;

SELECT b.title, m.full_name, l.issue_date
FROM Loans l
JOIN BookCopies c ON l.copy_id=c.copy_id
JOIN Books b ON c.book_id=b.book_id
JOIN Members m ON l.member_id=m.member_id
WHERE c.status='issued';

SELECT b.title, COUNT(c.copy_id) AS total_copies
FROM Books b
LEFT JOIN BookCopies c ON b.book_id=c.book_id
GROUP BY b.book_id;

SELECT b.title, COUNT(*) AS issues,
RANK() OVER (ORDER BY COUNT(*) DESC) AS ranking
FROM Loans l
JOIN BookCopies bc ON l.copy_id = bc.copy_id
JOIN Books b ON bc.book_id = b.book_id
GROUP BY b.title;

SELECT m.full_name, b.title, l.due_date
FROM Loans l
JOIN Members m ON l.member_id=m.member_id
JOIN BookCopies c ON l.copy_id=c.copy_id
JOIN Books b ON c.book_id=b.book_id
WHERE l.return_date IS NULL AND l.due_date < CURDATE();

SELECT 
    loan_id,
    GREATEST(DATEDIFF(CURDATE(), due_date), 0) * 5 AS fine
FROM Loans;

SELECT m.full_name, COUNT(*) AS total_loans
FROM Loans l
JOIN Members m ON l.member_id=m.member_id
GROUP BY m.member_id
ORDER BY total_loans DESC;

SELECT b.title, COUNT(*) AS issued_count
FROM BookCopies c
JOIN Books b ON c.book_id=b.book_id
WHERE c.status='issued'
GROUP BY b.title;

CREATE VIEW OverdueBooks AS
SELECT m.full_name AS member, b.title, l.due_date
FROM Loans l
JOIN Members m ON l.member_id=m.member_id
JOIN BookCopies c ON l.copy_id=c.copy_id
JOIN Books b ON c.book_id=b.book_id
WHERE l.return_date IS NULL AND l.due_date < CURDATE();

DELIMITER //
CREATE PROCEDURE IssueBook(IN copy INT, IN member INT, IN due DATE)
BEGIN
    INSERT INTO Loans(copy_id, member_id, issue_date, due_date)
    VALUES(copy, member, CURDATE(), due);

    UPDATE BookCopies SET status='issued' WHERE copy_id=copy;
END //
DELIMITER ;

DELIMITER //
CREATE PROCEDURE ReturnBook(IN loan INT)
BEGIN
    UPDATE Loans SET return_date = CURDATE() WHERE loan_id = loan;

    UPDATE BookCopies 
    SET status='available'
    WHERE copy_id = (SELECT copy_id FROM Loans WHERE loan_id = loan);
END //
DELIMITER ;

DELIMITER //
CREATE TRIGGER fine_trigger AFTER UPDATE ON Loans
FOR EACH ROW
BEGIN
    IF NEW.return_date IS NOT NULL AND NEW.return_date > NEW.due_date THEN
        INSERT INTO Fines(loan_id, amount)
        VALUES(NEW.loan_id, DATEDIFF(NEW.return_date, NEW.due_date) * 5);
    END IF;
END //
DELIMITER ;


