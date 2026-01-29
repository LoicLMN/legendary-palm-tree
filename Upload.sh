#!/bin/bash

# Script complet de génération de l’architecture Clean Code React/React Native

# Usage: bash generate-react-architecture.sh [project-path]

PROJECT_PATH=”${1:-.}”

echo “📁 Création de l’architecture React/React Native…”

# ============ DOSSIERS ============

mkdir -p “$PROJECT_PATH/src/features/core/domain/entities”
mkdir -p “$PROJECT_PATH/src/features/core/domain/repositories”
mkdir -p “$PROJECT_PATH/src/features/core/infrastructure/http”
mkdir -p “$PROJECT_PATH/src/features/core/infrastructure/repositories”
mkdir -p “$PROJECT_PATH/src/features/core/store”

mkdir -p “$PROJECT_PATH/src/features/product/domain/use-cases/{GetAllProducts,GetProduct,SearchProducts,CreateProduct,UpdateProduct}”
mkdir -p “$PROJECT_PATH/src/features/product/presentation/components/{product-list,product-detail,product-filter}”
mkdir -p “$PROJECT_PATH/src/features/product/presentation/pages”

mkdir -p “$PROJECT_PATH/src/features/cart/domain/use-cases/{GetCart,AddToCart,RemoveFromCart,UpdateCart}”
mkdir -p “$PROJECT_PATH/src/features/cart/presentation/components/cart-widget”
mkdir -p “$PROJECT_PATH/src/features/cart/presentation/pages”

mkdir -p “$PROJECT_PATH/src/features/order/domain/use-cases/{GetOrders,CreateOrder,UpdateOrderStatus}”
mkdir -p “$PROJECT_PATH/src/features/order/presentation/pages”

mkdir -p “$PROJECT_PATH/src/features/shared/components/{header,footer,sidebar}”
mkdir -p “$PROJECT_PATH/src/features/shared/hooks”
mkdir -p “$PROJECT_PATH/src/features/shared/utils/{validators,formatters,helpers}”
mkdir -p “$PROJECT_PATH/src/features/shared/types”

mkdir -p “$PROJECT_PATH/src/app/layouts”
mkdir -p “$PROJECT_PATH/.ai/features”
mkdir -p “$PROJECT_PATH/.ai/contexts”

echo “📝 Création des fichiers…”

# ============ CORE - ENTITIES ============

cat > “$PROJECT_PATH/src/features/core/domain/entities/User.ts” << ‘EOF’
export class User {
constructor(
public id: string,
public name: string,
public email: string,
public role: ‘admin’ | ‘user’ = ‘user’,
public createdAt: Date = new Date()
) {}

isValid(): boolean {
return this.name.length > 0 && this.email.includes(’@’);
}

isAdmin(): boolean {
return this.role === ‘admin’;
}
}
EOF

cat > “$PROJECT_PATH/src/features/core/domain/entities/Product.ts” << ‘EOF’
export class Product {
constructor(
public id: string,
public name: string,
public price: number,
public stock: number,
public description: string = ‘’,
public category: string = ‘’
) {}

isAvailable(): boolean {
return this.stock > 0;
}

applyDiscount(discountPercent: number): number {
return this.price * (1 - discountPercent / 100);
}
}
EOF

cat > “$PROJECT_PATH/src/features/core/domain/entities/Cart.ts” << ‘EOF’
import { Product } from ‘./Product’;

export interface CartItem {
product: Product;
quantity: number;
}

export class Cart {
constructor(
public id: string,
public items: CartItem[] = [],
public createdAt: Date = new Date()
) {}

addItem(product: Product, quantity: number = 1): void {
const existingItem = this.items.find(item => item.product.id === product.id);
if (existingItem) {
existingItem.quantity += quantity;
} else {
this.items.push({ product, quantity });
}
}

removeItem(productId: string): void {
this.items = this.items.filter(item => item.product.id !== productId);
}

getTotalPrice(): number {
return this.items.reduce((total, item) => total + item.product.price * item.quantity, 0);
}

isEmpty(): boolean {
return this.items.length === 0;
}
}
EOF

