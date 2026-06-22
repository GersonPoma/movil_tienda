import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../../core/theme/app_theme.dart';
import '../../../providers/reportes_provider.dart';

class ReportesScreen extends StatefulWidget {
  const ReportesScreen({Key? key}) : super(key: key);

  @override
  State<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends State<ReportesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // QBE State
  String? _selectedVistaNombre;
  Map<String, dynamic>? _selectedVistaData;
  List<Map<String, dynamic>> _filtros = [];
  List<String> _agruparPor = [];
  List<Map<String, dynamic>> _metricas = [];
  List<Map<String, dynamic>> _filtrosHaving = [];
  
  final TextEditingController _ordenarPorController = TextEditingController();
  final TextEditingController _paginaController = TextEditingController(text: '1');
  final TextEditingController _porPaginaController = TextEditingController(text: '50');

  // Ganancias State
  int _gananciasMes = DateTime.now().month;
  String _gananciasGroupBy = 'categoria';
  bool _gananciasCargando = false;

  // NLP Texto State
  final TextEditingController _textoNlpController = TextEditingController();

  // NLP Voz State
  late stt.SpeechToText _speech;
  bool _speechEnabled = false;
  bool _isListening = false;
  String _lastWords = '';
  String _speechStatus = 'Presiona el micrófono y habla';

  // Opciones estáticas de meses y agrupaciones para Ganancias
  final List<Map<String, dynamic>> _meses = [
    {'valor': 0, 'label': 'Todos los meses'},
    {'valor': 1, 'label': 'Enero'},
    {'valor': 2, 'label': 'Febrero'},
    {'valor': 3, 'label': 'Marzo'},
    {'valor': 4, 'label': 'Abril'},
    {'valor': 5, 'label': 'Mayo'},
    {'valor': 6, 'label': 'Junio'},
    {'valor': 7, 'label': 'Julio'},
    {'valor': 8, 'label': 'Agosto'},
    {'valor': 9, 'label': 'Septiembre'},
    {'valor': 10, 'label': 'Octubre'},
    {'valor': 11, 'label': 'Noviembre'},
    {'valor': 12, 'label': 'Diciembre'},
  ];

