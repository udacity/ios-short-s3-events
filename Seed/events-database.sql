-- MySQL dump 10.13  Distrib 5.7.19, for Linux (x86_64)
--
-- Host: 172.17.0.2    Database: game_night
-- ------------------------------------------------------
-- Server version	5.7.19

-- MUST SET 40101 to see emoji

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

ALTER DATABASE `game_night` CHARACTER SET utf8mb4 COLLATE utf8mb4_bin;

--
-- Table structure for table `event_games`
--

DROP TABLE IF EXISTS `event_games`;

CREATE TABLE `event_games` (
  `id` int(6) unsigned NOT NULL AUTO_INCREMENT,
  `activity_id` int(6) unsigned NOT NULL,
  `event_id` int(6) unsigned NOT NULL,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4;

ALTER TABLE `event_games` CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_bin;

--
-- Dumping data for table `event_games`
--

LOCK TABLES `event_games` WRITE;
/*!40000 ALTER TABLE `event_games` DISABLE KEYS */;
INSERT INTO `event_games` VALUES
(1,6,1,'2017-07-24 20:43:51','2017-07-24 20:43:51'),
(2,5,1,'2017-07-24 20:43:51','2017-07-24 20:43:51'),
(3,4,2,'2017-07-24 20:43:51','2017-07-24 20:43:51'),
(4,6,2,'2017-07-24 20:43:51','2017-07-24 20:43:51');
/*!40000 ALTER TABLE `event_games` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `events`
--

DROP TABLE IF EXISTS `events`;

CREATE TABLE `events` (
  `id` int(6) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(50) NOT NULL,
  `emoji` varchar(25) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL,
  `description` text,
  `host` int(6) unsigned NOT NULL,
  `start_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `location` varchar(255) DEFAULT NULL,
  `latitude` double DEFAULT NULL,
  `longitude` double DEFAULT NULL,
  `is_public` tinyint(1) NOT NULL,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4;

ALTER TABLE `events` CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_bin;

--
-- Dumping data for table `events`
--

LOCK TABLES `events` WRITE;
/*!40000 ALTER TABLE `events` DISABLE KEYS */;
INSERT INTO `events` VALUES
(1,'Always Look On the Bright Side of the Planet Earth','🔥','Its game night! Lets play some games!',1,'2017-08-01 14:53:25','San Francisco',37.7749,-122.4194,1,'2017-08-01 14:53:25','2017-07-24 20:43:51'),
(2,'Event 2','🕹','Another event description',1,'2017-08-01 14:54:14','Huntsville',34.7304,-86.5861,1,'2017-08-01 14:54:14','2017-07-24 20:43:51'),
(3,'Event 3','🔑','Who Did It?',1,'2017-08-01 14:54:14','London, UK',51.5074,-0.1278,1,'2017-08-01 14:54:14','2017-07-24 20:43:51'),
(4,'Event 4','🏖','Board Games by the Beach',1,'2017-08-01 14:54:14','Los Angeles, CA',34.0522,-118.2437,1,'2017-08-01 14:54:14','2017-07-24 20:43:51');
/*!40000 ALTER TABLE `events` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Create stored procedure for calculating distance
--

DELIMITER //
CREATE PROCEDURE events_within_miles_from_location
(`location_latitude` double, `location_longitude` double, `miles` int)
BEGIN
  SELECT id, ( 3959 * acos( cos( radians( location_latitude ) ) * cos( radians( latitude ) ) * cos( radians( longitude ) - radians( location_longitude ) ) + sin( radians( location_latitude ) ) * sin(radians(latitude)) ) ) AS distance
  FROM events
  HAVING distance < miles
  ORDER BY distance;
END //
DELIMITER ;

--
-- Table structure for table `rsvps`
--

DROP TABLE IF EXISTS `rsvps`;

CREATE TABLE `rsvps` (
  `id` int(6) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` varchar(50) NOT NULL,
  `event_id` int(6) unsigned NOT NULL,
  `accepted` tinyint(1) DEFAULT NULL,
  `comment` varchar(255) DEFAULT NULL,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `rsvps`
--

LOCK TABLES `rsvps` WRITE;
/*!40000 ALTER TABLE `rsvps` DISABLE KEYS */;
INSERT INTO `rsvps` VALUES
(1,'1',1,1,'I coming!','2017-07-24 20:43:51','2017-07-24 20:43:51'),
(2,'2',1,0,'Sorry, maybe next time.','2017-07-24 20:43:51','2017-07-24 20:43:51');
/*!40000 ALTER TABLE `rsvps` ENABLE KEYS */;
UNLOCK TABLES;

/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;
/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2017-08-01 14:57:24
