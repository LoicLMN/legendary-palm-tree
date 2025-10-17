// presentation/context/ServiceContext.tsx
import React, { createContext, useContext } from 'react';
import { SQLiteService } from '../../infrastructure/database/SqliteService';

const sqliteService = new SQLiteService();
sqliteService.init();

const ServiceContext = createContext<{ sqlite: SQLiteService } | null>(null);

export const ServiceProvider = ({ children }: { children: React.ReactNode }) => {
  return (
    <ServiceContext.Provider value={{ sqlite: sqliteService }}>
      {children}
    </ServiceContext.Provider>
  );
};

export const useServices = () => {
  const context = useContext(ServiceContext);
  if (!context) throw new Error('useServices must be used within a ServiceProvider');
  return context;
};
