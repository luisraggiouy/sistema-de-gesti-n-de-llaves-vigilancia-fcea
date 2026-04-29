import { createRoot } from "react-dom/client";
import App from "./App.tsx";
import "./index.css";
// Importar el parche CORS para solucionar problemas de conexión al backend
import { aplicarParchesCORS } from "./lib/cors-fix";

// Aplicar parche CORS inmediatamente
aplicarParchesCORS();

// Mensaje de estado en la consola
console.log("[Sistema Llaves FCEA] Iniciando aplicación con parche CORS activado");

createRoot(document.getElementById("root")!).render(<App />);