  final List<Map<String, dynamic>> _groupByOptions = [
    {'valor': 'categoria', 'label': 'Categoría'},
    {'valor': 'marca', 'label': 'Marca'},
    {'valor': 'producto', 'label': 'Producto'},
    {'valor': 'variante', 'label': 'Variante'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        Provider.of<ReportesProvider>(context, listen: false).limpiarResultados();
      }
    });

    _speech = stt.SpeechToText();
    _initSpeech();

    // Cargar vistas al inicio
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ReportesProvider>(context, listen: false).cargarVistas().then((_) {
        final vistas = Provider.of<ReportesProvider>(context, listen: false).vistas;
        if (vistas.isNotEmpty) {
          _seleccionarVista(vistas.first['nombre']);
        }
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _ordenarPorController.dispose();
    _paginaController.dispose();
    _porPaginaController.dispose();
    _textoNlpController.dispose();
    super.dispose();
  }

  // ---- SPEECH TO TEXT ----
  void _initSpeech() async {
    try {
      bool available = await _speech.initialize(
        onStatus: (val) {
          if (val == 'done' || val == 'notListening') {
            setState(() => _isListening = false);
            if (_lastWords.trim().isNotEmpty) {
              _ejecutarVozNLP(_lastWords);
            }
          }
        },
        onError: (val) {
          setState(() {
            _isListening = false;
            _speechStatus = 'Error: ${val.errorMsg}';
          });
        },
      );
      setState(() => _speechEnabled = available);
    } catch (e) {
      debugPrint('Error de inicialización de micrófono: $e');
    }
  }

  void _startListening() async {
    if (!_speechEnabled) {
      bool available = await _speech.initialize();
      setState(() => _speechEnabled = available);
      if (!available) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reconocimiento de voz no disponible en este dispositivo')),
        );
        return;
      }
    }
    setState(() {
      _isListening = true;
      _lastWords = '';
      _speechStatus = 'Escuchando...';
    });
    await _speech.listen(
      onResult: (val) {
        setState(() {
          _lastWords = val.recognizedWords;
          _speechStatus = _lastWords;
        });
      },
      localeId: 'es_ES',
    );
  }

  void _stopListening() async {
    await _speech.stop();
    setState(() => _isListening = false);
  }

  void _toggleMic() {
    if (_isListening) {
      _stopListening();
    } else {
      _startListening();
    }
  }

  void _ejecutarVozNLP(String query) {
    Provider.of<ReportesProvider>(context, listen: false).ejecutarNLP(query).then((success) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reporte de voz ejecutado con éxito')),
        );
      }
    });
  }

  // ---- VISTAS LÓGICAS & QBE ----
  void _seleccionarVista(String vistaNombre) {
    final vistas = Provider.of<ReportesProvider>(context, listen: false).vistas;
    final vista = vistas.firstWhere((v) => v['nombre'] == vistaNombre, orElse: () => null);
    setState(() {
      _selectedVistaNombre = vistaNombre;
      _selectedVistaData = vista;
      _filtros = [];
      _agruparPor = [];
      _metricas = [];
      _filtrosHaving = [];
    });
  }

  bool _esCampoTecnico(String nombre) {
    return nombre == 'id' || nombre.endsWith('_id');
  }

  List<dynamic> _obtenerCamposDisponibles() {
    if (_selectedVistaData == null) return [];
    final campos = _selectedVistaData!['campos'] as List<dynamic>? ?? [];
    return campos.where((c) => !_esCampoTecnico(c['nombre'])).toList();
  }

  List<dynamic> _obtenerCamposAgrupables() {
    if (_selectedVistaData == null) return [];
    final campos = _selectedVistaData!['campos'] as List<dynamic>? ?? [];
    return campos.where((c) => c['agrupable'] == true && !_esCampoTecnico(c['nombre'])).toList();
  }

  List<dynamic> _obtenerCamposAgregables() {
    if (_selectedVistaData == null) return [];
    final campos = _selectedVistaData!['campos'] as List<dynamic>? ?? [];
    return campos.where((c) => c['agregable'] == true && !_esCampoTecnico(c['nombre'])).toList();
  }

  String _traducirOperador(String op) {
    const map = {
      'exact': 'es exactamente',
      'neq': 'no es igual a',
      'gte': 'mayor o igual que (>=)',
      'lte': 'menor o igual que (<=)',
      'gt': 'mayor que (>)',
      'lt': 'menor que (<)',
      'contains': 'contiene',
      'icontains': 'contiene (sin mayúsculas)',
      'startswith': 'comienza con',
      'month': 'es del mes',
      'year': 'es del año',
      'day': 'es del día',
    };
    return map[op] ?? op;
  }

  List<String> _obtenerOperadoresParaCampo(String campoNombre) {
    if (_selectedVistaData == null) return ['exact'];
    final campos = _selectedVistaData!['campos'] as List<dynamic>? ?? [];
    final campo = campos.firstWhere((c) => c['nombre'] == campoNombre, orElse: () => null);
    if (campo == null) return ['exact'];
    return List<String>.from(campo['operadores'] ?? ['exact']);
  }

  void _agregarFiltro() {
    final campos = _obtenerCamposDisponibles();
    if (campos.isEmpty) return;
    setState(() {
      _filtros.add({
        'campo': campos.first['nombre'],
        'operador': 'exact',
        'valor': '',
      });
    });
  }

  void _removerFiltro(int index) {
    setState(() {
      _filtros.removeAt(index);
    });
  }

  void _agregarMetrica() {
    final campos = _obtenerCamposAgregables();
    if (campos.isEmpty) return;
    setState(() {
      _metricas.add({
        'campo': campos.first['nombre'],
        'operacion': 'sum',
        'alias': '',
      });
    });
  }

  void _removerMetrica(int index) {
    setState(() {
      _metricas.removeAt(index);
    });
  }

  void _agregarHaving() {
    setState(() {
      _filtrosHaving.add({
        'alias': '',
        'operador': 'gte',
        'valor': '',
      });
    });
  }

  void _removerHaving(int index) {
    setState(() {
      _filtrosHaving.removeAt(index);
    });
  }

  void _generarGanancias() async {
    final groupByMap = {
      'categoria': ['categoria_id', 'categoria_nombre'],
      'marca': ['marca_id', 'marca_nombre'],
      'producto': ['producto_id', 'producto_nombre'],
      'variante': ['variante_id', 'variante_sku', 'producto_nombre'],
    };

    final Map<String, dynamic> payload = {
      'vista_logica': 'detalle_venta',
      'agrupar_por': groupByMap[_gananciasGroupBy] ?? groupByMap['categoria'],
      'metricas_agrupadas': [
        {'campo': 'ganancia', 'operacion': 'sum', 'alias': 'ganancia_total'},
      ],
      'ordenar_por': '-ganancia_total',
    };

    if (_gananciasMes > 0) {
      payload['filtros'] = [
        {'campo': 'venta_fecha', 'operador': 'month', 'valor': _gananciasMes}
      ];
    }

    setState(() => _gananciasCargando = true);
    final provider = Provider.of<ReportesProvider>(context, listen: false);
    final success = await provider.ejecutarQBE(payload);
    setState(() => _gananciasCargando = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reporte de Ganancias generado con éxito')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error ?? 'Error al generar ganancias')),
      );
    }
  }

  void _ejecutarQBE() async {
    if (_selectedVistaNombre == null) return;

    final Map<String, dynamic> payload = {
      'vista_logica': _selectedVistaNombre,
      'paginacion': {
        'pagina': int.tryParse(_paginaController.text) ?? 1,
        'cantidad_por_pagina': int.tryParse(_porPaginaController.text) ?? 50,
      }
    };

    if (_filtros.isNotEmpty) {
      payload['filtros'] = _filtros.map((f) {
        final valorRaw = f['valor'].toString();
        dynamic valorFinal = valorRaw;
        // Intentar parsear a número si es numérico
        if (num.tryParse(valorRaw) != null) {
          valorFinal = num.parse(valorRaw);
        }
        return {
          'campo': f['campo'],
          'operador': f['operador'],
          'valor': valorFinal,
        };
      }).toList();
    }

    if (_agruparPor.isNotEmpty) {
      payload['agrupar_por'] = _agruparPor;
    }

    if (_metricas.isNotEmpty) {
      payload['metricas_agrupadas'] = _metricas.map((m) {
        final String campo = m['campo'];
        final String operacion = m['operacion'];
        final String alias = m['alias'].toString().trim().isNotEmpty
            ? m['alias'].toString().trim()
            : '${campo}_$operacion';
        return {
          'campo': campo,
          'operacion': operacion,
          'alias': alias,
        };
      }).toList();
    }

    if (_filtrosHaving.isNotEmpty) {
      payload['filtros_having'] = _filtrosHaving.map((h) {
        final valorRaw = h['valor'].toString();
        dynamic valorFinal = valorRaw;
        if (num.tryParse(valorRaw) != null) {
          valorFinal = num.parse(valorRaw);
        }
        return {
          'alias': h['alias'],
          'operador': h['operador'],
          'valor': valorFinal,
        };
      }).toList();
    }

    if (_ordenarPorController.text.trim().isNotEmpty) {
      payload['ordenar_por'] = _ordenarPorController.text.trim();
    }

    final provider = Provider.of<ReportesProvider>(context, listen: false);
    final success = await provider.ejecutarQBE(payload);
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error ?? 'Error al ejecutar QBE')),
      );
    }
  }

  void _ejecutarTextoNLP() async {
    final query = _textoNlpController.text.trim();
    if (query.isEmpty) return;

    final provider = Provider.of<ReportesProvider>(context, listen: false);
    final success = await provider.ejecutarNLP(query);
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error ?? 'Error al procesar consulta')),
      );
    }
  }

  // ---- RENDERIZADORES DE TABS ----

  Widget _buildQbeTab(ReportesProvider reportes) {
    if (reportes.vistas.isEmpty && reportes.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ganancias Panel
          Card(
            color: const Color(0xFFFFF8E1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFFFFE082)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.trending_up, color: Color(0xFFE65100)),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Ganancias del Mes (Acceso Rápido)',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFE65100),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Column(
                    children: [
                      DropdownButtonFormField<int>(
                        value: _gananciasMes,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Mes',
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          border: OutlineInputBorder(),
                        ),
                        items: _meses.map((m) {
                          return DropdownMenuItem<int>(
                            value: m['valor'],
                            child: Text(
                              m['label'],
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _gananciasMes = val);
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _gananciasGroupBy,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Agrupar por',
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          border: OutlineInputBorder(),
                        ),
                        items: _groupByOptions.map((g) {
                          return DropdownMenuItem<String>(
                            value: g['valor'],
                            child: Text(
                              g['label'],
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _gananciasGroupBy = val);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _gananciasCargando ? null : _generarGanancias,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFB300),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: _gananciasCargando
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.flash_on),
                      label: const Text('Generar Reporte Rápido'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Selector de Vista Lógica
          if (reportes.vistas.isNotEmpty) ...[
            const Text('Vista Lógica Base', style: AppTheme.titleSmall),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedVistaNombre,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              items: reportes.vistas.map<DropdownMenuItem<String>>((v) {
                return DropdownMenuItem<String>(
                  value: v['nombre'],
                  child: Text(v['etiqueta'] ?? v['nombre']),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) _seleccionarVista(val);
              },
            ),
            const SizedBox(height: 20),
          ],

          if (_selectedVistaData != null) ...[
            // FILTROS
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Filtros', style: AppTheme.titleSmall),
                TextButton.icon(
                  onPressed: _agregarFiltro,
                  icon: const Icon(Icons.add),
                  label: const Text('Añadir Filtro'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _filtros.length,
              itemBuilder: (ctx, i) {
                final filtro = _filtros[i];
                final campos = _obtenerCamposDisponibles();
                final ops = _obtenerOperadoresParaCampo(filtro['campo']);
                
                // Asegurarse de que el operador seleccionado sea válido para este campo
                if (!ops.contains(filtro['operador'])) {
                  filtro['operador'] = ops.first;
                }

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              DropdownButtonFormField<String>(
                                value: filtro['campo'],
                                decoration: const InputDecoration(labelText: 'Campo', border: InputBorder.none),
                                items: campos.map<DropdownMenuItem<String>>((c) {
                                  return DropdownMenuItem<String>(
                                    value: c['nombre'],
                                    child: Text(c['etiqueta'] ?? c['nombre']),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() {
                                      filtro['campo'] = val;
                                      filtro['operador'] = _obtenerOperadoresParaCampo(val).first;
                                    });
                                  }
                                },
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      value: filtro['operador'],
                                      decoration: const InputDecoration(labelText: 'Operador', border: InputBorder.none),
                                      items: ops.map<DropdownMenuItem<String>>((op) {
                                        return DropdownMenuItem<String>(
                                          value: op,
                                          child: Text(_traducirOperador(op)),
                                        );
                                      }).toList(),
                                      onChanged: (val) {
                                        if (val != null) {
                                          setState(() => filtro['operador'] = val);
                                        }
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextFormField(
                                      initialValue: filtro['valor'].toString(),
                                      decoration: const InputDecoration(labelText: 'Valor', border: InputBorder.none),
                                      onChanged: (val) => filtro['valor'] = val,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _removerFiltro(i),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const Divider(height: 32),

            // AGRUPACIÓN (GROUP BY)
            const Text('Agrupar Por (Group By)', style: AppTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _obtenerCamposAgrupables().map<Widget>((c) {
                final nombre = c['nombre'] as String;
                final etiqueta = c['etiqueta'] as String? ?? nombre;
                final isSelected = _agruparPor.contains(nombre);
                return FilterChip(
                  label: Text(etiqueta),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _agruparPor.add(nombre);
                      } else {
                        _agruparPor.remove(nombre);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const Divider(height: 32),

            // MÉTRICAS AGRUPADAS
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Métricas Agrupadas', style: AppTheme.titleSmall),
                TextButton.icon(
                  onPressed: _agregarMetrica,
                  icon: const Icon(Icons.add),
                  label: const Text('Añadir Métrica'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _metricas.length,
              itemBuilder: (ctx, i) {
                final metrica = _metricas[i];
                final campos = _obtenerCamposAgregables();

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              DropdownButtonFormField<String>(
                                value: metrica['campo'],
                                decoration: const InputDecoration(labelText: 'Campo', border: InputBorder.none),
                                items: campos.map<DropdownMenuItem<String>>((c) {
                                  return DropdownMenuItem<String>(
                                    value: c['nombre'],
                                    child: Text(c['etiqueta'] ?? c['nombre']),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => metrica['campo'] = val);
                                  }
                                },
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      value: metrica['operacion'],
                                      decoration: const InputDecoration(labelText: 'Operación', border: InputBorder.none),
                                      items: const [
                                        DropdownMenuItem(value: 'sum', child: Text('Suma (SUM)')),
                                        DropdownMenuItem(value: 'count', child: Text('Conteo (COUNT)')),
                                        DropdownMenuItem(value: 'avg', child: Text('Promedio (AVG)')),
                                        DropdownMenuItem(value: 'min', child: Text('Mínimo (MIN)')),
                                        DropdownMenuItem(value: 'max', child: Text('Máximo (MAX)')),
                                      ],
                                      onChanged: (val) {
                                        if (val != null) {
                                          setState(() => metrica['operacion'] = val);
                                        }
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextFormField(
                                      initialValue: metrica['alias'],
                                      decoration: const InputDecoration(labelText: 'Alias (Opcional)', border: InputBorder.none),
                                      onChanged: (val) => metrica['alias'] = val,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _removerMetrica(i),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const Divider(height: 32),

            // FILTROS HAVING
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Filtro Having', style: AppTheme.titleSmall),
                TextButton.icon(
                  onPressed: _agregarHaving,
                  icon: const Icon(Icons.add),
                  label: const Text('Añadir Having'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _filtrosHaving.length,
              itemBuilder: (ctx, i) {
                final having = _filtrosHaving[i];

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              TextFormField(
                                initialValue: having['alias'],
                                decoration: const InputDecoration(labelText: 'Alias Métrica', border: InputBorder.none),
                                onChanged: (val) => having['alias'] = val,
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      value: having['operador'],
                                      decoration: const InputDecoration(labelText: 'Operador', border: InputBorder.none),
                                      items: const [
                                        DropdownMenuItem(value: 'gte', child: Text('>=')),
                                        DropdownMenuItem(value: 'lte', child: Text('<=')),
                                        DropdownMenuItem(value: 'gt', child: Text('>')),
                                        DropdownMenuItem(value: 'lt', child: Text('<')),
                                        DropdownMenuItem(value: 'exact', child: Text('=')),
                                        DropdownMenuItem(value: 'neq', child: Text('!=')),
                                      ],
                                      onChanged: (val) {
                                        if (val != null) {
                                          setState(() => having['operador'] = val);
                                        }
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextFormField(
                                      initialValue: having['valor'].toString(),
                                      decoration: const InputDecoration(labelText: 'Valor', border: InputBorder.none),
                                      onChanged: (val) => having['valor'] = val,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _removerHaving(i),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const Divider(height: 32),

            // ORDEN Y PAGINACIÓN
            const Text('Ordenamiento y Paginación', style: AppTheme.titleSmall),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _ordenarPorController,
                    decoration: const InputDecoration(
                      labelText: 'Ordenar Por (ej. -fecha)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _paginaController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Página',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _porPaginaController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Por Página',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // BOTÓN EJECUTAR
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: reportes.isLoading ? null : _ejecutarQBE,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: reportes.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.play_arrow),
                label: const Text('Ejecutar Consulta (QBE)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            _buildResultados(reportes),
          ],
        ],
      ),
    );
  }

  Widget _buildTextoTab(ReportesProvider reportes) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Escribe tu consulta en lenguaje natural:',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black54),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _textoNlpController,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Ej: Dame los 5 productos más vendidos de este mes agrupados por marca.',
              border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
                borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: reportes.isLoading || _textoNlpController.text.trim().isEmpty ? null : _ejecutarTextoNLP,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: reportes.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome),
              label: const Text('Interpretar y Ejecutar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          _buildResultados(reportes),
        ],
      ),
    );
  }

  Widget _buildVozTab(ReportesProvider reportes) {
    return SingleChildScrollView(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Presiona el micrófono y dinos qué reporte necesitas',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: reportes.isLoading ? null : _toggleMic,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: _isListening ? Colors.red : AppTheme.primaryColor,
                  shape: BoxShape.circle,
                  boxShadow: _isListening
                      ? [BoxShadow(color: Colors.red.withOpacity(0.5), blurRadius: 20, spreadRadius: 5)]
                      : [BoxShadow(color: AppTheme.primaryColor.withOpacity(0.3), blurRadius: 10, spreadRadius: 2)],
                ),
                child: Icon(
                  _isListening ? Icons.mic_off : (reportes.isLoading ? Icons.hourglass_top : Icons.mic),
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _speechStatus,
              style: TextStyle(
                fontSize: 16,
                fontStyle: FontStyle.italic,
                color: _isListening ? Colors.red : Colors.black87,
                fontWeight: _isListening ? FontWeight.bold : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
            if (_lastWords.isNotEmpty && !_isListening) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Text(
                  'Texto Transcrito: "$_lastWords"',
                  style: const TextStyle(fontSize: 14, color: Colors.blue),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            _buildResultados(reportes),
          ],
        ),
      ),
    );
  }

  // ---- DYNAMIC DATATABLE RESULTS ----

  Widget _buildResultados(ReportesProvider reportes) {
    if (reportes.error != null) {
      return Card(
        color: Colors.red.shade50,
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  reportes.error!,
                  style: const TextStyle(color: Colors.red, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final resultados = reportes.resultados;
    if (resultados == null) return const SizedBox.shrink();

    final List<dynamic> datos = resultados['datos'] as List<dynamic>? ?? [];
    final paginacion = resultados['paginacion'] as Map<String, dynamic>?;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 32),
          
          // Query Interpretada NLP
          if (reportes.queryInterpretada != null) ...[
            ExpansionTile(
              leading: const Icon(Icons.code, color: AppTheme.primaryColor),
              title: const Text('Query Interpretada (NLP JSON)', style: TextStyle(fontWeight: FontWeight.bold)),
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    const JsonEncoder.withIndent('  ').convert(reportes.queryInterpretada),
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // Total de registros
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Resultados del Reporte', style: AppTheme.titleMedium),
              if (paginacion != null)
                Text(
                  'Registros: ${paginacion['total_registros'] ?? datos.length}',
                  style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.bold),
                ),
            ],
          ),
          const SizedBox(height: 12),

          if (datos.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Center(
                  child: Text('La consulta no retornó ningún registro.', style: TextStyle(color: Colors.grey)),
                ),
              ),
            )
          else
            // Tabla Dinámica
            Card(
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Container(
                constraints: const BoxConstraints(maxHeight: 400),
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: MaterialStateProperty.all(AppTheme.primaryColor.withOpacity(0.08)),
                      columns: _buildColumns(datos.first),
                      rows: _buildRows(datos),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<DataColumn> _buildColumns(Map<String, dynamic> primerFila) {
    return primerFila.keys.map((key) {
      final label = key.replaceAll('_', ' ').toUpperCase();
      return DataColumn(
        label: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
        ),
      );
    }).toList();
  }

  List<DataRow> _buildRows(List<dynamic> datos) {
    return datos.map((row) {
      final map = row as Map<String, dynamic>;
      return DataRow(
        cells: map.values.map((val) {
          String displayVal = '-';
          if (val != null) {
            if (val is double) {
              displayVal = val.toStringAsFixed(2);
            } else {
              displayVal = val.toString();
            }
          }
          return DataCell(Text(displayVal));
        }).toList(),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final reportes = Provider.of<ReportesProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(
        title: const Text('Panel de Reportes'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.grid_on), text: 'QBE'),
            Tab(icon: Icon(Icons.text_fields), text: 'Texto NLP'),
            Tab(icon: Icon(Icons.mic), text: 'Voz NLP'),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildQbeTab(reportes),
                _buildTextoTab(reportes),
                _buildVozTab(reportes),
              ],
            ),
          ),
          if (reportes.isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
