# Admin System — Product Requirements Document (PRD)

## Platform Context

This document defines the requirements for the **Admin Portal** — the
internal management interface for a single tenant (restaurant) on the
Multi-Tenant Food Ordering Platform.

This PRD describes `Tenant #1` **(Pizza Palace)** and serves as the
reference implementation for the platform's admin portal. All subsequent
tenants will use the same portal — their specific product catalogs,
categories, and branding are configured through tenant settings, not
through new development.

This PRD covers the admin portal only. The following are out of scope
for this document and will be covered in separate PRDs:

- Customer-facing ordering website (`apps/web`)
- Platform super-admin portal (`apps/super-admin`)

## Tenant Context

This web application serves as a comprehensive administrative management system for a pizza delivery business powered by Supabase backend, designed for internal staff and authorized personnel. The platform provides centralized control over key business operations, including:

- **Customer Management**: Maintain and organize customer information and records
- **Order Management**: Track, process, and manage customer orders throughout the fulfillment lifecycle
- **Address Management**: Store and manage delivery and billing addresses
- **Product Catalog**: Administer pizza offerings and product inventory
- **Product Categorization**: Organize products by dietary preferences (Vegetarian, Non-Vegetarian, Vegan)
- **Additional Features**: Extended administrative functionality and operational tools

**Access Level**: Restricted to authorized administrators and staff members only. This is a backend management interface and is not accessible to end customers.

**Purpose**: To streamline internal operations and provide staff with the necessary tools to efficiently manage all aspects of the pizza delivery business.

## Table of Contents

