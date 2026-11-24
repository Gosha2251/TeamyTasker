/*M!999999\- enable the sandbox mode */ 
-- MariaDB dump 10.19-12.2.2-MariaDB, for Win64 (AMD64)
--
-- Host: localhost    Database: team_task_planner
-- ------------------------------------------------------
-- Server version	12.2.2-MariaDB

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*M!100616 SET @OLD_NOTE_VERBOSITY=@@NOTE_VERBOSITY, NOTE_VERBOSITY=0 */;

--
-- Current Database: `team_task_planner`
--

CREATE DATABASE /*!32312 IF NOT EXISTS*/ `team_task_planner` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci */;

USE `team_task_planner`;

--
-- Table structure for table `comments`
--

DROP TABLE IF EXISTS `comments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `comments` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `task_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `text` text NOT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `task_id` (`task_id`),
  KEY `user_id` (`user_id`),
  CONSTRAINT `1` FOREIGN KEY (`task_id`) REFERENCES `tasks` (`id`) ON DELETE CASCADE,
  CONSTRAINT `2` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `comments`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `comments` WRITE;
/*!40000 ALTER TABLE `comments` DISABLE KEYS */;
INSERT INTO `comments` VALUES
(2,7,4,'Pirmais testa komentārs.','2026-11-22 17:56:40'),
(3,7,5,'Ej bekot Paša!!!\r\n:)','2026-11-22 17:58:08'),
(4,8,4,'Ludvig dari ātrāk!','2026-11-22 18:27:46'),
(5,11,2,'Vēlams izdarīt šodienas laikā!','2026-11-23 22:05:15');
/*!40000 ALTER TABLE `comments` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Table structure for table `status`
--

DROP TABLE IF EXISTS `status`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `status` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(50) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `status`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `status` WRITE;
/*!40000 ALTER TABLE `status` DISABLE KEYS */;
INSERT INTO `status` VALUES
(3,'Done'),
(2,'In Progress'),
(1,'New');
/*!40000 ALTER TABLE `status` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Table structure for table `tasks`
--

DROP TABLE IF EXISTS `tasks`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `tasks` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `title` varchar(200) NOT NULL,
  `description` text DEFAULT NULL,
  `status_id` int(11) NOT NULL,
  `assigned_to` int(11) DEFAULT NULL,
  `team_id` int(11) NOT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `status_id` (`status_id`),
  KEY `assigned_to` (`assigned_to`),
  KEY `team_id` (`team_id`),
  CONSTRAINT `1` FOREIGN KEY (`status_id`) REFERENCES `status` (`id`),
  CONSTRAINT `2` FOREIGN KEY (`assigned_to`) REFERENCES `users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `3` FOREIGN KEY (`team_id`) REFERENCES `teams` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=13 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tasks`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `tasks` WRITE;
/*!40000 ALTER TABLE `tasks` DISABLE KEYS */;
INSERT INTO `tasks` VALUES
(1,'Tīkla atjaunošana','Salabot interneta tīklu ofisā',2,NULL,1,'2026-10-21 19:21:25'),
(2,'Datora setup','Sagatavot un iestatīt datoru jaunam lietottājam. Pieslēgt domēnam!',2,NULL,1,'2026-10-21 20:06:44'),
(4,'Tīkla iekārtas demontāža','Demontēt veco tīkla iekārtu un kabeļus.',1,2,1,'2026-11-15 20:11:02'),
(7,'Testa uzdevums','funkcionālais tests procesā',3,NULL,3,'2026-11-22 17:51:37'),
(8,'test 2','darīt kaut ko!',2,5,3,'2026-11-22 18:26:55'),
(10,'Kabeļu kārtošana','Sakārtot vadus pa vajadzigajām atvilknēm.',3,6,2,'2026-11-23 11:48:14'),
(11,'programmatūras atjaunošana','Atjaunot serveru lietojamprogrammatūru un pārstartēt serverus. pārliecināties, ka viss startēja un darbojas korekti.',2,3,2,'2026-11-23 11:51:31'),
(12,'Birokrātija','Sagatavot un nosūtīt atskaiti par projekta virzību.',1,2,2,'2026-11-23 11:52:49');
/*!40000 ALTER TABLE `tasks` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Table structure for table `teams`
--

DROP TABLE IF EXISTS `teams`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `teams` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(100) NOT NULL,
  `owner_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_teams_owner` (`owner_id`),
  CONSTRAINT `fk_teams_owner` FOREIGN KEY (`owner_id`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `teams`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `teams` WRITE;
/*!40000 ALTER TABLE `teams` DISABLE KEYS */;
INSERT INTO `teams` VALUES
(1,'Projekta komanda',NULL),
(2,'Komanda Nr: 1',2),
(3,'Mileniāļi -Komanda Nr:2',4);
/*!40000 ALTER TABLE `teams` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `users` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(100) NOT NULL,
  `email` varchar(150) NOT NULL,
  `password` varchar(255) NOT NULL,
  `team_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `email` (`email`),
  KEY `team_id` (`team_id`),
  CONSTRAINT `1` FOREIGN KEY (`team_id`) REFERENCES `teams` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `users`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `users` WRITE;
/*!40000 ALTER TABLE `users` DISABLE KEYS */;
INSERT INTO `users` VALUES
(2,'Rostislavs','rostya596@example.com','scrypt:32768:8:1$Df7WgbzgOlq3EF5U$6ed50ac0fa297e013812f9750ac2810669e32473e3098de1eaf6bf935e92c139a75c83e7fd9cf18912102103245f3b09ee813b239c0161b3b51040427900b672',2),
(3,'Gustavs','gustavo666@example.com','scrypt:32768:8:1$KHN3ZJIDVzRrpvwu$97df544f7e53e4b8c74025c915a4855730d9cd026f4b3a566b1f4e9a11f3275c3f417c0a241408936cec36dd8341cacb0bfb023adb4de162208de0c59f23b713',2),
(4,'Pavils','pasha2303@example.com','scrypt:32768:8:1$wY4zgvMuWQ9rnceZ$4712697836298c473ad09fd09f0f7a752107cdac6a31f78a20fc7f2abd3a601f73f6d88ce0523d0aec2eec03965eabe9aff52e56491c082897fc7e5a81ede5be',3),
(5,'Ludvigs','ludvigslucifers@example.com','scrypt:32768:8:1$cWuRMX9qH1bM6ki4$447b2da3107999990aed0e4cee07f6bbbaddf7a4b6b6170b845b735b30ca6539d78b49ed541c49bb6471d2ba8992d6661ef0ac0a3791fb9d4983da345a94c7e2',3),
(6,'Žans','zhandos420@example.com','scrypt:32768:8:1$bO0z56bD6amcyU2K$276c96b1daed6bf66219d28ece795748c475b7f1db838242d1cc238e2c840aa1b2fba27866a47c6331998b57ece54ff426291a79e367c5e2e2277d567f7a0164',2);
/*!40000 ALTER TABLE `users` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*M!100616 SET NOTE_VERBOSITY=@OLD_NOTE_VERBOSITY */;

-- Dump completed on 2026-11-24 22:33:04
