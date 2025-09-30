-- Script corrigido e adaptado para MySQL 4.1+

CREATE TABLE `environments` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `name` VARCHAR(100) NOT NULL,
    `created_at` DATETIME,
    `cliente` VARCHAR(100)
) ENGINE=InnoDB;

CREATE TABLE `courses` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `id_origem` INT,
    `name` VARCHAR(100) NOT NULL,
    `created_at` DATETIME,
    `environment_id` INT UNSIGNED,
    `cliente` VARCHAR(100),
    FOREIGN KEY (`environment_id`) REFERENCES `environments` (`id`)
) ENGINE=InnoDB;

CREATE TABLE `spaces` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `id_origem` INT,
    `name` VARCHAR(100) NOT NULL,
    `created_at` DATETIME,
    `members_count` INT DEFAULT 0,
    `course_id` INT UNSIGNED,
    `turn` VARCHAR(100),
    `cliente` VARCHAR(100),
    FOREIGN KEY (`course_id`) REFERENCES `courses` (`id`)
) ENGINE=InnoDB;

CREATE TABLE `subjects` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `id_origem` INT,
    `name` VARCHAR(100) NOT NULL,
    `space_id` INT UNSIGNED,
    `created_at` DATETIME,
    `is_root` TINYINT(1) DEFAULT 1,
    `parent_id` INT UNSIGNED,
    `cliente` VARCHAR(100),
    FOREIGN KEY (`space_id`) REFERENCES `spaces` (`id`),
    FOREIGN KEY (`parent_id`) REFERENCES `subjects` (`id`)
) ENGINE=InnoDB;

CREATE TABLE `lectures` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `id_origem` INT,
    `name` VARCHAR(100) NOT NULL,
    `created_at` DATETIME,
    `view_count` INT DEFAULT 0,
    `lectureable_type` VARCHAR(100),
    `lectureable_id` INT,
    `subject_id` INT UNSIGNED,
    `lecture_type` VARCHAR(100),
    `cliente` VARCHAR(100),
    FOREIGN KEY (`subject_id`) REFERENCES `subjects` (`id`)
) ENGINE=InnoDB;

CREATE TABLE `users` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `id_origem` INT,
    `created_at` DATETIME,
    `updated_at` DATETIME,
    `last_login_at` DATETIME,
    `birthday` DATE,
    `gender` VARCHAR(100),
    `first_name` VARCHAR(100),
    `last_name` VARCHAR(100),
    `removed` TINYINT(1) DEFAULT 0,
    `login_count` INT DEFAULT 0,
    `last_seen_at` DATETIME,
    `cliente` VARCHAR(100)
) ENGINE=InnoDB;

CREATE TABLE `type_interaction` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `name` VARCHAR(100) NOT NULL,
    `cliente` VARCHAR(100)
) ENGINE=InnoDB;

CREATE TABLE `fat_interaction` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `id_origem` INT,
    `in_response_to_id` INT UNSIGNED,
    `in_response_to_type` VARCHAR(100),
    `created_at` DATETIME,
    `user_id` INT UNSIGNED,
    `struct_interaction_id` INT,
    `struct_interaction_type` VARCHAR(100),
    `interaction_type` VARCHAR(100),
    `type_interaction_id` INT UNSIGNED,
    FOREIGN KEY (`in_response_to_id`) REFERENCES `fat_interaction` (`id`),
    FOREIGN KEY (`user_id`) REFERENCES `users` (`id`),
    FOREIGN KEY (`type_interaction_id`) REFERENCES `type_interaction` (`id`)
) ENGINE=InnoDB;

CREATE TABLE `friendships` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `user_id` INT UNSIGNED,
    `friend_id` INT UNSIGNED,
    `requested_at` DATETIME,
    `accepted_at` DATETIME,
    `status` VARCHAR(100),
    `cliente` VARCHAR(100),
    FOREIGN KEY (`user_id`) REFERENCES `users` (`id`),
    FOREIGN KEY (`friend_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB;

CREATE TABLE `gradebooks` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `structure_id` INT,
    `structure_type` VARCHAR(100),
    `deleted_at` DATETIME,
    `created_at` DATETIME,
    `updated_at` DATETIME,
    `cliente` VARCHAR(100)
) ENGINE=InnoDB;

CREATE TABLE `grade_groups` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `grade_group_id_origem` INT,
    `gradebook_id` INT UNSIGNED,
    `gradebook_id_origem` INT,
    `title` VARCHAR(100),
    `grade_weight` INT,
    `group_type` VARCHAR(100),
    `pass_grade` DECIMAL(5, 2),
    `deleted_at` DATETIME,
    `created_at` DATETIME,
    `updated_at` DATETIME,
    `calc_type` ENUM('sum', 'average', 'weighted'),
    `retake_calc_type` ENUM('sum', 'average', 'weighted', 'replace', 'max'),
    `cliente` VARCHAR(100),
    FOREIGN KEY (`gradebook_id`) REFERENCES `gradebooks` (`id`)
) ENGINE=InnoDB;

CREATE TABLE `assignments` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `id_origem` INT,
    `grade_group_id` INT UNSIGNED,
    `grade_group_id_origem` INT,
    `resource_id` INT,
    `resource_type` VARCHAR(100),
    `title` VARCHAR(100),
    `max_grade` DECIMAL(5, 2),
    `grade_weight` DECIMAL(5, 2),
    `position` INT,
    `open_date` DATETIME,
    `due_date` DATETIME,
    `deleted_at` DATETIME,
    `created_at` DATETIME,
    `updated_at` DATETIME,
    `cliente` VARCHAR(100),
    FOREIGN KEY (`grade_group_id`) REFERENCES `grade_groups` (`id`)
) ENGINE=InnoDB;

CREATE TABLE `fat_assignments` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `id_origem` INT,
    `assignment_id` INT UNSIGNED,
    `user_id` INT UNSIGNED,
    `grade` DECIMAL(5, 2),
    `submitted_at` DATETIME,
    `deleted_at` DATETIME,
    `created_at` DATETIME,
    `updated_at` DATETIME,
    `status` ENUM('assigned', 'submitted', 'pending', 'graded'),
    `cliente` VARCHAR(100),
    FOREIGN KEY (`assignment_id`) REFERENCES `assignments` (`id`),
    FOREIGN KEY (`user_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB;