USE university;

-- Создание хранимых процедур для часто используемых запросов
DELIMITER $$

CREATE PROCEDURE GetStudentPerformance(IN student_id INT)
BEGIN
    SELECT 
        s.student_id,
        CONCAT(s.first_name, ' ', s.last_name) as student_name,
        f.faculty_name,
        c.course_name,
        g.grade,
        g.grade_type,
        g.grade_date
    FROM Students s
    JOIN Faculties f ON s.faculty_id = f.faculty_id
    JOIN Grades g ON s.student_id = g.student_id
    JOIN Courses c ON g.course_id = c.course_id
    WHERE s.student_id = student_id
    ORDER BY g.grade_date DESC;
END$$

CREATE PROCEDURE GetFacultyStatistics(IN faculty_id INT)
BEGIN
    SELECT 
        f.faculty_name,
        COUNT(DISTINCT s.student_id) as students_count,
        COUNT(DISTINCT p.professor_id) as professors_count,
        COUNT(DISTINCT c.course_id) as courses_count,
        ROUND(AVG(g.grade), 2) as average_grade,
        COUNT(DISTINCT pub.publication_id) as publications_count
    FROM Faculties f
    LEFT JOIN Students s ON f.faculty_id = s.faculty_id
    LEFT JOIN Departments d ON f.faculty_id = d.faculty_id
    LEFT JOIN Professors p ON d.department_id = p.department_id
    LEFT JOIN Courses c ON d.department_id = c.department_id
    LEFT JOIN Grades g ON s.student_id = g.student_id
    LEFT JOIN ProfessorPublications pp ON p.professor_id = pp.professor_id
    LEFT JOIN Publications pub ON pp.publication_id = pub.publication_id
    WHERE f.faculty_id = faculty_id
    GROUP BY f.faculty_id;
END$$

DELIMITER ;

-- Создание событий для автоматического обслуживания
SET GLOBAL event_scheduler = ON;

DELIMITER $$

CREATE EVENT IF NOT EXISTS update_overdue_loans
ON SCHEDULE EVERY 1 DAY
STARTS CURRENT_TIMESTAMP
DO
BEGIN
    UPDATE ResourceLoans 
    SET status = 'Overdue',
        fine_amount = DATEDIFF(CURDATE(), due_date) * 5.00
    WHERE due_date < CURDATE() 
    AND return_date IS NULL 
    AND status = 'On Loan';
END$$

DELIMITER ;

-- Создание сложных аналитических запросов как представлений
CREATE VIEW faculty_performance_report AS
SELECT 
    f.faculty_name,
    COUNT(DISTINCT s.student_id) as total_students,
    COUNT(DISTINCT p.professor_id) as total_professors,
    COUNT(DISTINCT c.course_id) as total_courses,
    ROUND(AVG(g.grade), 2) as average_grade,
    COUNT(DISTINCT pub.publication_id) as total_publications,
    SUM(rp.budget) as total_research_budget
FROM Faculties f
LEFT JOIN Students s ON f.faculty_id = s.faculty_id
LEFT JOIN Departments d ON f.faculty_id = d.faculty_id
LEFT JOIN Professors p ON d.department_id = p.department_id
LEFT JOIN Courses c ON d.department_id = c.department_id
LEFT JOIN Grades g ON s.student_id = g.student_id
LEFT JOIN ProfessorPublications pp ON p.professor_id = pp.professor_id
LEFT JOIN Publications pub ON pp.publication_id = pub.publication_id
LEFT JOIN Laboratories l ON d.department_id = l.department_id
LEFT JOIN ResearchProjects rp ON l.lab_id = rp.lab_id
GROUP BY f.faculty_id;

-- Индексы для оптимизации производительности
CREATE INDEX idx_grades_student_course ON Grades(student_id, course_id);
CREATE INDEX idx_resource_loans_dates ON ResourceLoans(loan_date, due_date, return_date);
CREATE INDEX idx_students_faculty_status ON Students(faculty_id, status);
CREATE INDEX idx_professors_department ON Professors(department_id, hire_date);