cat > “$PROJECT_PATH/src/features/core/domain/entities/Order.ts” << ‘EOF’
import { Cart } from ‘./Cart’;

export type OrderStatus = ‘pending’ | ‘confirmed’ | ‘shipped’ | ‘delivered’ | ‘cancelled’;

export class Order {
constructor(
public id: string,
public cart: Cart,
public status: OrderStatus = ‘pending’,
public totalPrice: number = 0,
public createdAt: Date = new Date(),
public updatedAt: Date = new Date()
) {
this.totalPrice = cart.getTotalPrice();
}

canBeCancelled(): boolean {
return this.status === ‘pending’ || this.status === ‘confirmed’;
}

updateStatus(newStatus: OrderStatus): void {
if (this.canBeUpdatedTo(newStatus)) {
this.status = newStatus;
this.updatedAt = new Date();
}
}

private canBeUpdatedTo(newStatus: OrderStatus): boolean {
const validTransitions: Record<OrderStatus, OrderStatus[]> = {
pending: [‘confirmed’, ‘cancelled’],
confirmed: [‘shipped’, ‘cancelled’],
shipped: [‘delivered’],
delivered: [],
cancelled: []
};
return validTransitions[this.status]?.includes(newStatus) ?? false;
}
}
EOF

cat > “$PROJECT_PATH/src/features/core/domain/entities/index.ts” << ‘EOF’
export { User } from ‘./User’;
export { Product } from ‘./Product’;
export { Cart, CartItem } from ‘./Cart’;
export { Order, OrderStatus } from ‘./Order’;
EOF

# ============ CORE - REPOSITORIES ============

cat > “$PROJECT_PATH/src/features/core/domain/repositories/UserRepository.ts” << ‘EOF’
import { User } from ‘../entities/User’;

export interface IUserRepository {
getById(id: string): Promise<User | null>;
getAll(): Promise<User[]>;
search(query: string): Promise<User[]>;
save(user: User): Promise<void>;
delete(id: string): Promise<void>;
}
EOF

cat > “$PROJECT_PATH/src/features/core/domain/repositories/ProductRepository.ts” << ‘EOF’
import { Product } from ‘../entities/Product’;

export interface IProductRepository {
getById(id: string): Promise<Product | null>;
getAll(): Promise<Product[]>;
search(query: string): Promise<Product[]>;
getByCategory(category: string): Promise<Product[]>;
save(product: Product): Promise<void>;
delete(id: string): Promise<void>;
}
EOF

cat > “$PROJECT_PATH/src/features/core/domain/repositories/CartRepository.ts” << ‘EOF’
import { Cart } from ‘../entities/Cart’;

export interface ICartRepository {
getById(id: string): Promise<Cart | null>;
save(cart: Cart): Promise<void>;
delete(id: string): Promise<void>;
}
EOF

cat > “$PROJECT_PATH/src/features/core/domain/repositories/OrderRepository.ts” << ‘EOF’
import { Order } from ‘../entities/Order’;

export interface IOrderRepository {
getById(id: string): Promise<Order | null>;
getAll(): Promise<Order[]>;
save(order: Order): Promise<void>;
update(order: Order): Promise<void>;
delete(id: string): Promise<void>;
}
EOF

cat > “$PROJECT_PATH/src/features/core/domain/repositories/index.ts” << ‘EOF’
export type { IUserRepository } from ‘./UserRepository’;
export type { IProductRepository } from ‘./ProductRepository’;
export type { ICartRepository } from ‘./CartRepository’;
export type { IOrderRepository } from ‘./OrderRepository’;
EOF

# ============ CORE - HTTP ============

cat > “$PROJECT_PATH/src/features/core/infrastructure/http/HttpClient.ts” << ‘EOF’
export interface ApiResponse<T> {
data: T;
message?: string;
success: boolean;
}

export class HttpClient {
private baseUrl = ‘’;

setBaseUrl(url: string): void {
this.baseUrl = url;
}

async get<T>(path: string): Promise<T> {
const response = await fetch(`${this.baseUrl}${path}`);
if (!response.ok) throw new Error(`HTTP ${response.status}`);
const data = await response.json();
return data as T;
}

async post<T>(path: string, body: any): Promise<T> {
const response = await fetch(`${this.baseUrl}${path}`, {
method: ‘POST’,
headers: { ‘Content-Type’: ‘application/json’ },
body: JSON.stringify(body),
});
if (!response.ok) throw new Error(`HTTP ${response.status}`);
const data = await response.json();
return data as T;
}

async put<T>(path: string, body: any): Promise<T> {
const response = await fetch(`${this.baseUrl}${path}`, {
method: ‘PUT’,
headers: { ‘Content-Type’: ‘application/json’ },
body: JSON.stringify(body),
});
if (!response.ok) throw new Error(`HTTP ${response.status}`);
const data = await response.json();
return data as T;
}

async delete<T>(path: string): Promise<T> {
const response = await fetch(`${this.baseUrl}${path}`, {
method: ‘DELETE’,
});
if (!response.ok) throw new Error(`HTTP ${response.status}`);
const data = await response.json();
return data as T;
}
}
EOF

# ============ CORE - REPOSITORIES IMPLEMENTATION ============

cat > “$PROJECT_PATH/src/features/core/infrastructure/repositories/BaseHttpRepository.ts” << ‘EOF’
import { HttpClient } from ‘../http/HttpClient’;

export abstract class BaseHttpRepository<T> {
protected abstract baseUrl: string;

constructor(protected http: HttpClient) {}

async getAll(): Promise<T[]> {
const data = await this.http.get<any[]>(this.baseUrl);
return data.map(item => this.toDomain(item));
}

async getById(id: string): Promise<T | null> {
try {
const data = await this.http.get<any>(`${this.baseUrl}/${id}`);
return this.toDomain(data);
} catch {
return null;
}
}

async save(entity: T): Promise<void> {
await this.http.post(this.baseUrl, this.toAPI(entity));
}

async delete(id: string): Promise<void> {
await this.http.delete(`${this.baseUrl}/${id}`);
}

protected abstract toDomain(data: any): T;
protected abstract toAPI(entity: T): any;
}
EOF

cat > “$PROJECT_PATH/src/features/core/infrastructure/repositories/HttpProductRepository.ts” << ‘EOF’
import { IProductRepository } from ‘../../domain/repositories/ProductRepository’;
import { Product } from ‘../../domain/entities/Product’;
import { BaseHttpRepository } from ‘./BaseHttpRepository’;
import { HttpClient } from ‘../http/HttpClient’;

export class HttpProductRepository extends BaseHttpRepository<Product> implements IProductRepository {
protected baseUrl = ‘/api/products’;

constructor(http: HttpClient) {
super(http);
}

async search(query: string): Promise<Product[]> {
const data = await this.http.get<any[]>(`${this.baseUrl}/search?q=${query}`);
return data.map(item => this.toDomain(item));
}

async getByCategory(category: string): Promise<Product[]> {
const data = await this.http.get<any[]>(`${this.baseUrl}/category/${category}`);
return data.map(item => this.toDomain(item));
}

protected toDomain(data: any): Product {
return new Product(data.id, data.name, data.price, data.stock, data.description, data.category);
}

protected toAPI(product: Product): any {
return {
id: product.id,
name: product.name,
price: product.price,
stock: product.stock,
description: product.description,
category: product.category,
};
}
}
EOF

