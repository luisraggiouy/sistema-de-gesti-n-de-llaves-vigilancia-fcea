
import fs from 'fs';

const text = `
Tablero principal puerta izquierda
A B C D E F G H
1 OFICINA Intendencia OFICINA UGE OFICINA Servicios. Generles tALLER Mantenimiento oFICINA Reproducciones TALLER Electrotécnia OFICINA Puerta vigilancia
2 BIBLIOTECA entrada BIBLIOTECA salida patio subsuelo BIBIOTECA depósito BIBLIOTECA Sala de lectura BIBLIOTECA Pasaje sale de lectura a biblioteca BIBLIOTECA Entrepiso Biblioteca
SALA Sala A
3 OFICINA Decanato SALA Sala consejo OFICINA Oficina decano Decanato interior OFICINA Comunicaciónes OFICINA Asistenciaacadémica OFICINA Cavida SALA Decanato a sala de consejo RECREACIÓN Recrea subsuelo entrada Archivo Area de recreación Depósito cecea
4 OFICINA Bedelía OFICINA Sistemas OFICINA Sistemas 21 OFICINA Apoyo docente OFICINA Extensión UEAM OFICINA Compras
BAÑOSBaños nuevos funcionarios
5 OTRO Archivo SALA Sala comisiones Comisiones reguladora Pasaje sala comisiones OFICINA Consejo y suministros OFICINA Suministros OFICINA Dirección TAS Personal TAS OFICINA Concursos
OTRO CECEA
6 OFICINA Rendiciones OFICINA Contaduría OFICINA Sueldos OFICINA Gastos OFICINA Convenios OFICINA Personal docente
OTRO Reja ventana investigadores Bajo escalera patio EIP

Puerta derecha tablero principal
A B C D E F G H
1
OTRO Entrada facultad OTRO Entrada eduardo acevedo OTRO Portón MSP AREA COMÚN Azotea ÁREA COMÚN Buhardilla OTRO Patio cantina
2
OTRO Cortina aulario
OTRO Porta rollos baños iesta ESPACIO COMÚN Bicicletas OTRO Patio reja invesigadores OTRO Reja exterior lactancia
3
OTRO Reja exterior eduardo acevedo jaula OTRO Salida patio 11-12d ESPACIO COMÚN Patio bicicletas BAÑOS Baños salón 5 OTRO Tableros OTRO Descanso cooperativa
4
SALA Lactancia manojo SALALactancia vestuarios BAÑOSBaño Hall cantina BAÑOSDuchas vestuarios subsuelo BAÑOSBaños subsuelo OTROSPorta rollo
5
BAÑOSBaño PA informática BAÑOSBaños IESTA BAÑOSBaños AM BAÑOSBaño salón 23 privado BAÑOSBaño salón 23 lisiado BAÑOSBaño salón 23 hombres BAÑOSBaño salón 23 damas
6
BAÑOS Baño salón 6 BAÑOSBaño salón 7 BAÑOSBaño salón 8 BAÑOSBaños vigilancia BAÑOSBaños decanato hombres BAÑOSBaños decanato damas

Lateral izquierdo (no llevan coordenadas por ser muy pocas en el área en este caso solo se dice que la llave se encuentra en lateral izquierdo)
Accesos EIP manojo
Oficinas y secretaría EIP 205-201
Oficinas EIP 301-315
Oficinas EIP 302-316

Lateral derecho (no llevan coordenadas por ser muy pocas en el área en este caso solo se dice que la llave se encuentra en lateral derecho)
Matemáticas
CGU
Recreación sala 1
Recreación entrada
Recreación sala 2
Recreación sala 3

Tablero principal fondo
A B C D E F G H I J Q K L M
1 OFICINA Affur OTROAscensor américa OTRO Traba ascensor EIP OTROPulsadores Isai OTROBomba de agua patio SALABomba de incendio OTROContadores ose jackson OTROMedidor de ute DEPÓSITO Depósito garrafas OTROCamioneta OTROMueble objetos perdidos
2 ACCESO Investigadores entrada oficinas OFICINA Investigadores baños OFICINA Investigadores of 1 OFICINA Investigadores of 2 OFICINA Investigadores of 3 OFICINA Investigadores of 4 OFICINA Investigadores of 5 OFICINA Investigadores of 6 OFICINA Investigadores of 7 OFICINA Investigadores of 8 OFICINA Investigadores of 9 OFICINA Investigadores of 10
3 SALA Sala de navegación entrada SALASala de navegación box 1 SALASala de navegación box 2 SALASala de navegación box 3 SALASala de navegación box 4 SALASala de navegación box 5 SALÓNBloomberg SALÓNInformática OFICINA UPC OFICINA UAE OFICINA Multimedia SALALockers pruebas sala docente

Fondo fila a partir de salones (a partir de esta fila solo se nombrará de cada llave la fila a la que pertenece y no la columna porque ya no existen equidistancias para completar las coordenadas entonces por ejemplo “salones 1,2,3,5 tablero principal, fondo, fila 4” esa será la info de ubicación
4 SALÓN Salónes 1,2,3,5 SALÓNHÍBRIDOSalón 4 SALÓN HÍBRIDOSalón 6 SALÓN HÍBRIDOSalón7 SALÓN HÍBRIDOSalón8 SALON HIBRIDOSalón 9 SALÓN Salón 10 SALONSalón11-12 SALÓN HIBRIDOSalones 14,15,16 SALÓNSalón 18 SAÓNsalón 19 Salón 20 SALON HÍBRIDOSalo1-nes 21-25
5 SALÓNEquipos AM SALÓNEquiposVIP
SALÓNEquiposAM SALÓNEquipos2 SALÓNEquipos3 SALÓNEquipos5 SALÓN HÍBRIDOEquipos6 SALÓN HÍBRIDOEquipos 7 SALÓN HÍBRIDOEquipos8 Equipos 10 SALÓNEquipos11 SALÓNEquipos12 SALÓN HÍBRIDOEquipos14 SALÓN HÍBRIDOEquipos15 SALÓN HÍBRIDOEquipos16 SALÓNEquipos18 SALÓN Equipos19 SALÓNEquipos20 OTROEquipos21 OTROEquipos22 HÍBRIDOEquipos23 SALÓN HÍBRIDOEquipos24 SALÓN HÍBRIDOEquipos25
6 OFICINAIesta sala 17 OFICINAIesta sala18 OFICINAIestasala19 OFICINAIestasala 2020.a-20.b-20.c OFICINAIestasala2121.a-21.b-21.c OFICINAIestasala22 OFICINAIestasala23-23.a-23.b-23.c OFICINAIesta sala 24 OFICINAIesta sala25 OFICINAIestasala27 DEPÓSITO Depósito de máquinas
`;

