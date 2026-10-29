import { describe, it, expect } from "vitest";
import { esHorarioRestringido } from "@/utils/horarioRestringido";

// Helper: crea una fecha valida (anio >= 2025 para no disparar el modo
// anti-reloj-roto) con la hora y minutos indicados.
const d = (h: number, m: number) => new Date(2026, 8, 26, h, m, 0);

describe("esHorarioRestringido — ventana nocturna 22:20 a 06:00 (upgrade 2026-09-26)", () => {
  it("NO restringe a las 22:00 (antes si, ahora no)", () => {
    expect(esHorarioRestringido(d(22, 0))).toBe(false);
  });

  it("NO restringe a las 22:19 (ultimo minuto habilitado)", () => {
    expect(esHorarioRestringido(d(22, 19))).toBe(false);
  });

  it("SI restringe a las 22:20 (nuevo inicio)", () => {
    expect(esHorarioRestringido(d(22, 20))).toBe(true);
  });

  it("SI restringe a las 22:59", () => {
    expect(esHorarioRestringido(d(22, 59))).toBe(true);
  });

  it("SI restringe a las 23:00", () => {
    expect(esHorarioRestringido(d(23, 0))).toBe(true);
  });

  it("SI restringe a la medianoche y de madrugada", () => {
    expect(esHorarioRestringido(d(0, 0))).toBe(true);
    expect(esHorarioRestringido(d(3, 30))).toBe(true);
  });

  it("SI restringe a las 05:59 (fin sin cambios)", () => {
    expect(esHorarioRestringido(d(5, 59))).toBe(true);
  });

  it("NO restringe a las 06:00 (fin de la ventana, igual que antes)", () => {
    expect(esHorarioRestringido(d(6, 0))).toBe(false);
  });

  it("NO restringe durante el dia (mediodia)", () => {
    expect(esHorarioRestringido(d(12, 0))).toBe(false);
  });

  it("proteccion anti-reloj-roto: anio < 2025 NUNCA restringe", () => {
    // Aun a las 3 AM, si el anio es absurdo (pila de BIOS agotada), no bloquea.
    expect(esHorarioRestringido(new Date(2000, 0, 1, 3, 0, 0))).toBe(false);
  });
});
