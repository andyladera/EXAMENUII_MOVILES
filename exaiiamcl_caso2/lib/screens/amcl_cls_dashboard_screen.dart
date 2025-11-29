import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/amcl_cls_dashboard_metrics.dart';
import '../services/amcl_cls_firestore_service.dart';
import 'amcl_cls_responses_map_screen.dart';

class AMCLclsDashboardScreen extends StatelessWidget {
  final _firestoreService = AMCLclsFirestoreService();

  AMCLclsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.dashboard, size: 24),
            SizedBox(width: 8),
            Text('Dashboard en Tiempo Real'),
          ],
        ),
        backgroundColor: Colors.purple.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.map),
            tooltip: 'Ver Mapa',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AMCLclsResponsesMapScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<AMCLclsDashboardMetrics>(
        stream: _firestoreService.getDashboardMetrics(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                ],
              ),
            );
          }
          
          if (!snapshot.hasData) {
            return const Center(
              child: Text('No hay datos disponibles'),
            );
          }
          
          AMCLclsDashboardMetrics metrics = snapshot.data!;
          
          return RefreshIndicator(
            onRefresh: () async {
              // Forzar actualización
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Indicador de actualización en tiempo real
                  _buildLiveIndicator(),
                  const SizedBox(height: 16),
                  
                  // Tarjetas de estadísticas generales
                  _buildStatsCards(metrics),
                  const SizedBox(height: 24),
                  
                  // Gráfico de respuestas por encuesta
                  _buildSurveyResponsesChart(metrics),
                  const SizedBox(height: 24),
                  
                  // Gráfico de respuestas en el tiempo
                  _buildResponsesOverTimeChart(metrics),
                  const SizedBox(height: 24),
                  
                  // Respuestas recientes
                  _buildRecentResponses(metrics),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildLiveIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.5),
                  spreadRadius: 2,
                  blurRadius: 4,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Actualización en tiempo real',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.green.shade800,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatsCards(AMCLclsDashboardMetrics metrics) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Encuestas',
                metrics.totalSurveys.toString(),
                Icons.poll,
                Colors.purple,
                '${metrics.activeSurveys} activas',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Total Respuestas',
                metrics.totalResponses.toString(),
                Icons.check_circle,
                Colors.green,
                'Todos los tiempos',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Usuarios',
                metrics.totalUsers.toString(),
                Icons.people,
                Colors.blue,
                '${metrics.surveyors} encuestadores',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Promedio',
                metrics.totalSurveys > 0
                    ? (metrics.totalResponses / metrics.totalSurveys).toStringAsFixed(1)
                    : '0',
                Icons.trending_up,
                Colors.orange,
                'Respuestas/encuesta',
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
    String subtitle,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 24, color: color),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSurveyResponsesChart(AMCLclsDashboardMetrics metrics) {
    if (metrics.responsesBySurvey.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Respuestas por Encuesta',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: metrics.responsesBySurvey.values.reduce((a, b) => a > b ? a : b).toDouble() * 1.2,
                  barTouchData: BarTouchData(enabled: true),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          List<String> surveyIds = metrics.responsesBySurvey.keys.toList();
                          if (value.toInt() >= 0 && value.toInt() < surveyIds.length) {
                            String surveyId = surveyIds[value.toInt()];
                            String title = metrics.surveyTitles[surveyId] ?? '';
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                title.length > 8 ? '${title.substring(0, 8)}...' : title,
                                style: const TextStyle(fontSize: 10),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(fontSize: 12),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 1,
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: metrics.responsesBySurvey.entries.toList().asMap().entries.map((entry) {
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: entry.value.value.toDouble(),
                          color: Colors.purple.shade400,
                          width: 20,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildResponsesOverTimeChart(AMCLclsDashboardMetrics metrics) {
    if (metrics.responsesOverTime.isEmpty) {
      return const SizedBox.shrink();
    }
    
    List<FlSpot> spots = [];
    metrics.responsesOverTime.asMap().forEach((index, data) {
      spots.add(FlSpot(index.toDouble(), data['count'].toDouble()));
    });
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Respuestas en los últimos 7 días',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          int index = value.toInt();
                          if (index >= 0 && index < metrics.responsesOverTime.length) {
                            String date = metrics.responsesOverTime[index]['date'];
                            DateTime dateTime = DateTime.parse(date);
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                DateFormat('dd/MM').format(dateTime),
                                style: const TextStyle(fontSize: 10),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(fontSize: 12),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: Colors.green.shade600,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: Colors.white,
                            strokeWidth: 2,
                            strokeColor: Colors.green.shade600,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.green.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildRecentResponses(AMCLclsDashboardMetrics metrics) {
    if (metrics.recentResponses.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: Text('No hay respuestas recientes'),
          ),
        ),
      );
    }
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.access_time, size: 20),
                SizedBox(width: 8),
                Text(
                  'Respuestas Recientes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            ...metrics.recentResponses.map((response) {
              String surveyTitle = metrics.surveyTitles[response['surveyId']] ?? 'Encuesta';
              DateTime completedAt = response['completedAt'];
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            response['respondentName'],
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            surveyTitle,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      DateFormat('HH:mm').format(completedAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
