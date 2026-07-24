// App root component
import { Toaster } from "@/components/ui/toaster";
import { Toaster as Sonner } from "@/components/ui/sonner";
import { TooltipProvider } from "@/components/ui/tooltip";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { BrowserRouter, Routes, Route } from "react-router-dom";
import { SolicitudesProvider } from "@/contexts/SolicitudesContext";
import { UsuariosRegistradosProvider } from "@/hooks/useUsuariosRegistrados";
import { DiagnosticoModal } from "@/components/DiagnosticoModal";
import Index from "./pages/Index";
import NotFound from "./pages/NotFound";
import MonitorVigilancia from "./pages/MonitorVigilancia";
import TerminalUsuario from "./pages/TerminalUsuario";
import Dashboard from "./pages/Dashboard";
import SRSDocument from "./pages/SRSDocument";

const queryClient = new QueryClient();

const App = () => (
  <QueryClientProvider client={queryClient}>
    <UsuariosRegistradosProvider>
    <SolicitudesProvider>
      <TooltipProvider>
        <Toaster />
        <Sonner />
        {/* Panel de diagnostico global. Se abre con Ctrl+Shift+D o con
            5 toques rapidos en pantalla. Sirve para depurar errores
            cuando DevTools (F12) esta bloqueado por politica de la
            organizacion en los kiosks tactiles. */}
        <DiagnosticoModal />
        <BrowserRouter>
          <Routes>
            <Route path="/" element={<Index />} />
            <Route path="/terminal" element={<TerminalUsuario />} />
            <Route path="/monitor" element={<MonitorVigilancia />} />
            <Route path="/dashboard" element={<Dashboard />} />
            <Route path="/srs" element={<SRSDocument />} />
            {/* ADD ALL CUSTOM ROUTES ABOVE THE CATCH-ALL "*" ROUTE */}
            <Route path="*" element={<NotFound />} />
          </Routes>
        </BrowserRouter>
      </TooltipProvider>
    </SolicitudesProvider>
    </UsuariosRegistradosProvider>
  </QueryClientProvider>
);

export default App;
