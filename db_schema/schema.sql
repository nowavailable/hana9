-- MySQL dump 10.13  Distrib 5.6.37, for Linux (x86_64)
--
-- Host: 192.168.99.1    Database: hana9_test
-- ------------------------------------------------------
-- Server version	5.6.37-log

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `cities`
--

DROP TABLE IF EXISTS `cities`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `cities` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `label` varchar(255) NOT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `cities`
--

LOCK TABLES `cities` WRITE;
/*!40000 ALTER TABLE `cities` DISABLE KEYS */;
/*!40000 ALTER TABLE `cities` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `cities_shops`
--

DROP TABLE IF EXISTS `cities_shops`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `cities_shops` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `shop_id` bigint(20) NOT NULL,
  `city_id` bigint(20) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_cities_shops_on_shop_id_and_city_id` (`shop_id`,`city_id`),
  KEY `index_cities_shops_on_city_id` (`city_id`),
  KEY `index_cities_shops_on_shop_id` (`shop_id`),
  CONSTRAINT `fk_rails_824c003bd3` FOREIGN KEY (`shop_id`) REFERENCES `shops` (`id`),
  CONSTRAINT `fk_rails_84dbcbae40` FOREIGN KEY (`city_id`) REFERENCES `cities` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `cities_shops`
--

LOCK TABLES `cities_shops` WRITE;
/*!40000 ALTER TABLE `cities_shops` DISABLE KEYS */;
/*!40000 ALTER TABLE `cities_shops` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `merchandises`
--

DROP TABLE IF EXISTS `merchandises`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `merchandises` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `label` varchar(255) NOT NULL,
  `price` int(11) NOT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `merchandises`
--

LOCK TABLES `merchandises` WRITE;
/*!40000 ALTER TABLE `merchandises` DISABLE KEYS */;
/*!40000 ALTER TABLE `merchandises` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `order_change_histories`
--

DROP TABLE IF EXISTS `order_change_histories`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `order_change_histories` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `order_id` bigint(20) NOT NULL,
  `order_code` varchar(255) NOT NULL,
  `ordered_at` datetime NOT NULL,
  `created_at` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `index_order_change_histories_on_order_id` (`order_id`),
  CONSTRAINT `fk_rails_3d559e17b5` FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `order_change_histories`
--

LOCK TABLES `order_change_histories` WRITE;
/*!40000 ALTER TABLE `order_change_histories` DISABLE KEYS */;
/*!40000 ALTER TABLE `order_change_histories` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `order_detail_change_histories`
--

DROP TABLE IF EXISTS `order_detail_change_histories`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `order_detail_change_histories` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `order_change_history_id` bigint(20) NOT NULL,
  `previous_order_detail_id` int(11) NOT NULL,
  `seq_code` varchar(255) NOT NULL,
  `merchandise_id` bigint(20) NOT NULL,
  `expected_date` date NOT NULL,
  `quantity` int(11) NOT NULL,
  `city_id` bigint(20) NOT NULL,
  `created_at` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `index_order_detail_change_histories_on_order_change_history_id` (`order_change_history_id`),
  KEY `index_order_detail_change_histories_on_merchandise_id` (`merchandise_id`),
  KEY `index_order_detail_change_histories_on_city_id` (`city_id`),
  CONSTRAINT `fk_rails_05d457f3e9` FOREIGN KEY (`city_id`) REFERENCES `cities` (`id`),
  CONSTRAINT `fk_rails_0bc7c37296` FOREIGN KEY (`merchandise_id`) REFERENCES `merchandises` (`id`),
  CONSTRAINT `fk_rails_0fce5a0cdd` FOREIGN KEY (`order_change_history_id`) REFERENCES `order_change_histories` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `order_detail_change_histories`
--

LOCK TABLES `order_detail_change_histories` WRITE;
/*!40000 ALTER TABLE `order_detail_change_histories` DISABLE KEYS */;
/*!40000 ALTER TABLE `order_detail_change_histories` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `order_details`
--

DROP TABLE IF EXISTS `order_details`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `order_details` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `seq_code` varchar(255) NOT NULL,
  `order_id` bigint(20) NOT NULL,
  `merchandise_id` bigint(20) NOT NULL,
  `expected_date` date NOT NULL,
  `quantity` int(11) NOT NULL,
  `city_id` bigint(20) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_order_details_on_seq_code_and_order_id_and_merchandise_id` (`seq_code`,`order_id`,`merchandise_id`),
  KEY `index_order_details_on_city_id` (`city_id`),
  KEY `index_order_details_on_merchandise_id` (`merchandise_id`),
  KEY `index_order_details_on_order_id` (`order_id`),
  KEY `index_order_details_on_expected_date` (`expected_date`),
  CONSTRAINT `fk_rails_520ffd0a7d` FOREIGN KEY (`merchandise_id`) REFERENCES `merchandises` (`id`),
  CONSTRAINT `fk_rails_9399183836` FOREIGN KEY (`city_id`) REFERENCES `cities` (`id`),
  CONSTRAINT `fk_rails_e5976611fd` FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `order_details`
--

LOCK TABLES `order_details` WRITE;
/*!40000 ALTER TABLE `order_details` DISABLE KEYS */;
/*!40000 ALTER TABLE `order_details` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `orders`
--

DROP TABLE IF EXISTS `orders`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `orders` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `order_code` varchar(255) NOT NULL,
  `ordered_at` datetime NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_orders_on_order_code` (`order_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `orders`
--

LOCK TABLES `orders` WRITE;
/*!40000 ALTER TABLE `orders` DISABLE KEYS */;
/*!40000 ALTER TABLE `orders` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `requested_deliveries`
--

DROP TABLE IF EXISTS `requested_deliveries`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `requested_deliveries` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `shop_id` bigint(20) NOT NULL,
  `order_code` varchar(255) NOT NULL,
  `order_detail_id` bigint(20) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_requested_deliveries_on_shop_id_and_order_detail_id` (`shop_id`,`order_detail_id`),
  KEY `index_requested_deliveries_on_order_code` (`order_code`),
  KEY `index_requested_deliveries_on_order_detail_id` (`order_detail_id`),
  KEY `index_requested_deliveries_on_shop_id` (`shop_id`),
  CONSTRAINT `fk_rails_86beaa131a` FOREIGN KEY (`shop_id`) REFERENCES `shops` (`id`),
  CONSTRAINT `fk_rails_f3b17b7e3f` FOREIGN KEY (`order_detail_id`) REFERENCES `order_details` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `requested_deliveries`
--

LOCK TABLES `requested_deliveries` WRITE;
/*!40000 ALTER TABLE `requested_deliveries` DISABLE KEYS */;
/*!40000 ALTER TABLE `requested_deliveries` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `rule_for_ships`
--

DROP TABLE IF EXISTS `rule_for_ships`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `rule_for_ships` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `shop_id` bigint(20) NOT NULL,
  `merchandise_id` bigint(20) NOT NULL,
  `interval_day` int(11) NOT NULL,
  `quantity_limit` int(11) NOT NULL,
  `quantity_available` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_rule_for_ships_on_shop_id_and_merchandise_id` (`shop_id`,`merchandise_id`),
  KEY `index_rule_for_ships_on_merchandise_id` (`merchandise_id`),
  KEY `index_rule_for_ships_on_shop_id` (`shop_id`),
  CONSTRAINT `fk_rails_1f466219bf` FOREIGN KEY (`shop_id`) REFERENCES `shops` (`id`),
  CONSTRAINT `fk_rails_65a125f816` FOREIGN KEY (`merchandise_id`) REFERENCES `merchandises` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `rule_for_ships`
--

LOCK TABLES `rule_for_ships` WRITE;
/*!40000 ALTER TABLE `rule_for_ships` DISABLE KEYS */;
/*!40000 ALTER TABLE `rule_for_ships` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ship_limits`
--

DROP TABLE IF EXISTS `ship_limits`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `ship_limits` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `shop_id` bigint(20) NOT NULL,
  `expected_date` date NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_ship_limits_on_shop_id_and_expected_date` (`shop_id`,`expected_date`),
  KEY `index_ship_limits_on_shop_id` (`shop_id`),
  CONSTRAINT `fk_rails_bf9578494f` FOREIGN KEY (`shop_id`) REFERENCES `shops` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ship_limits`
--

LOCK TABLES `ship_limits` WRITE;
/*!40000 ALTER TABLE `ship_limits` DISABLE KEYS */;
/*!40000 ALTER TABLE `ship_limits` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `shops`
--

DROP TABLE IF EXISTS `shops`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `shops` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `code` varchar(255) NOT NULL,
  `label` varchar(255) NOT NULL,
  `delivery_limit_per_day` varchar(255) NOT NULL,
  `mergin` varchar(255) NOT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_shops_on_code` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `shops`
--

LOCK TABLES `shops` WRITE;
/*!40000 ALTER TABLE `shops` DISABLE KEYS */;
/*!40000 ALTER TABLE `shops` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2017-11-26 21:53:38