cat > “$PROJECT_PATH/src/features/core/infrastructure/repositories/index.ts” << ‘EOF’
export { BaseHttpRepository } from ‘./BaseHttpRepository’;
export { HttpProductRepository } from ‘./HttpProductRepository’;
EOF

# ============ CORE - STORE ============

cat > “$PROJECT_PATH/src/features/core/store/useAppStore.ts” << ‘EOF’
import { createContext, useContext, useState, ReactNode } from ‘react’;
import { Product, Cart, Order } from ‘../domain/entities’;

export interface AppState {
products: Product[];
productsLoading: boolean;
productsError: string | null;
cart: Cart | null;
cartLoading: boolean;
cartError: string | null;
orders: Order[];
ordersLoading: boolean;
ordersError: string | null;
}

export interface AppContextType extends AppState {
setProducts: (products: Product[]) => void;
setProductsLoading: (loading: boolean) => void;
setProductsError: (error: string | null) => void;
setCart: (cart: Cart | null) => void;
setCartLoading: (loading: boolean) => void;
setCartError: (error: string | null) => void;
setOrders: (orders: Order[]) => void;
setOrdersLoading: (loading: boolean) => void;
setOrdersError: (error: string | null) => void;
}

const AppContext = createContext<AppContextType | undefined>(undefined);

export const AppProvider: React.FC<{ children: ReactNode }> = ({ children }) => {
// Products
const [products, setProducts] = useState<Product[]>([]);
const [productsLoading, setProductsLoading] = useState(false);
const [productsError, setProductsError] = useState<string | null>(null);

// Cart
const [cart, setCart] = useState<Cart | null>(null);
const [cartLoading, setCartLoading] = useState(false);
const [cartError, setCartError] = useState<string | null>(null);

// Orders
const [orders, setOrders] = useState<Order[]>([]);
const [ordersLoading, setOrdersLoading] = useState(false);
const [ordersError, setOrdersError] = useState<string | null>(null);

const value: AppContextType = {
products,
productsLoading,
productsError,
cart,
cartLoading,
cartError,
orders,
ordersLoading,
ordersError,
setProducts,
setProductsLoading,
setProductsError,
setCart,
setCartLoading,
setCartError,
setOrders,
setOrdersLoading,
setOrdersError,
};

return <AppContext.Provider value={value}>{children}</AppContext.Provider>;
};

export const useAppStore = (): AppContextType => {
const context = useContext(AppContext);
if (!context) {
throw new Error(‘useAppStore must be used within AppProvider’);
}
return context;
};
EOF

# ============ PRODUCT - USE CASES ============

cat > “$PROJECT_PATH/src/features/product/domain/use-cases/GetAllProducts/GetAllProductsUseCase.ts” << ‘EOF’
import { Product } from ‘@/features/core/domain/entities’;
import { IProductRepository } from ‘@/features/core/domain/repositories’;

export interface GetAllProductsResponse {
products: Product[];
}

export class GetAllProductsUseCase {
constructor(private productRepository: IProductRepository) {}

async execute(): Promise<GetAllProductsResponse> {
const products = await this.productRepository.getAll();
return { products };
}
}
EOF

cat > “$PROJECT_PATH/src/features/product/domain/use-cases/GetProduct/GetProductUseCase.ts” << ‘EOF’
import { Product } from ‘@/features/core/domain/entities’;
import { IProductRepository } from ‘@/features/core/domain/repositories’;

export interface GetProductResponse {
product: Product;
}

export class GetProductUseCase {
constructor(private productRepository: IProductRepository) {}

async execute(productId: string): Promise<GetProductResponse> {
const product = await this.productRepository.getById(productId);
if (!product) {
throw new Error(‘Product not found’);
}
return { product };
}
}
EOF

cat > “$PROJECT_PATH/src/features/product/domain/use-cases/SearchProducts/SearchProductsUseCase.ts” << ‘EOF’
import { Product } from ‘@/features/core/domain/entities’;
import { IProductRepository } from ‘@/features/core/domain/repositories’;

