import 'package:cloud_firestore/cloud_firestore.dart';

class DataSeeder {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 근육 그룹 초기화 (관리자가 한 번만 실행)
  Future<void> seedMuscleGroups() async {
final muscleGroups = [
  // 상위 부위
  {'id': 1, 'name': '가슴'},
  {'id': 2, 'name': '등'},
  {'id': 3, 'name': '어깨'},
  {'id': 4, 'name': '하체'},
  {'id': 5, 'name': '팔'},
  {'id': 6, 'name': '코어'},
];


    final batch = _db.batch();
    for (var mg in muscleGroups) {
      final docRef = _db.collection('muscle_groups'). doc('mg_${mg['id']}');
      batch. set(docRef, mg);
    }
    await batch.commit();
    print('✅ 근육 그룹 초기화 완료');
  }

  // 운동 초기화
  Future<void> seedExercises() async {
    final exercises = [
  // ---------------- 가슴 ----------------
  {
    'id': 1,
    'name': '푸쉬업',
    'imagePath':'assets/images/pushup.jpg',
    'description': '체중을 이용한 가슴 운동',
    'equipment': '체중',
    'youtubeUrl': null,
    'supportsReps': true,
    'supportsWeight': false,
    'supportsTime': false,
    'supportsDistance': false,
    'primaryMuscles': [
      {'id': 1, 'name': '가슴', 'isPrimary': true}
    ],
    'secondaryMuscles': [
      {'id': 5, 'name': '팔', 'isPrimary': false}
    ],
    'allMuscleIds': [1, 5],
  },
  {
    'id': 2,
    'name': '벤치프레스',
    'imagePath':'assets/images/benchpress.jpg',
    'description': '바벨을 이용한 대표적인 가슴 운동',
    'equipment': '바벨',
    'youtubeUrl': null,
    'supportsReps': true,
    'supportsWeight': true,
    'supportsTime': false,
    'supportsDistance': false,
    'primaryMuscles': [
      {'id': 1, 'name': '가슴', 'isPrimary': true}
    ],
    'secondaryMuscles': [
      {'id': 3, 'name': '어깨', 'isPrimary': false},
      {'id': 5, 'name': '팔', 'isPrimary': false},
    ],
    'allMuscleIds': [1, 3, 5],
  },

  // ---------------- 등 ----------------
  {
    'id': 3,
    'name': '랫풀다운',
    'imagePath':'assets/images/latpulldown.jpg',
    'description': '등 전체를 사용하는 광배근 운동',
    'equipment': '머신',
    'youtubeUrl': null,
    'supportsReps': true,
    'supportsWeight': true,
    'supportsTime': false,
    'supportsDistance': false,
    'primaryMuscles': [
      {'id': 2, 'name': '등', 'isPrimary': true}
    ],
    'secondaryMuscles': [
      {'id': 5, 'name': '팔', 'isPrimary': false}
    ],
    'allMuscleIds': [2, 5],
  },
  {
    'id': 4,
    'name': '바벨로우',
    'imagePath':'assets/images/barbellrow.jpg',
    'description': '허리를 굽혀 바벨을 당기는 등 운동',
    'equipment': '바벨',
    'youtubeUrl': null,
    'supportsReps': true,
    'supportsWeight': true,
    'supportsTime': false,
    'supportsDistance': false,
    'primaryMuscles': [
      {'id': 2, 'name': '등', 'isPrimary': true}
    ],
    'secondaryMuscles': [
      {'id': 6, 'name': '코어', 'isPrimary': false},
      {'id': 5, 'name': '팔', 'isPrimary': false},
    ],
    'allMuscleIds': [2, 6, 5],
  },

  // ---------------- 어깨 ----------------
  {
    'id': 5,
    'name': '숄더프레스',
    'imagePath':'assets/images/shoulderpress.jpg',
    'description': '머리 위로 무게를 밀어 올리는 어깨 운동',
    'equipment': '덤벨 또는 머신',
    'youtubeUrl': null,
    'supportsReps': true,
    'supportsWeight': true,
    'supportsTime': false,
    'supportsDistance': false,
    'primaryMuscles': [
      {'id': 3, 'name': '어깨', 'isPrimary': true}
    ],
    'secondaryMuscles': [
      {'id': 5, 'name': '팔', 'isPrimary': false},
      {'id': 6, 'name': '코어', 'isPrimary': false}
    ],
    'allMuscleIds': [3, 5, 6],
  },
  {
    'id': 6,
    'name': '사이드 레터럴 레이즈',
    'imagePath':'assets/images/side_lateral_raise.jpg',
    'description': '어깨 측면을 강화하는 운동',
    'equipment': '덤벨',
    'youtubeUrl': null,
    'supportsReps': true,
    'supportsWeight': true,
    'supportsTime': false,
    'supportsDistance': false,
    'primaryMuscles': [
      {'id': 3, 'name': '어깨', 'isPrimary': true}
    ],
    'secondaryMuscles': [],
    'allMuscleIds': [3],
  },

  // ---------------- 하체 ----------------
  {
    'id': 7,
    'name': '스쿼트',
    'imagePath':'assets/images/squat.jpg',
    'description': '하체 전체를 사용하는 대표 운동',
    'equipment': '체중 또는 바벨',
    'youtubeUrl': null,
    'supportsReps': true,
    'supportsWeight': true,
    'supportsTime': false,
    'supportsDistance': false,
    'primaryMuscles': [
      {'id': 4, 'name': '하체', 'isPrimary': true}
    ],
    'secondaryMuscles': [
      {'id': 6, 'name': '코어', 'isPrimary': false}
    ],
    'allMuscleIds': [4, 6],
  },
  {
    'id': 8,
    'name': '레그프레스',
    'imagePath':'assets/images/legpress.jpg',
    'description': '머신으로 수행하는 하체 근력 운동',
    'equipment': '머신',
    'youtubeUrl': null,
    'supportsReps': true,
    'supportsWeight': true,
    'supportsTime': false,
    'supportsDistance': false,
    'primaryMuscles': [
      {'id': 4, 'name': '하체', 'isPrimary': true}
    ],
    'secondaryMuscles': [],
    'allMuscleIds': [4],
  },

  // ---------------- 팔 ----------------
  {
    'id': 9,
    'name': '바벨컬',
    'imagePath':'assets/images/barbellcurl.jpg',
    'description': '팔 이두근을 강화하는 운동',
    'equipment': '바벨',
    'youtubeUrl': null,
    'supportsReps': true,
    'supportsWeight': true,
    'supportsTime': false,
    'supportsDistance': false,
    'primaryMuscles': [
      {'id': 5, 'name': '팔', 'isPrimary': true},
    ],
    'secondaryMuscles': [],
    'allMuscleIds': [5],
  },
  {
    'id': 10,
    'name': '트라이셉스 푸쉬다운',
    'imagePath':'assets/images/tricep_pushdown.jpg',
    'description': '케이블을 당겨 삼두를 강화하는 운동',
    'equipment': '케이블 머신',
    'youtubeUrl': null,
    'supportsReps': true,
    'supportsWeight': true,
    'supportsTime': false,
    'supportsDistance': false,
    'primaryMuscles': [
      {'id': 5, 'name': '팔', 'isPrimary': true},
    ],
    'secondaryMuscles': [
      {'id': 3, 'name': '어깨', 'isPrimary': false}
    ],
    'allMuscleIds': [5, 3],
  },

  // ---------------- 코어 ----------------
  {
    'id': 11,
    'name': '플랭크',
    'imagePath':'assets/images/plank.jpg',
    'description': '코어 전체를 버티는 운동',
    'equipment': '체중',
    'youtubeUrl': null,
    'supportsReps': false,
    'supportsWeight': false,
    'supportsTime': true,
    'supportsDistance': false,
    'primaryMuscles': [
      {'id': 6, 'name': '코어', 'isPrimary': true},
    ],
    'secondaryMuscles': [],
    'allMuscleIds': [6],
  },
  {
    'id': 12,
    'name': '크런치',
    'imagePath':'assets/images/crunch.jpg',
    'description': '복직근 위주의 코어 운동',
    'equipment': '체중',
    'youtubeUrl': null,
    'supportsReps': true,
    'supportsWeight': false,
    'supportsTime': false,
    'supportsDistance': false,
    'primaryMuscles': [
      {'id': 6, 'name': '코어', 'isPrimary': true},
    ],
    'secondaryMuscles': [],
    'allMuscleIds': [6],
  },
];


    final batch = _db.batch();
    for (var ex in exercises) {
      final docRef = _db.collection('exercises').doc('ex_${ex['id']}');
      batch.set(docRef, ex);
    }
    await batch. commit();
    print('✅ 운동 데이터 초기화 완료');
  }
}