/*
================================================================================
  Студент:  Любоградов Павел Александрович
  Вариант:  (28 % 26) + 1 = 3 — «Склад: хранение товаров клиентов на стеллажах» 
  Группа: М26-555
  Подразделение: Институт Интеллектуальных Кибернетических Систем (ИИКС)
  Направление 01.04.02 «Прикладная математика и информатика»
  Образовательная программа «Обработка данных и применение искусственного интеллекта» (Кафедра 42)
================================================================================

  УСЛОВИЕ ЗАДАНИЯ
  ---------------
  В качестве задания обучающимся предлагается рассмотреть формальное описание
  некоторой предметной области, заданное в текстовой форме. Предметная
  область в большинстве случаев взята из общеизвестных тематик для простоты
  понимания текста задания.
  Обучающимся необходимо провести анализ предметной области, выделить
  основные сущности и связи между ними, определить атрибуты сущностей и их
  типы данных, выявить возможные ограничения целостности и значения по
  умолчанию.
  На итоговом шаге все необходимые сущности и связи нужно реализовать в виде
  SQL-скрипта, создающего таблицы на основе команд CREATE TABLE.
  Результатом работы является SQL-код в виде одного файла текстового
  формата.

  Описание предметной области (вариант 3):
  Описание хранящихся на складе товаров. Включает в себя: описание помещений,
  описание стеллажей, описание клиентов, описание товаров, хранящихся на
  стеллажах. Описание помещения состоит из: названия, полезного объёма,
  температурных и влажностных условий. Описание стеллажа состоит из: номера,
  указания помещения, в котором стеллаж находится, количества мест для
  хранения в стеллаже, высоты, ширины и длины одного места, максимальной
  суммарной нагрузки. Описание клиента состоит из: названия юридического лица
  и банковских реквизитов в виде большого текста. Описание товара, хранящегося
  на стеллажах, состоит из: высоты, ширины, длины, веса, даты поступления,
  номера договора, указания, от какого клиента поступил, даты окончания
  договора, температурных и влажностных условий хранения, указания стеллажа,
  и позиции размещения на нём, представляемой в виде целого номера.
  На одном стеллаже могут храниться товары только одного клиента.

================================================================================
  АНАЛИЗ ПРЕДМЕТНОЙ ОБЛАСТИ
================================================================================

  Основные сущности (таблицы)
  ---------------------------
    Помещения  (rooms)      — складские помещения с климатическими условиями;
    Стеллажи   (racks)      — стеллажи, установленные в помещениях;
    Клиенты    (clients)    — юридические лица, сдающие товар на хранение;
    Договоры   (contracts)  — договоры хранения, заключённые с клиентами;
    Товары     (goods)      — единицы товара, размещённые на местах стеллажей.

  Связи
  -----
    Стеллажи  с Помещениями   M:1  обязательная (стеллаж всегда в помещении);
    Стеллажи  с Клиентами     M:1  необязательная (стеллаж закрепляется за
                                   клиентом; свободный стеллаж — без клиента);
    Договоры  с Клиентами     M:1  обязательная;
    Товары    с Договорами    M:1  обязательная;
    Товары    со Стеллажами   M:1  обязательная;
    Товары    с Клиентами     M:1  — «от какого клиента поступил»: реализована
                                   полем goods.client_id, согласованным
                                   с договором составным внешним ключом.

  Единицы измерения (зафиксированы в именах столбцов)
  ---------------------------------------------------
    линейные размеры — метры (_m), точность 1 мм:      numeric(6, 3);
    объём            — кубические метры (_m3):         numeric(10, 2);
    масса, нагрузка  — килограммы (_kg):               numeric(9, 3)/(9, 2);
    температура      — градусы Цельсия (_c), шаг 0,1:  numeric(4, 1);
    влажность        — относительная, % (_pct):        numeric(4, 1).
  Для физических величин выбран тип numeric (точные значения, без ошибок
  округления, присущих real/double precision).

  Температурные и влажностные условия представлены диапазонами
  (минимум/максимум). Для помещения — поддерживаемый в нём режим (обязателен).
  Для товара — требования к хранению; NULL в границе означает «ограничения
  с этой стороны нет» (например, «хранить при температуре не выше +25 °C»:
  temp_min_c = NULL, temp_max_c = 25).

  Ограничения, требующие сравнения строк разных таблиц или агрегатов,
  не выражаются средствами CREATE TABLE (CHECK видит только текущую строку)
  и при развитии проекта реализуются триггерами:
    - номер позиции товара не превышает количества мест стеллажа;
    - габариты товара не превышают размеров места стеллажа;
    - суммарный вес товаров не превышает максимальной нагрузки стеллажа;
    - условия хранения товара совместимы с условиями помещения;
    - дата поступления товара не позже даты окончания договора.

  Границы модели и направления развития
  -------------------------------------
  Строка goods — это физическая единица хранения (грузовое место), а не
  позиция каталога: по условию у товара есть габариты, вес, дата поступления,
  один стеллаж и одна позиция на нём, но нет наименования или артикула.
  Поэтому товар связан с договором как M:1 — у единицы хранения один договор
  и одна дата его окончания; продление договора меняет contracts.end_date,
  перевод товара на новый договор — goods.contract_id.

  Если в требованиях появится идентификатор товара как позиции каталога
  (артикул, наименование), и один и тот же товар сможет поступать от разных
  клиентов и лежать на разных стеллажах, модель разделяется на две сущности:
    products    — справочник товаров: артикул , наименование, типовые
                  габариты, вес, условия хранения;
    stock_items — единицы хранения: товар, договор, клиент,
                  стеллаж, позиция, дата поступления, фактические габариты/вес.
  Связь products — stock_items 1:M; правило «один клиент на стеллаж»
  сохраняется теми же составными внешними ключами, перенесёнными
  в stock_items. Без артикула такое разделение преждевременно.

================================================================================
*/