export interface SearchProductsRequest {
query: string;
}

export interface SearchProductsResponse {
products: Product[];
}

export class SearchProductsUseCase {
constructor(private productRepository: IProductRepository) {}

async execute(request: SearchProductsRequest): Promise<SearchProductsResponse> {
if (!request.query.trim()) {
return { products: [] };
}
const products = await this.productRepository.search(request.query);
return { products };
}
}
EOF

cat > “$PROJECT_PATH/src/features/product/domain/use-cases/CreateProduct/CreateProductUseCase.ts” << ‘EOF’
import { Product } from ‘@/features/core/domain/entities’;
import { IProductRepository } from ‘@/features/core/domain/repositories’;

export interface CreateProductRequest {
name: string;
price: number;
stock: number;
description?: string;
category?: string;
}

export interface CreateProductResponse {
product: Product;
}

export class CreateProductUseCase {
constructor(private productRepository: IProductRepository) {}

async execute(request: CreateProductRequest): Promise<CreateProductResponse> {
this.validateRequest(request);

```
const product = new Product(
  this.generateId(),
  request.name,
  request.price,
  request.stock,
  request.description || '',
  request.category || ''
);

if (!product.isAvailable()) {
  throw new Error('Product is not available');
}

await this.productRepository.save(product);
return { product };
```

}

private validateRequest(request: CreateProductRequest): void {
if (!request.name.trim()) {
throw new Error(‘Product name is required’);
}
if (request.price <= 0) {
throw new Error(‘Product price must be greater than 0’);
}
if (request.stock < 0) {
throw new Error(‘Product stock cannot be negative’);
}
}

private generateId(): string {
return Math.random().toString(36).substr(2, 9);
}
}
EOF

cat > “$PROJECT_PATH/src/features/product/domain/use-cases/index.ts” << ‘EOF’
export { GetAllProductsUseCase, type GetAllProductsResponse } from ‘./GetAllProducts/GetAllProductsUseCase’;
export { GetProductUseCase, type GetProductResponse } from ‘./GetProduct/GetProductUseCase’;
export { SearchProductsUseCase, type SearchProductsRequest, type SearchProductsResponse } from ‘./SearchProducts/SearchProductsUseCase’;
export { CreateProductUseCase, type CreateProductRequest, type CreateProductResponse } from ‘./CreateProduct/CreateProductUseCase’;
EOF

# ============ PRODUCT - COMPONENTS ============

cat > “$PROJECT_PATH/src/features/product/presentation/components/product-list/ProductList.tsx” << ‘EOF’
import { useEffect } from ‘react’;
import { useAppStore } from ‘@/features/core/store/useAppStore’;
import { HttpProductRepository } from ‘@/features/core/infrastructure/repositories’;
import { GetAllProductsUseCase } from ‘../../domain/use-cases’;
import { HttpClient } from ‘@/features/core/infrastructure/http/HttpClient’;

