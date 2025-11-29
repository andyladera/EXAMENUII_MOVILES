import 'package:hive/hive.dart';
import '../models/amcl_cls_response.dart';

// Adaptador Hive para AMCLclsResponse
// Run: flutter packages pub run build_runner build
// typeId debe ser único para cada clase

class AMCLclsResponseAdapter extends TypeAdapter<AMCLclsResponse> {
  @override
  final int typeId = 0; // ID único para este adaptador

  @override
  AMCLclsResponse read(BinaryReader reader) {
    String? idValue = reader.read() as String?;
    return AMCLclsResponse(
      id: idValue ?? '',
      surveyId: reader.read() as String,
      userId: reader.read() as String,
      respondentName: reader.read() as String,
      respondentEmail: reader.read() as String?,
      answers: Map<String, dynamic>.from(reader.read() as Map),
      completedAt: reader.read() as DateTime,
      location: reader.read() as String?,
    );
  }

  @override
  void write(BinaryWriter writer, AMCLclsResponse obj) {
    writer.write(obj.id);
    writer.write(obj.surveyId);
    writer.write(obj.userId);
    writer.write(obj.respondentName);
    writer.write(obj.respondentEmail);
    writer.write(obj.answers);
    writer.write(obj.completedAt);
    writer.write(obj.location);
  }
}
