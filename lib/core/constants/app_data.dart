class Subject {
  final String id;
  final String name;
  final int price;
  final String imageUrl;

  const Subject(this.id, this.name, this.price, this.imageUrl);
}

class AppData {
  static const Map<String, List<Subject>> curriculum = {
    'First Year': [
      Subject('anatomy', 'Anatomy', 299, 'assets/images/subjects/anatomy.jpg'),
      Subject('physiology', 'Physiology', 299, 'assets/images/subjects/physiology.jpg'),
      Subject('tarika_e_tibb', 'Tarika-e-Tibb', 149, 'assets/images/subjects/history.jpg'),
      Subject('umoor_e_tabiya', 'Umoor-e-Tabiya', 149, 'assets/images/subjects/history.jpg'),
      Subject('mantiq_wa_falsafa', 'Mantiq wa Falsafa', 99, 'assets/images/subjects/history.jpg'),
      Subject('urdu_arabic', 'Urdu & Arabic', 150, 'assets/images/subjects/urdu_arabic.jpg'),
      Subject('package_first_year', 'First Year Package (Full)', 800, 'assets/images/subjects/library.jpg'),
    ],
    'Second Year': [
      Subject('community_medicine', 'Community Medicine', 150, 'assets/images/subjects/library.jpg'),
      Subject('pathology', 'Pathology', 399, 'assets/images/subjects/pathology.jpg'),
      Subject('sariyath', 'Sariyath', 199, 'assets/images/subjects/anatomy.jpg'),
      Subject('forensic_toxicology', 'Forensic & Toxicology', 149, 'assets/images/subjects/history.jpg'),
      Subject('ilmul_advia', 'Ilmul Advia', 99, 'assets/images/subjects/materia_medica.jpg'),
      Subject('mufradat', 'Mufradat', 99, 'assets/images/subjects/herbs_bowl.jpg'),
      Subject('saidla', 'Saidla', 99, 'assets/images/subjects/pharmacy.jpg'),
      Subject('murakkabat', 'Murakkabat', 99, 'assets/images/subjects/materia_medica.jpg'),
      Subject('microbiology', 'Microbiology', 49, 'assets/images/subjects/microbiology.jpg'),
      Subject('package_second_year', 'Full Second Year Combo', 999, 'assets/images/subjects/library.jpg'),
    ],
    'Final Year': [
      Subject('moalijat', 'Moalijat', 599, 'assets/images/subjects/gynecology_bp.jpg'),
      Subject('gynecology', 'Gynecology', 199, 'assets/images/subjects/gynecology_bp.jpg'),
      Subject('obstruction', 'Obstruction', 199, 'assets/images/subjects/physiology.jpg'),
      Subject('ent_ophthalmology', 'ENT & Ophthalmology', 199, 'assets/images/subjects/ent_eye.jpg'),
      Subject('pediatric', 'Pediatric', 199, 'assets/images/subjects/pediatric.jpg'),
      Subject('research_methodology', 'Research Methodology', 99, 'assets/images/subjects/research_writing.jpg'),
      Subject('ibt', 'IBT', 149, 'assets/images/subjects/pharmacy.jpg'),
      Subject('skin', 'Skin', 99, 'assets/images/subjects/skin.jpg'),
      Subject('surgery_1', 'Surgery 1', 199, 'assets/images/subjects/surgery.jpg'),
      Subject('surgery_2', 'Surgery 2', 199, 'assets/images/subjects/surgery.jpg'),
      Subject('package_final_year', 'Complete Final Year Combo', 1500, 'assets/images/subjects/library.jpg'),
    ],
  };

  static List<String> get years => curriculum.keys.toList();

  static List<Subject> getSubjectsByYear(String year) {
    return curriculum[year] ?? [];
  }
}

