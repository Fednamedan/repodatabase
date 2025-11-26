CREATE DATABASE IF NOT EXISTS university CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE university;

CREATE TABLE Countries (
    country_id INT AUTO_INCREMENT PRIMARY KEY,
    country_name VARCHAR(100) NOT NULL UNIQUE,
    country_code CHAR(3) NOT NULL UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE Cities (
    city_id INT AUTO_INCREMENT PRIMARY KEY,
    city_name VARCHAR(100) NOT NULL,
    country_id INT NOT NULL,
    population INT NULL CHECK (population >= 0),
    FOREIGN KEY (country_id) REFERENCES Countries(country_id) ON DELETE RESTRICT,
    INDEX idx_city_country (city_name, country_id)
) ENGINE=InnoDB;

CREATE TABLE Faculties (
    faculty_id INT AUTO_INCREMENT PRIMARY KEY,
    faculty_name VARCHAR(200) NOT NULL UNIQUE,
    dean_name VARCHAR(150) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    phone VARCHAR(20) NULL,
    budget DECIMAL(15,2) NOT NULL DEFAULT 0.00 CHECK (budget >= 0),
    established_year YEAR NOT NULL CHECK (established_year >= 1800 AND established_year <= 2100),
    INDEX idx_faculty_established (established_year)
) ENGINE=InnoDB;


CREATE TABLE Departments (
    department_id INT AUTO_INCREMENT PRIMARY KEY,
    department_name VARCHAR(200) NOT NULL,
    faculty_id INT NOT NULL,
    head_name VARCHAR(150) NOT NULL,
    room_number VARCHAR(10) NOT NULL,
    FOREIGN KEY (faculty_id) REFERENCES Faculties(faculty_id) ON DELETE CASCADE,
    UNIQUE KEY unique_department_faculty (department_name, faculty_id),
    INDEX idx_department_faculty (faculty_id)
) ENGINE=InnoDB;

-- 5. Таблица преподавателей
CREATE TABLE Professors (
    professor_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    phone VARCHAR(20) NULL,
    birth_date DATE NOT NULL CHECK (birth_date <= '2024-01-01' AND YEAR(birth_date) >= 1900),
    hire_date DATE NOT NULL DEFAULT (CURRENT_DATE),
    salary DECIMAL(10,2) NOT NULL CHECK (salary >= 0),
    department_id INT NOT NULL,
    degree ENUM('PhD', 'Master', 'Bachelor', 'Professor') NOT NULL DEFAULT 'Master',
    FOREIGN KEY (department_id) REFERENCES Departments(department_id) ON DELETE RESTRICT,
    INDEX idx_professor_name (last_name, first_name),
    INDEX idx_professor_department (department_id),
    INDEX idx_professor_hire (hire_date)
) ENGINE=InnoDB;


CREATE TABLE ResearchInterests (
    interest_id INT AUTO_INCREMENT PRIMARY KEY,
    interest_name VARCHAR(200) NOT NULL UNIQUE,
    description TEXT NULL,
    field ENUM('Engineering', 'Science', 'Humanities', 'Social Sciences', 'Medical') NOT NULL,
    INDEX idx_research_field (field)
) ENGINE=InnoDB;

CREATE TABLE ProfessorInterests (
    professor_id INT NOT NULL,
    interest_id INT NOT NULL,
    PRIMARY KEY (professor_id, interest_id),
    FOREIGN KEY (professor_id) REFERENCES Professors(professor_id) ON DELETE CASCADE,
    FOREIGN KEY (interest_id) REFERENCES ResearchInterests(interest_id) ON DELETE CASCADE
) ENGINE=InnoDB;


CREATE TABLE Students (
    student_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    phone VARCHAR(20) NULL,
    birth_date DATE NOT NULL CHECK (birth_date <= '2024-01-01' AND YEAR(birth_date) >= 1980),
    enrollment_date DATE NOT NULL DEFAULT (CURRENT_DATE),
    faculty_id INT NOT NULL,
    city_id INT NULL,
    address TEXT NULL,
    status ENUM('Active', 'Graduated', 'Suspended', 'Withdrawn') NOT NULL DEFAULT 'Active',
    FOREIGN KEY (faculty_id) REFERENCES Faculties(faculty_id) ON DELETE RESTRICT,
    FOREIGN KEY (city_id) REFERENCES Cities(city_id) ON DELETE SET NULL,
    INDEX idx_student_name (last_name, first_name),
    INDEX idx_student_faculty (faculty_id),
    INDEX idx_student_status (status),
    INDEX idx_student_enrollment (enrollment_date)
) ENGINE=InnoDB;


CREATE TABLE Courses (
    course_id INT AUTO_INCREMENT PRIMARY KEY,
    course_code VARCHAR(20) NOT NULL UNIQUE,
    course_name VARCHAR(200) NOT NULL,
    description TEXT NULL,
    credits TINYINT NOT NULL CHECK (credits BETWEEN 1 AND 10),
    department_id INT NOT NULL,
    hours_per_semester SMALLINT NOT NULL DEFAULT 36 CHECK (hours_per_semester BETWEEN 10 AND 200),
    is_elective BOOLEAN NOT NULL DEFAULT FALSE,
    FOREIGN KEY (department_id) REFERENCES Departments(department_id) ON DELETE CASCADE,
    INDEX idx_course_department (department_id),
    INDEX idx_course_credits (credits)
) ENGINE=InnoDB;


CREATE TABLE StudyGroups (
    group_id INT AUTO_INCREMENT PRIMARY KEY,
    group_code VARCHAR(20) NOT NULL UNIQUE,
    faculty_id INT NOT NULL,
    year_established YEAR NOT NULL DEFAULT (2024),
    curator_id INT NULL,
    FOREIGN KEY (faculty_id) REFERENCES Faculties(faculty_id) ON DELETE CASCADE,
    FOREIGN KEY (curator_id) REFERENCES Professors(professor_id) ON DELETE SET NULL,
    INDEX idx_group_faculty (faculty_id)
) ENGINE=InnoDB;

CREATE TABLE StudentGroups (
    student_id INT NOT NULL,
    group_id INT NOT NULL,
    joined_date DATE NOT NULL DEFAULT (CURRENT_DATE),
    PRIMARY KEY (student_id, group_id),
    FOREIGN KEY (student_id) REFERENCES Students(student_id) ON DELETE CASCADE,
    FOREIGN KEY (group_id) REFERENCES StudyGroups(group_id) ON DELETE CASCADE,
    INDEX idx_student_group (student_id, group_id)
) ENGINE=InnoDB;


CREATE TABLE ClassSchedule (
    schedule_id INT AUTO_INCREMENT PRIMARY KEY,
    course_id INT NOT NULL,
    professor_id INT NOT NULL,
    group_id INT NOT NULL,
    room VARCHAR(20) NOT NULL,
    day_of_week ENUM('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday') NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    semester TINYINT NOT NULL CHECK (semester BETWEEN 1 AND 8),
    academic_year YEAR NOT NULL,
    FOREIGN KEY (course_id) REFERENCES Courses(course_id) ON DELETE CASCADE,
    FOREIGN KEY (professor_id) REFERENCES Professors(professor_id) ON DELETE CASCADE,
    FOREIGN KEY (group_id) REFERENCES StudyGroups(group_id) ON DELETE CASCADE,
    INDEX idx_schedule_course (course_id),
    INDEX idx_schedule_professor (professor_id),
    INDEX idx_schedule_group (group_id),
    INDEX idx_schedule_time (day_of_week, start_time),
    INDEX idx_schedule_semester (semester, academic_year)
) ENGINE=InnoDB;


CREATE TABLE Grades (
    grade_id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT NOT NULL,
    course_id INT NOT NULL,
    professor_id INT NOT NULL,
    grade DECIMAL(3,1) NOT NULL CHECK (grade BETWEEN 0 AND 100),
    grade_date DATE NOT NULL DEFAULT (CURRENT_DATE),
    semester TINYINT NOT NULL CHECK (semester BETWEEN 1 AND 8),
    academic_year YEAR NOT NULL,
    grade_type ENUM('Exam', 'Test', 'Project', 'Homework', 'Quiz') NOT NULL DEFAULT 'Exam',
    comments TEXT NULL,
    FOREIGN KEY (student_id) REFERENCES Students(student_id) ON DELETE CASCADE,
    FOREIGN KEY (course_id) REFERENCES Courses(course_id) ON DELETE CASCADE,
    FOREIGN KEY (professor_id) REFERENCES Professors(professor_id) ON DELETE CASCADE,
    UNIQUE KEY unique_grade_record (student_id, course_id, professor_id, grade_type, semester, academic_year),
    INDEX idx_grade_student (student_id),
    INDEX idx_grade_course (course_id),
    INDEX idx_grade_professor (professor_id),
    INDEX idx_grade_date (grade_date),
    INDEX idx_grade_semester (semester, academic_year)
) ENGINE=InnoDB;

CREATE TABLE Publications (
    publication_id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(500) NOT NULL,
    abstract TEXT NULL,
    publication_date DATE NOT NULL CHECK (publication_date <= '2024-12-31'),
    publisher VARCHAR(300) NULL,
    doi VARCHAR(100) UNIQUE NULL,
    type ENUM('Journal', 'Conference', 'Book', 'Thesis') NOT NULL DEFAULT 'Journal',
    impact_factor DECIMAL(4,2) NULL CHECK (impact_factor >= 0),
    pages SMALLINT NULL CHECK (pages > 0),
    INDEX idx_publication_date (publication_date),
    INDEX idx_publication_type (type),
    INDEX idx_publication_publisher (publisher(100))
) ENGINE=InnoDB;


CREATE TABLE ProfessorPublications (
    professor_id INT NOT NULL,
    publication_id INT NOT NULL,
    author_order TINYINT NOT NULL CHECK (author_order >= 1),
    is_corresponding_author BOOLEAN NOT NULL DEFAULT FALSE,
    PRIMARY KEY (professor_id, publication_id),
    FOREIGN KEY (professor_id) REFERENCES Professors(professor_id) ON DELETE CASCADE,
    FOREIGN KEY (publication_id) REFERENCES Publications(publication_id) ON DELETE CASCADE,
    INDEX idx_professor_publication (professor_id, publication_id)
) ENGINE=InnoDB;


CREATE TABLE Laboratories (
    lab_id INT AUTO_INCREMENT PRIMARY KEY,
    lab_name VARCHAR(200) NOT NULL,
    department_id INT NOT NULL,
    supervisor_id INT NOT NULL,
    location VARCHAR(100) NOT NULL,
    equipment_budget DECIMAL(12,2) NOT NULL DEFAULT 0.00 CHECK (equipment_budget >= 0),
    established_date DATE NOT NULL DEFAULT (CURRENT_DATE),
    FOREIGN KEY (department_id) REFERENCES Departments(department_id) ON DELETE CASCADE,
    FOREIGN KEY (supervisor_id) REFERENCES Professors(professor_id) ON DELETE RESTRICT,
    UNIQUE KEY unique_lab_department (lab_name, department_id),
    INDEX idx_lab_department (department_id),
    INDEX idx_lab_supervisor (supervisor_id)
) ENGINE=InnoDB;


CREATE TABLE ResearchProjects (
    project_id INT AUTO_INCREMENT PRIMARY KEY,
    project_name VARCHAR(300) NOT NULL,
    lab_id INT NOT NULL,
    principal_investigator_id INT NOT NULL,
    start_date DATE NOT NULL DEFAULT (CURRENT_DATE),
    end_date DATE NULL,
    budget DECIMAL(12,2) NOT NULL CHECK (budget >= 0),
    funding_source VARCHAR(200) NULL,
    status ENUM('Planning', 'Active', 'Completed', 'Cancelled') NOT NULL DEFAULT 'Planning',
    FOREIGN KEY (lab_id) REFERENCES Laboratories(lab_id) ON DELETE CASCADE,
    FOREIGN KEY (principal_investigator_id) REFERENCES Professors(professor_id) ON DELETE RESTRICT,
    INDEX idx_project_lab (lab_id),
    INDEX idx_project_status (status),
    INDEX idx_project_dates (start_date, end_date)
) ENGINE=InnoDB;


CREATE TABLE StudentProjects (
    student_id INT NOT NULL,
    project_id INT NOT NULL,
    role VARCHAR(100) NOT NULL DEFAULT 'Research Assistant',
    hours_per_week DECIMAL(4,1) NOT NULL DEFAULT 10.0 CHECK (hours_per_week BETWEEN 1 AND 40),
    start_date DATE NOT NULL DEFAULT (CURRENT_DATE),
    end_date DATE NULL,
    stipend DECIMAL(8,2) NULL CHECK (stipend >= 0),
    PRIMARY KEY (student_id, project_id),
    FOREIGN KEY (student_id) REFERENCES Students(student_id) ON DELETE CASCADE,
    FOREIGN KEY (project_id) REFERENCES ResearchProjects(project_id) ON DELETE CASCADE,
    INDEX idx_student_project (student_id, project_id),
    INDEX idx_project_role (role)
) ENGINE=InnoDB;


CREATE TABLE LibraryResources (
    resource_id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(500) NOT NULL,
    author VARCHAR(300) NULL,
    isbn VARCHAR(17) UNIQUE NULL,
    resource_type ENUM('Book', 'Journal', 'E-book', 'Thesis', 'Conference Proceedings') NOT NULL,
    publication_year YEAR NULL CHECK (publication_year IS NULL OR publication_year BETWEEN 1500 AND 2100),
    publisher VARCHAR(300) NULL,
    total_copies INT NOT NULL DEFAULT 1 CHECK (total_copies >= 0),
    available_copies INT NOT NULL DEFAULT 1 CHECK (available_copies >= 0 AND available_copies <= total_copies),
    location VARCHAR(100) NULL,
    INDEX idx_resource_title (title),
    INDEX idx_resource_type (resource_type),
    INDEX idx_resource_author (author(100)),
    INDEX idx_resource_year (publication_year)
) ENGINE=InnoDB;


CREATE TABLE ResourceLoans (
    loan_id INT AUTO_INCREMENT PRIMARY KEY,
    resource_id INT NOT NULL,
    student_id INT NULL,
    professor_id INT NULL,
    loan_date DATE NOT NULL DEFAULT (CURRENT_DATE),
    due_date DATE NOT NULL,
    return_date DATE NULL,
    fine_amount DECIMAL(6,2) NOT NULL DEFAULT 0.00 CHECK (fine_amount >= 0),
    status ENUM('On Loan', 'Returned', 'Overdue', 'Lost') NOT NULL DEFAULT 'On Loan',
    FOREIGN KEY (resource_id) REFERENCES LibraryResources(resource_id) ON DELETE CASCADE,
    FOREIGN KEY (student_id) REFERENCES Students(student_id) ON DELETE SET NULL,
    FOREIGN KEY (professor_id) REFERENCES Professors(professor_id) ON DELETE SET NULL,
    INDEX idx_loan_resource (resource_id),
    INDEX idx_loan_student (student_id),
    INDEX idx_loan_professor (professor_id),
    INDEX idx_loan_due_date (due_date),
    INDEX idx_loan_status (status),
    INDEX idx_loan_dates (loan_date, due_date, return_date)
) ENGINE=InnoDB;

CREATE TABLE Classrooms (
    classroom_id INT AUTO_INCREMENT PRIMARY KEY,
    room_number VARCHAR(10) NOT NULL UNIQUE,
    building VARCHAR(50) NOT NULL,
    capacity SMALLINT NOT NULL CHECK (capacity BETWEEN 1 AND 500),
    has_projector BOOLEAN NOT NULL DEFAULT FALSE,
    has_computers BOOLEAN NOT NULL DEFAULT FALSE,
    faculty_id INT NOT NULL,
    FOREIGN KEY (faculty_id) REFERENCES Faculties(faculty_id) ON DELETE CASCADE,
    INDEX idx_classroom_building (building, room_number),
    INDEX idx_classroom_capacity (capacity)
) ENGINE=InnoDB;

CREATE TABLE Scholarships (
    scholarship_id INT AUTO_INCREMENT PRIMARY KEY,
    scholarship_name VARCHAR(200) NOT NULL UNIQUE,
    provider VARCHAR(200) NOT NULL,
    amount DECIMAL(8,2) NOT NULL CHECK (amount > 0),
    requirements TEXT NULL,
    application_deadline DATE NULL,
    faculty_id INT NULL,
    FOREIGN KEY (faculty_id) REFERENCES Faculties(faculty_id) ON DELETE SET NULL,
    INDEX idx_scholarship_amount (amount),
    INDEX idx_scholarship_deadline (application_deadline)
) ENGINE=InnoDB;


CREATE TABLE StudentScholarships (
    student_id INT NOT NULL,
    scholarship_id INT NOT NULL,
    award_date DATE NOT NULL DEFAULT (CURRENT_DATE),
    end_date DATE NULL,
    amount_awarded DECIMAL(8,2) NOT NULL CHECK (amount_awarded > 0),
    status ENUM('Active', 'Completed', 'Revoked') NOT NULL DEFAULT 'Active',
    PRIMARY KEY (student_id, scholarship_id, award_date),
    FOREIGN KEY (student_id) REFERENCES Students(student_id) ON DELETE CASCADE,
    FOREIGN KEY (scholarship_id) REFERENCES Scholarships(scholarship_id) ON DELETE CASCADE,
    INDEX idx_student_scholarship (student_id, scholarship_id)
) ENGINE=InnoDB;
