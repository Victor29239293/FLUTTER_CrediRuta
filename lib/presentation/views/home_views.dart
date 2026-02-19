/// Barrel file para exportar la vista Home refactorizada
/// Este archivo mantiene compatibilidad con imports existentes
///
/// La nueva arquitectura está organizada en:
/// - home/home_view.dart: Vista principal
/// - home/home_content.dart: Contenido con búsqueda y lista
/// - home/widgets/: Componentes UI reutilizables
/// - home/detalle/: Bottom sheet de detalle del cobro
/// - home/utils/: Utilidades como formateadores de fecha

export 'home/home_view.dart';
export 'home/home_content.dart';
export 'home/detalle/detalle_cobro_sheet.dart';
export 'home/widgets/widgets.dart';
export 'home/utils/date_formatter.dart';

// Alias para mantener compatibilidad con el nombre anterior
import 'home/home_view.dart';

/// @deprecated Usar [HomeView] en su lugar
/// Vista principal del Home - Con selector de fecha
typedef HomeViews = HomeView;
