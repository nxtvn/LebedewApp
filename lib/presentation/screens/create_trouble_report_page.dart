import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../common/viewmodels/trouble_report_viewmodel.dart';
import '../common/network/network_info_facade.dart';

class CreateTroubleReportPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Störungsmeldung erstellen'),
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    return Column(
      children: [
        _buildStatusBar(context),
        // ... existing code ...
      ],
    );
  }

  Widget _buildStatusBar(BuildContext context) {
    final networkInfo = Provider.of<NetworkInfoFacade>(context, listen: false);

    return StreamBuilder<bool>(
      stream: networkInfo.isConnected,
      builder: (context, snapshot) {
        final isConnected = snapshot.data ?? false;
        return Container(
          padding: EdgeInsets.all(8),
          color: isConnected ? Colors.green : Colors.red,
          child: Row(
            children: [
              Icon(
                isConnected ? Icons.cloud_done : Icons.cloud_off,
                color: Colors.white,
              ),
              SizedBox(width: 8),
              Text(
                isConnected ? 'Online' : 'Offline',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
} 