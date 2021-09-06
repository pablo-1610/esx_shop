CREATE TABLE `shop_items` (
  `item_id` int(11) NOT NULL,
  `item_name` varchar(255) NOT NULL,
  `category_name` varchar(255) NOT NULL,
  `item_price` int(11) NOT NULL,
  `item_max` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

ALTER TABLE `shop_items`
  ADD PRIMARY KEY (`item_id`);

ALTER TABLE `shop_items`
  MODIFY `item_id` int(11) NOT NULL AUTO_INCREMENT;
COMMIT;

CREATE TABLE `shop_categories` (
  `category_id` int(11) NOT NULL,
  `category_name` varchar(255) NOT NULL,
  `category_label` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

ALTER TABLE `shop_categories`
  ADD PRIMARY KEY (`category_id`),
  ADD UNIQUE KEY `category_name` (`category_name`);

ALTER TABLE `shop_categories`
  MODIFY `category_id` int(11) NOT NULL AUTO_INCREMENT;
COMMIT;