export const ProductList: React.FC = () => {
const {
products,
productsLoading,
productsError,
setProducts,
setProductsLoading,
setProductsError,
} = useAppStore();

const httpClient = new HttpClient();
httpClient.setBaseUrl(process.env.REACT_APP_API_URL || ‘http://localhost:3000’);
const productRepository = new HttpProductRepository(httpClient);

useEffect(() => {
loadProducts();
}, []);

const loadProducts = async () => {
const useCase = new GetAllProductsUseCase(productRepository);

```
setProductsLoading(true);
setProductsError(null);

try {
  const response = await useCase.execute();
  setProducts(response.products);
} catch (error) {
  const message = error instanceof Error ? error.message : 'Unknown error';
  setProductsError(message);
} finally {
  setProductsLoading(false);
}
```

};

return (
<div className="product-list">
<h2>Produits</h2>
<button onClick={loadProducts}>Charger les produits</button>

```
  {!productsLoading ? (
    <>
      <p className="product-count">{products.length} produits</p>
      <ul>
        {products.map((product) => (
          <li key={product.id}>
            <strong>{product.name}</strong>
            <p>{product.price}€ - Stock: {product.stock}</p>
            <p>{product.description}</p>
          </li>
        ))}
      </ul>
    </>
  ) : (
    <p>Chargement...</p>
  )}

  {productsError && <p className="error">{productsError}</p>}
</div>
```

);
};
EOF

cat > “$PROJECT_PATH/src/features/product/presentation/pages/ProductsPage.tsx” << ‘EOF’
import { ProductList } from ‘../components/product-list/ProductList’;

export const ProductsPage: React.FC = () => (

  <div>
    <h1>Nos produits</h1>
    <ProductList />
  </div>
);
EOF

# ============ SHARED - UTILS ============

cat > “$PROJECT_PATH/src/features/shared/utils/validators/email.validator.ts” << ‘EOF’
export class EmailValidator {
static isValid(email: string): boolean {
const regex = /^[^\s@]+@[^\s@]+.[^\s@]+$/;
return regex.test(email);
}
}
EOF

cat > “$PROJECT_PATH/src/features/shared/utils/formatters/dateFormatter.ts” << ‘EOF’
export class DateFormatter {
static format(date: Date, locale: string = ‘fr-FR’): string {
return new Intl.DateTimeFormat(locale).format(date);
}
}

export class CurrencyFormatter {
static format(value: number, currency: string = ‘EUR’, locale: string = ‘fr-FR’): string {
return new Intl.NumberFormat(locale, {
style: ‘currency’,
currency,
}).format(value);
}
}
EOF

# ============ APP ============

cat > “$PROJECT_PATH/src/app/App.tsx” << ‘EOF’
import ‘./App.css’;
import { ProductsPage } from ‘@/features/product/presentation/pages/ProductsPage’;

export const App: React.FC = () => (

  <div className="app">
    <header className="app-header">
      <h1>Clean Code Architecture - React</h1>
    </header>
    <main className="app-main">
      <ProductsPage />
    </main>
  </div>
);
EOF

cat > “$PROJECT_PATH/src/app/App.css” << ‘EOF’
.app {
min-height: 100vh;
background-color: #f5f5f5;
}

.app-header {
background-color: #333;
color: white;
padding: 20px;
}

.app-header h1 {
margin: 0;
}

.app-main {
padding: 20px;
}

.product-list {
background: white;
padding: 20px;
border-radius: 8px;
box-shadow: 0 2px 4px rgba(0,0,0,0.1);
}

.product-count {
font-weight: bold;
margin: 10px 0;
}

.product-list ul {
list-style: none;
padding: 0;
}

.product-list li {
padding: 10px;
border: 1px solid #ddd;
margin: 5px 0;
border-radius: 4px;
}

.product-list button {
padding: 8px 16px;
background-color: #007bff;
color: white;
border: none;
border-radius: 4px;
cursor: pointer;
margin-bottom: 20px;
}

.product-list button:hover {
background-color: #0056b3;
}

.error {
color: #d32f2f;
padding: 10px;
background-color: #ffebee;
border-radius: 4px;
}
EOF

cat > “$PROJECT_PATH/src/main.tsx” << ‘EOF’
import React from ‘react’;
import ReactDOM from ‘react-dom/client’;
import { AppProvider } from ‘@/features/core/store/useAppStore’;
import { App } from ‘./app/App’;

ReactDOM.createRoot(document.getElementById(‘root’)!).render(
<React.StrictMode>
<AppProvider>
<App />
</AppProvider>
</React.StrictMode>
);
EOF

# ============ .AI FOLDER ============

cat > “$PROJECT_PATH/.ai/PROMPT_PREFIX.txt” << ‘EOF’

# CONTEXTE - À COPIER EN DÉBUT DE CHAQUE PROMPT

Tu es un agent IA développant une application **React/React Native** avec architecture **Clean Code**.

## 🎯 Règles d’or (NON NÉGOCIABLES)

1. **Domain = Métier pur** → Zéro import React, réutilisable partout
1. **Store = État simple** → Context API + useState, aucune dépendance externe
1. **Composants = Simples** → Utilisent useAppStore hook, créent use cases au runtime
1. **Communication** → Via useAppStore UNIQUEMENT, pas d’imports croisés
1. **Réutilisation** → OK si composant reçoit data via props

## 📂 Structure (résumé)

```
src/features/
├── core/
│   ├── domain/        (entities, repositories)
│   ├── infrastructure/(HTTP, repositories)
│   └── store/         (useAppStore - Context API)
├── [feature]/
│   ├── domain/use-cases/
│   └── presentation/components + pages/
└── shared/            (validators, formatters, hooks)
```

## ✅ Avant de proposer du code

1. Confirme que tu as compris l’architecture
1. Utilise les templates de `.ai/contexts/`
1. Respecte `.ai/code-standards.md`
1. Commente pourquoi c’est cohérent

**Confirme ta compréhension maintenant.**
EOF

cat > “$PROJECT_PATH/.ai/README.md” << ‘EOF’

# 🤖 Guide pour les agents IA (React/React Native)

Ce dossier contient toute la documentation pour développer dans cette architecture.

## 📚 Comment l’utiliser

1. **Avant chaque prompt** : Copie `PROMPT_PREFIX.txt`
1. **Pour créer du code** : Lis `contexts/[type]-creation.md`
1. **Pour modifier une feature** : Lis `features/[feature].md`
1. **Pour les conventions** : Lis `code-standards.md`
1. **Pour la structure** : Lis `architecture.md`
1. **En cas de bug** : Lis `troubleshooting.md`

## 🗂️ Fichiers clés

- `PROMPT_PREFIX.txt` → À copier en début de prompt
- `architecture.md` → Architecture complète
- `code-standards.md` → Conventions de code
- `contexts/` → Templates pour créer du code
- `features/` → Spécifications des features
- `troubleshooting.md` → Erreurs courantes
  EOF

cat > “$PROJECT_PATH/.ai/architecture.md” << ‘EOF’

# Architecture Clean Code React/React Native

## 🎯 Résumé exécutif

- **Domain** = Logique métier pure (zéro React)
- **Infrastructure** = HTTP, repositories
- **Store** = Context API + useState (ultra-simple)
- **Features** = Autonomes, communiquent via useAppStore
- **Shared** = Utilitaires réutilisables

## 📁 Structure

```
src/features/
├── core/
│   ├── domain/
│   │   ├── entities/        (User, Product, Cart, Order)
│   │   └── repositories/    (Interfaces)
│   ├── infrastructure/
│   │   ├── http/HttpClient.ts
│   │   └── repositories/    (BaseHttpRepository, HttpProductRepository)
│   └── store/useAppStore.ts (Context API)
├── product/
│   ├── domain/use-cases/    (GetAllProducts, CreateProduct, etc.)
│   └── presentation/
│       ├── components/      (ProductList, ProductDetail)
│       └── pages/          (ProductsPage.tsx)
├── cart/, order/, auth/
└── shared/
    ├── components/
    ├── hooks/
    ├── utils/              (validators, formatters)
    └── types/
```

## 🏗️ Store (Context API)

```typescript
// features/core/store/useAppStore.ts
const AppProvider = ({ children }) => {
  const [products, setProducts] = useState([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  return (
    <AppContext.Provider value={{ products, setProducts, loading, setLoading, error, setError }}>
      {children}
    </AppContext.Provider>
  );
};

const useAppStore = () => useContext(AppContext);
```

**Zéro dépendance externe !**

## 🎯 Composant

```typescript
export const ProductList: React.FC = () => {
```