- [1. Project Overview](#1-project-overview)
- [2. User Roles](#2-user-roles)
- [3. Main Layout Structure](#3-main-layout-structure)
- [4. Dashboard](#4-dashboard)
- [5. Catalog Module](#5-catalog-module)
  - [5.1 Categories](#51-categories)
  - [5.2 Products](#52-products)
    - [5.2.1 Product Variants](#521-product-variants)
    - [5.2.2 Product Status](#522-product-status)
    - [5.2.3 Product Features](#523-product-features)
- [6. Customers Module](#6-customers-module)
  - [6.1 Customer Data](#61-customer-data)
  - [6.2 Customer Addresses](#62-customer-addresses)
  - [6.3 Customer Features](#63-customer-features)
- [7. Orders Module](#7-orders-module)
  - [7.1 Order Data](#71-order-data)
  - [7.2 Order Status Workflow](#72-order-status-workflow)
  - [7.3 Payment Status](#73-payment-status)
  - [7.4 Order Features](#74-order-features)
- [8. Addresses Module](#8-addresses-module)
- [9. Sales / Analytics](#9-sales--analytics)
  - [9.1 Time Filters](#91-time-filters)
- [10. Settings Module](#10-settings-module)
  - [10.1 Security Settings](#101-security-settings)
  - [10.2 Branding](#102-branding)
  - [10.3 Language Management](#103-language-management)
  - [10.4 Email Templates](#104-email-templates)
  - [10.5 Payment Methods](#105-payment-methods)
- [11. Audit Logs](#11-audit-logs)
- [12. Notifications](#12-notifications)
- [13. Data Backup](#13-data-backup)
- [14. Technical Architecture](#14-technical-architecture)
- [15. Performance & Data Handling](#15-performance--data-handling)
- [16. Accessibility](#16-accessibility)
- [17. Evaluation](#17-evaluation)

## 1. Project Overview

The **Pizza Shop Administrator Portal** is a web-based dashboard used by shop administrators and staff to manage all operational aspects of the pizza business from a single interface. This project focuses on building the frontend for the administrator portal. The backend will be built using Supabase.

### High level Modules

This structure is **very clean and scalable**.

| Module    | Purpose                             |
| --------- | ----------------------------------- |
| Dashboard | Business overview                   |
| Customers | Manage customer records             |
| Catalog   | Manage pizzas/products & categories |
| Orders    | Manage incoming orders              |
| Addresses | Manage customer addresses           |
| Sales     | Business analytics                  |
| Settings  | Configure system behavior           |

The portal will allow staff to manage:

- Orders
- Customers
- Products (Pizzas)
- Product Categories
- Customer Addresses
- Sales analytics
- System settings
- Staff accounts

This system acts as the **internal management interface** for the pizza shop.

Customers will **not access this portal**.

Customers interact with the **customer-facing website**, while administrators manage business operations through this dashboard.

## 2. User Roles

The system supports **multiple staff accounts with role-based access control (RBAC)**.

### 2.1. Admin

Full access to the system.

Permissions:

- Manage staff accounts

- Access all modules

- Manage settings

- Access sales analytics

- View audit logs

- Manage products, orders, customers, addresses

---

### 2.2. Manager

Limited administrative permissions.

Permissions:

- Manage orders

- Manage customers

- Manage products

- View dashboard

- View addresses

Restrictions:

- Cannot access **Settings**

- Cannot manage **staff accounts**

- Cannot access **Sales analytics**

---

### 2.3. Staff

Operational role.

Permissions:

- View and manage orders

- Manage customers

- View products

Restrictions:

- Cannot access **Settings**

- Cannot access **Sales**

- Cannot manage **staff accounts**

## 3. Main Layout Structure

The administrator portal consists of two primary UI sections.

### 3.1 Sidebar Navigation

A **collapsible sidebar** will provide navigation across the system.

Default state: **Expanded**

Menu items:

```sh
Dashboard
Customers
Catalog
   - Categories
   - Products
Orders
Addresses
Sales
Settings
Audit Logs
```

Behavior:

- Sidebar remains **fixed**

- Supports **collapsed state**

- Displays icons in collapsed mode

---

### 3.2 Top Navigation Bar

The top navigation bar provides global system actions.

Elements:

- Application logo

- Language selector

- User profile

- Sign in / sign out

Supported languages:

```sh
English
Czech
German
```

## 4. Dashboard

The dashboard provides a **business overview**.

Displayed metrics:

```sh
Today's Orders
Today's Revenue
Top Selling Pizzas
Low Stock Products
Recent Orders
```

Widgets may include:

- Orders summary

- Revenue summary

- Best selling products

- Low stock alerts

- Recent order activity

## 5. Catalog Module

The catalog module manages products and product categories. For this tenant, products are pizzas. **Future tenants may sell any type of product.**

Structure:

```sh
Catalog
   Categories
   Products
```

---

### 5.1 Categories

Categories organize products. This tenant uses: Veg, Non-Veg, Vegan, Special. **Categories are configured per tenant.**

Example:

```sh
Veg
Non-Veg
Vegan
Special
```

Features:

- Create category

- Edit category

- Disable category

- Delete category

- Search categories

- Filter categories

- Sort categories

---

### 5.2 Products

Products represent pizzas available for sale.

Each product includes:

```sh
Name
Description
Category
Image
Status
Variants
```

Example:

```sh
Margherita Pizza
Category: Veg
Description: Classic cheese pizza
Image
```

---

#### 5.2.1 Product Variants

Each pizza may include multiple size variants.

Example:

```sh
Margherita

Small
Medium
Large
```

Each variant includes:

```sh
Variant Name
Price
Stock status
```

---

#### 5.2.2 Product Status

Products may have the following states:

```sh
Active
Out of Stock
Disabled
```

---

#### 5.2.3 Product Features

Features:

- Create product
- Edit product
- Disable product
- Delete product
- Upload product image
- Image preview
- Filter products
- Sort products
- Pagination
- Export product table

Export formats:

```sh
CSV
Excel
```

## 6. Customers Module

This module manages customer records.

Customer sources:

```sh
Customer website
Phone order
Walk-in order
Admin created
```

---

### 6.1 Customer Data

Customer profile includes:

```sh
First name
Last name
Gender
Email
Phone number
Profile picture
Account status
```

---

### 6.2 Customer Addresses

Each customer can store **up to 4 addresses**.

Example:

```sh
Home
Work
Other
```

---

### 6.3 Customer Features

- Create customer

- Edit customer

- View customer details

- Enable/Disable customer

- Delete customer

- Manage customer addresses

- Search customers

- Filter customers

- Sort customers

- Pagination

- Export table (CSV/Excel)

## 7. Orders Module

The Orders module manages all incoming and manually created orders.

Orders may originate from:

```sh
Customer website
Phone order
Walk-in order
Admin created
```

---

### 7.1 Order Data

Each order contains:

```sh
Order ID
Customer
Order items
Address
Payment method
Payment status
Order status
Tracking number
Notes
```

---

### 7.2 Order Status Workflow

Orders move through the following states:

```sh
Pending
Preparing
Ready
Out for Delivery
Completed
Cancelled
```

---

### 7.3 Payment Status

Payment states:

```sh
Pending
Paid
Failed
Refunded
```

---

### 7.4 Order Features

- Create order manually

- Edit order items

- Update order status

- Update tracking information

- Modify delivery address

- Generate invoice PDF

- Filter orders

- Sort orders

- Pagination

- Export orders table

Export formats:

```sh
CSV
Excel
```

## 8. Addresses Module

Displays all addresses across customers.

Features:

- View all addresses

- Edit address

- Delete address

- Filter addresses

- Sort addresses

- Pagination

- Export address data

## 9. Sales / Analytics

The sales module provides business insights.

Analytics available:

```sh
Revenue by day
Revenue by product
Revenue by category
Orders per day
```

---

### 9.1 Time Filters

Users can view analytics by:

```sh
Daily
Weekly
Monthly
Yearly
```

## 10. Settings Module

The settings module manages configuration for this tenant. Settings are stored per-tenant and include branding, language, VAT rate, delivery fee, and payment methods.

### 10.1 Security Settings

Features:

```sh
Limit login attempts
Whitelist IP addresses
Blacklist IP addresses
```

---

### 10.2 Branding

Admins can update:

```sh
Application logo
Application title
```

---

### 10.3 Language Management

Supported languages:

```sh
English
Czech
German
```

Admins can configure default language.

---

### 10.4 Email Templates

System emails include:

```sh
Order confirmation
Invoice
Incomplete payment notification
Account creation
Password reset
```

---

### 10.5 Payment Methods

Supported payment methods:

```sh
Visa / Credit Card
Cash on delivery
```

## 11. Audit Logs

The system records administrative actions.

Example logs:

```sh
Admin created product
Admin edited order
Admin deleted customer
Admin changed settings
```

Audit logs include:

```sh
User
Action
Timestamp
Affected entity
```

## 12. Notifications

The system provides operational alerts.

Examples:

```sh
New order received
Low stock products
Failed payments
```

## 13. Data Backup

The system must support regular data backups.

Backups may include:

```sh
Database
Product images
System settings
```

## 14. Technical Architecture

Backend:

```sh
Supabase
```

Services used:

```sh
Supabase Database
Supabase Storage
Supabase Authentication
Supabase REST APIs
```

Image storage:

```sh
Supabase Storage
```

## 15. Performance & Data Handling

Tables must support:

```sh
Filtering
Sorting
Pagination
Export
Large datasets
```

All tables should be optimized for **large data volumes**.

## 16. Accessibility

Admin UI should support accessibility improvements:

Examples:

```sh
Keyboard navigation
ARIA roles
Screen reader support
Color contrast
```

## 17. Evaluation

This is already a **very strong real-world admin system**.

You are essentially building something similar to:

- Magento Admin

- Shopify Admin

- Stripe Dashboard

## 18. Changelog

| Version | Date | Change |
|---|---|---|
| 1.0 | 2026-03-18 | Initial requirements finalized for Pizza Palace Praha |
| 1.1 | 2026-03-23 | Platform context section added — this PRD covers Tenant #1 of the Multi-Tenant Food Ordering Platform |
| 1.1 | 2026-03-23 | Catalog section updated — products are tenant-generic, not pizza-specific at the platform level |
| 1.1 | 2026-03-23 | Settings section updated — settings are per-tenant, stored in `tenants.settings` jsonb |
