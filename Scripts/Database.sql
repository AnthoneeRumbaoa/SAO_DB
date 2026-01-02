-- MySQL Workbench Forward Engineering

SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';

-- -----------------------------------------------------
-- Schema SAO_DB
-- -----------------------------------------------------

-- -----------------------------------------------------
-- Schema SAO_DB
-- -----------------------------------------------------
CREATE SCHEMA IF NOT EXISTS `SAO_DB` DEFAULT CHARACTER SET utf8 ;
USE `SAO_DB` ;

-- -----------------------------------------------------
-- Table `SAO_DB`.`PROGRAM`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `SAO_DB`.`PROGRAM` (
  `ID` INT NOT NULL AUTO_INCREMENT,
  `programName` VARCHAR(45) NOT NULL,
  `Created_At` DATETIME NOT NULL,
  `Updated_At` DATETIME NOT NULL,
  `Created_By` VARCHAR(45) NOT NULL,
  `Updated_By` VARCHAR(45) NOT NULL,
  PRIMARY KEY (`ID`),
  UNIQUE INDEX `programName_UNIQUE` (`programName` ASC) VISIBLE)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `SAO_DB`.`STUDENT`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `SAO_DB`.`STUDENT` (
  `ID_Number` VARCHAR(8) NOT NULL,
  `lastName` VARCHAR(30) NOT NULL,
  `firstName` VARCHAR(30) NOT NULL,
  `Section` VARCHAR(45) NOT NULL,
  `Year` INT NOT NULL,
  `Created_At` DATETIME NOT NULL,
  `Updated_At` DATETIME NOT NULL,
  `Created_By` VARCHAR(45) NOT NULL,
  `Updated_By` VARCHAR(45) NOT NULL,
  `PROGRAM_ID` INT NOT NULL,
  PRIMARY KEY (`ID_Number`),
  INDEX `fk_STUDENT_PROGRAM1_idx` (`PROGRAM_ID` ASC) VISIBLE,
  CONSTRAINT `fk_STUDENT_PROGRAM1`
    FOREIGN KEY (`PROGRAM_ID`)
    REFERENCES `SAO_DB`.`PROGRAM` (`ID`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `SAO_DB`.`COURSE`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `SAO_DB`.`COURSE` (
  `ID` INT NOT NULL AUTO_INCREMENT,
  `Code` VARCHAR(7) NOT NULL,
  `Name` VARCHAR(50) NOT NULL,
  `Created_At` DATETIME NOT NULL,
  `Updated_At` DATETIME NOT NULL,
  `Created_By` VARCHAR(45) NOT NULL,
  `Updated_By` VARCHAR(45) NOT NULL,
  `PROGRAM_ID` INT NOT NULL,
  PRIMARY KEY (`ID`),
  INDEX `fk_COURSE_PROGRAM1_idx` (`PROGRAM_ID` ASC) VISIBLE,
  UNIQUE INDEX `Code_UNIQUE` (`Code` ASC) VISIBLE,
  UNIQUE INDEX `Name_UNIQUE` (`Name` ASC) VISIBLE,
  CONSTRAINT `fk_COURSE_PROGRAM1`
    FOREIGN KEY (`PROGRAM_ID`)
    REFERENCES `SAO_DB`.`PROGRAM` (`ID`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `SAO_DB`.`ENROLLMENT`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `SAO_DB`.`ENROLLMENT` (
  `ID` INT NOT NULL AUTO_INCREMENT,
  `Units` INT NOT NULL,
  `Grade` VARCHAR(9) NOT NULL,
  `Status` ENUM('Passed', 'Failed', 'Active') NOT NULL,
  `Created_At` DATETIME NOT NULL,
  `Updated_At` DATETIME NOT NULL,
  `Created_By` VARCHAR(45) NOT NULL,
  `Updated_By` VARCHAR(45) NOT NULL,
  `COURSE_ID` INT NOT NULL,
  `STUDENT_ID` VARCHAR(8) NOT NULL,
  PRIMARY KEY (`ID`),
  INDEX `fk_ENROLLMENT_COURSE1_idx` (`COURSE_ID` ASC) VISIBLE,
  INDEX `fk_ENROLLMENT_STUDENT1_idx` (`STUDENT_ID` ASC) VISIBLE,
  CONSTRAINT `fk_ENROLLMENT_COURSE1`
    FOREIGN KEY (`COURSE_ID`)
    REFERENCES `SAO_DB`.`COURSE` (`ID`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_ENROLLMENT_STUDENT1`
    FOREIGN KEY (`STUDENT_ID`)
    REFERENCES `SAO_DB`.`STUDENT` (`ID_Number`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `SAO_DB`.`COURSE_PREREQUISITE`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `SAO_DB`.`COURSE_PREREQUISITE` (
  `PREREQUISITE_ID` INT NOT NULL,
  `COURSE_ID` INT NOT NULL,
  `Created_At` DATETIME NOT NULL,
  `Updated_At` DATETIME NOT NULL,
  `Created_By` VARCHAR(45) NOT NULL,
  `Updated_By` VARCHAR(45) NOT NULL,
  PRIMARY KEY (`PREREQUISITE_ID`, `COURSE_ID`),
  INDEX `fk_COURSE_PREREQUISITE_COURSE1_idx` (`COURSE_ID` ASC) VISIBLE,
  CONSTRAINT `fk_PREREQUISITE_COURSE`
    FOREIGN KEY (`PREREQUISITE_ID`)
    REFERENCES `SAO_DB`.`COURSE` (`ID`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_PARENT_COURSE`
    FOREIGN KEY (`COURSE_ID`)
    REFERENCES `SAO_DB`.`COURSE` (`ID`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;
