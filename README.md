# Changadex

Un coleccionista de items para **Project Zomboid (Build 42)**. Andá descubriendo
items a medida que los recogés, los leés, te los ponés, los comés o los ves en
la tele, y la lista se va llenando sola — como una Pokédex pero de todo lo que
podés encontrar en Knox County.

![poster](poster.png)

## Qué hace

- Ventana de colección con categorías (Armas, Ropa, Comida, Literatura,
  Entretenimiento, Herramientas, etc.) y porcentaje de avance.
- **Descubrimiento automático** según cómo interactuás con cada cosa:
  - Armas / herramientas / ropa / materiales → al meterlos en la mochila.
  - Comida / bebida → al comerla o tomarla.
  - Libros / revistas / periódicos / flyers → al leerlos.
  - VHS / CD → al insertarlos en un VCR, radio o TV.
- **Títulos específicos**: revistas y diarios se guardan por título (ej.
  "Sprinter: Diciembre 1983"), no por el tipo genérico.
- **Notificación tipo subida de nivel** sobre la cabeza del personaje cuando
  descubrís algo nuevo.
- **Menú contextual**: clic derecho sobre un item te dice si ya está
  descubierto o si falta leerlo/comerlo/verlo.
- Filtros: solo descubiertos / todos / solo faltantes, y buscador.
- Progreso **por personaje** (guardado en `ModData`, no se pierde entre
  sesiones).

## Instalación

### Desde Steam Workshop
*(próximamente)*

### Manual
1. Descargá la última versión desde
   [Releases](../../releases).
2. Copiá la carpeta `Changadex/` en `C:\Users\<usuario>\Zomboid\mods\`.
3. Abrí Project Zomboid → **Mods** → activá **Changadex**.

## Uso

- Tecla **N** (configurable en *Options → Key Bindings → Changadex*) abre la
  ventana.
- La ventana muestra el catálogo por categorías. Lo que todavía no descubriste
  sale como silueta gris con `???`.

## Compatibilidad

- Project Zomboid **Build 42** (probado con la unstable branch).
- No tocaba nada del save original — si desactivás el mod, tu partida sigue
  funcionando.

## Troubleshooting

- **No aparece el mod en el menú**: asegurate de que esté en
  `<usuario>/Zomboid/mods/Changadex/` y que la subcarpeta `42/` exista.
- **No se abre con N**: chequeá que N no esté usada por otra cosa en
  *Options → Key Bindings*.
- **Algo tira error**: abrí `ProjectZomboid64ShowConsole.bat` en vez del
  ejecutable normal para ver los logs en vivo, o miralos en
  `C:\Users\<usuario>\Zomboid\console.txt`.

## Feedback

Tiré un issue o un PR si encontrás un bug o querés sugerir algo. Lo que más me
interesa saber:

- Items mal categorizados (ej. algo que debería ir a Literatura y cae en otra).
- Acciones de descubrimiento que no me acordé de hookear.
- Balance del sistema de progreso (¿demasiadas categorías? ¿muy grandes?).

## Licencia

MIT — ver [LICENSE](LICENSE).
