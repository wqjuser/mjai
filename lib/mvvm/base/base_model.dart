abstract class BaseModel {
  Map<String, dynamic> toJson();

  BaseModel fromJson(Map<String, dynamic> json);
}
