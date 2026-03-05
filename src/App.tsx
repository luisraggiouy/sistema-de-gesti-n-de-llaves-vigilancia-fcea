// App root component
import { Toaster } from "@/components/ui/toaster";
import { Toaster as Sonner } from "@/components/ui/sonner";
import { TooltipProvider } from "@/components/ui/tooltip";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { BrowserRouter, Routes, Route } from "react-router-dom";
import { SolicitudesProvider } from "@/contexts/SolicitudesContext";
import Index from "./pages/Index";
import NotFound from "./pages/NotFound";
import MonitorVigilancia from "./pages/MonitorVigilancia";
import TerminalUsuario from "./pages/TerminalUsuario";
import Dashboard from "./pages/Dashboard";
import SRSDocument from "./pages/SRSDocument";

const queryClient = new QueryClient();

const App = () => (
  <QueryClientProvider client={queryClient}>
    <SolicitudesProvider>
      <TooltipProvider>
        <Toaster />
        <Sonner />
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
  </QueryClientProvider>
);

export default App;