BEGIN;
 
-- Пересоздаём схему, чтобы скрипт можно было выполнять повторно.
DROP SCHEMA IF EXISTS warehouse CASCADE;
CREATE SCHEMA warehouse;
 
 
-- -----------------------------------------------------------------------------
-- Помещения
-- -----------------------------------------------------------------------------
CREATE TABLE warehouse.rooms
(
    id               integer        GENERATED ALWAYS AS IDENTITY
                                    CONSTRAINT rooms_pk PRIMARY KEY,
    name             varchar(64)    NOT NULL,
    useful_volume_m3 numeric(10, 2) NOT NULL,
    temp_min_c       numeric(4, 1)  NOT NULL,
    temp_max_c       numeric(4, 1)  NOT NULL,
    humidity_min_pct numeric(4, 1)  NOT NULL,
    humidity_max_pct numeric(4, 1)  NOT NULL,
 
    CONSTRAINT rooms_name_uq           UNIQUE (name),
    CONSTRAINT rooms_name_ck           CHECK (btrim(name) <> ''),
    CONSTRAINT rooms_useful_volume_ck  CHECK (useful_volume_m3 > 0),
    CONSTRAINT rooms_temp_bounds_ck    CHECK (temp_min_c BETWEEN -100 AND 100
                                          AND temp_max_c BETWEEN -100 AND 100),
    CONSTRAINT rooms_temp_range_ck     CHECK (temp_min_c <= temp_max_c),
    CONSTRAINT rooms_humidity_bounds_ck CHECK (humidity_min_pct BETWEEN 0 AND 100
                                          AND humidity_max_pct BETWEEN 0 AND 100),
    CONSTRAINT rooms_humidity_range_ck CHECK (humidity_min_pct <= humidity_max_pct)
);
 
 
-- -----------------------------------------------------------------------------
-- Клиенты
-- -----------------------------------------------------------------------------
CREATE TABLE warehouse.clients
(
    id           integer      GENERATED ALWAYS AS IDENTITY
                              CONSTRAINT clients_pk PRIMARY KEY,
    name         varchar(256) NOT NULL,
    bank_details text         NOT NULL,
 
    CONSTRAINT clients_name_uq         UNIQUE (name),
    CONSTRAINT clients_name_ck         CHECK (btrim(name) <> ''),
    CONSTRAINT clients_bank_details_ck CHECK (btrim(bank_details) <> '')
);
 
 
-- -----------------------------------------------------------------------------
-- Стеллажи
-- -----------------------------------------------------------------------------
CREATE TABLE warehouse.racks
(
    id             integer       GENERATED ALWAYS AS IDENTITY
                                 CONSTRAINT racks_pk PRIMARY KEY,
    number         varchar(16)   NOT NULL,  -- маркировка, уникальна в пределах помещения
    room_id        integer       NOT NULL,
    client_id      integer,                 -- закрепление за клиентом; NULL — стеллаж свободен
    places_count   integer       NOT NULL,
    place_height_m numeric(6, 3) NOT NULL,
    place_width_m  numeric(6, 3) NOT NULL,
    place_length_m numeric(6, 3) NOT NULL,
    max_load_kg    numeric(9, 2) NOT NULL,
 
    CONSTRAINT racks_room_number_uq  UNIQUE (room_id, number),
    -- Ключ-цель для составного внешнего ключа из goods (правило «один клиент
    -- на стеллаж»). Внешний ключ может ссылаться только на ключ таблицы.
    CONSTRAINT racks_id_client_uq    UNIQUE (id, client_id),
    CONSTRAINT racks_room_fk         FOREIGN KEY (room_id)
        REFERENCES warehouse.rooms (id)   ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT racks_client_fk       FOREIGN KEY (client_id)
        REFERENCES warehouse.clients (id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT racks_number_ck       CHECK (btrim(number) <> ''),
    CONSTRAINT racks_places_count_ck CHECK (places_count > 0),
    CONSTRAINT racks_place_size_ck   CHECK (place_height_m > 0
                                        AND place_width_m  > 0
                                        AND place_length_m > 0),
    CONSTRAINT racks_max_load_ck     CHECK (max_load_kg > 0)
);
 
 
-- -----------------------------------------------------------------------------
-- Договоры хранения
-- -----------------------------------------------------------------------------
CREATE TABLE warehouse.contracts
(
    id        integer     GENERATED ALWAYS AS IDENTITY
                          CONSTRAINT contracts_pk PRIMARY KEY,
    number    varchar(32) NOT NULL,
    client_id integer     NOT NULL,
    end_date  date        NOT NULL,
 
    CONSTRAINT contracts_number_uq    UNIQUE (number),
    -- Ключ-цель для составного внешнего ключа из goods: клиент товара
    -- обязан совпадать с клиентом договора.
    CONSTRAINT contracts_id_client_uq UNIQUE (id, client_id),
    CONSTRAINT contracts_client_fk    FOREIGN KEY (client_id)
        REFERENCES warehouse.clients (id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT contracts_number_ck    CHECK (btrim(number) <> '')
);
 
 
-- -----------------------------------------------------------------------------
-- Товары, хранящиеся на стеллажах
-- -----------------------------------------------------------------------------
CREATE TABLE warehouse.goods
(
    id               integer       GENERATED ALWAYS AS IDENTITY
                                   CONSTRAINT goods_pk PRIMARY KEY,
    contract_id      integer       NOT NULL,
    client_id        integer       NOT NULL,  -- от кого поступил; согласован с договором и стеллажом
    rack_id          integer       NOT NULL,
    position_no      integer       NOT NULL,  -- номер места на стеллаже, начиная с 1
    height_m         numeric(6, 3) NOT NULL,
    width_m          numeric(6, 3) NOT NULL,
    length_m         numeric(6, 3) NOT NULL,
    weight_kg        numeric(9, 3) NOT NULL,
    receipt_date     date          NOT NULL DEFAULT CURRENT_DATE,
    -- Условия хранения товара: NULL в границе — ограничения с этой стороны нет.
    temp_min_c       numeric(4, 1),
    temp_max_c       numeric(4, 1),
    humidity_min_pct numeric(4, 1),
    humidity_max_pct numeric(4, 1),
 
    -- На одной позиции стеллажа размещается один товар.
    CONSTRAINT goods_rack_position_uq   UNIQUE (rack_id, position_no),
    -- Клиент товара = клиент договора.
    CONSTRAINT goods_contract_client_fk FOREIGN KEY (contract_id, client_id)
        REFERENCES warehouse.contracts (id, client_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    -- Клиент товара = клиент, за которым закреплён стеллаж
    -- (на одном стеллаже — товары только одного клиента).
    CONSTRAINT goods_rack_client_fk     FOREIGN KEY (rack_id, client_id)
        REFERENCES warehouse.racks (id, client_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT goods_position_no_ck     CHECK (position_no >= 1),
    CONSTRAINT goods_size_ck            CHECK (height_m > 0
                                           AND width_m  > 0
                                           AND length_m > 0),
    CONSTRAINT goods_weight_ck          CHECK (weight_kg > 0),
    CONSTRAINT goods_temp_bounds_ck     CHECK (temp_min_c BETWEEN -100 AND 100
                                           AND temp_max_c BETWEEN -100 AND 100),
    CONSTRAINT goods_temp_range_ck      CHECK (temp_min_c <= temp_max_c),
    CONSTRAINT goods_humidity_bounds_ck CHECK (humidity_min_pct BETWEEN 0 AND 100
                                           AND humidity_max_pct BETWEEN 0 AND 100),
    CONSTRAINT goods_humidity_range_ck  CHECK (humidity_min_pct <= humidity_max_pct)
);
 

COMMIT;