const lines = text.trim().split('\\n');

const sections = [];
let currentSection = null;

for (const line of lines) {
  if (line.startsWith('Tablero principal') || line.startsWith('Puerta derecha') || line.startsWith('Lateral izquierdo') || line.startsWith('Lateral derecho') || line.startsWith('Tablero principal fondo')) {
    if (currentSection) {
      sections.push(currentSection);
    }
    currentSection = {
      title: line.trim(),
      data: []
    };
  } else if (currentSection) {
    currentSection.data.push(line.trim());
  }
}
if (currentSection) {
  sections.push(currentSection);
}

const lugares = [];
let idCounter = 1;

function parseSection(section) {
  const zona = section.title.includes('puerta izquierda') ? 'Puerta izquierda' :
               section.title.includes('puerta derecha') ? 'Puerta derecha' :
               section.title.includes('fondo') ? 'Fondo' :
               section.title.includes('Lateral izquierdo') ? 'Lateral izquierdo' :
               'Lateral derecho';

  let headers = [];
  let rowIndex = -1;

  for (const line of section.data) {
    // console.log("Line:", line);
    if (line.match(/^[A-Z\s]+$/) && !line.match(/^\d/)) {
        headers = line.split(/\s{2,}/).filter(h => h.trim());
        rowIndex = -1; 
        // console.log("Headers:", headers);
        continue;
    }

    const parts = line.split(/\s{2,}/).filter(p => p.trim());
    // console.log("Parts:", parts);
    if (parts.length === 0) continue;

    let row;
    let items;

    if (parts[0].match(/^\d$/)) {
        row = parseInt(parts[0], 10);
        items = parts.slice(1);
        rowIndex = 0;
    } else {
        items = parts;
        if(rowIndex !== -1) rowIndex++;
    }
    
    if (zona === 'Lateral izquierdo' || zona === 'Lateral derecho') {
        for (const item of items) {
            lugares.push({
                id: `l${idCounter++}`,
                nombre: item,
                tipo: 'Otro',
                edificio: 'Central',
                tablero: 'Tablero Principal',
                ubicacion: {
                    zona: zona
                },
                disponible: true,
                esHibrido: false
            });
        }
        continue;
    }

    for (const item of items) {
        const itemParts = item.trim().split(/\s+/);
        const tipo = itemParts[0];
        const nombre = itemParts.slice(1).join(' ');
        const columna = headers[rowIndex] || '';

        lugares.push({
            id: `l${idCounter++}`,
            nombre: nombre,
            tipo: tipo,
            edificio: 'Central',
            tablero: 'Tablero Principal',
            ubicacion: {
                zona: zona,
                fila: row,
                columna: columna
            },
            disponible: true,
            esHibrido: false
        });
        if(rowIndex !== -1) rowIndex++;
    }
  }
}


for (const section of sections) {
    parseSection(section);
}


// console.log(JSON.stringify(sections, null, 2));

for (const section of sections) {
    parseSection(section);
}


console.log(JSON.stringify(lugares, null, 2));
