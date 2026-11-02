# Data Model: 005 구조화 속성·사진 분석

값 목록(코드·라벨)의 단일 진실 원천은 `lib/data/models/item_attributes.dart`다. 이 문서는 저장 규칙과 표를 요약한다.

## 1. Item 추가 필드 (클래스 끝에 선언)

| 필드 | 타입 | 기본값 | 규칙 |
|---|---|---|---|
| `subType` | `String?` | null | 세부 종류 코드. `category`에 속하지 않는 코드는 저장 시 null로 정리한다 |
| `colors` | `List<String>` | `[]` | 색상 코드 최대 3개, 첫 값이 대표 색상. 알 수 없는 코드·중복 제거 |
| `seasons` | `List<Season>` | `[]` | enum 순서로 정규화. 비어 있으면 "정하지 않음" |
| `material` | `String?` | null | 소재 코드 |
| `pattern` | `String?` | null | 패턴 코드 |
| `cutoutPath` | `String?` | null | 배경 제거본 sandbox 상대 경로(`items/{id}_cutout.png`). `imagePath`가 없으면 null |

- 세부 종류·색상·소재·패턴은 **문자열 코드**로 저장한다. ordinal enum과 달리 값 추가·순서 변경이 저장 데이터를 바꾸지 않는다.
  코드는 바꾸거나 재사용하지 않는다(폐기 시 카탈로그에서 숨기고 읽기는 유지).
- `Season`은 4값 고정 enum(`spring, summer, autumn, winter`)이다. ordinal 저장이므로 끝에만 추가한다.
- `ItemPurpose`는 기존 `sport` 뒤에 `daily, work, outing, formal, travel, home`을 추가한다(ordinal 유지). 표시 순서는 `ItemPurpose.selectable`.
- 구 데이터는 필드가 없으므로 위 기본값으로 읽힌다. 의미가 바뀌는 변경이 없어 `storageVersion`은 올리지 않는다.

## 2. 카탈로그 요약

| 축 | 코드 → 라벨 |
|---|---|
| 세부 종류 · 상의 | tshirt 티셔츠, shirt 셔츠·블라우스, knit 니트, sweatshirt 맨투맨, hoodie 후드티, sleeveless 민소매, polo 폴로 |
| 세부 종류 · 하의 | jeans 청바지, slacks 슬랙스, cotton_pants 면바지, shorts 반바지, skirt 스커트, jogger 트레이닝 바지, leggings 레깅스 |
| 세부 종류 · 아우터 | coat 코트, padding 패딩, jacket 재킷, blazer 블레이저, jumper 점퍼, cardigan 카디건, vest 조끼 |
| 세부 종류 · 원피스 | dress 원피스, jumpsuit 점프수트 |
| 세부 종류 · 신발 | sneakers 운동화, dress_shoes 구두, boots 부츠, sandals 샌들·슬리퍼, loafers 로퍼 |
| 세부 종류 · 가방 | backpack 백팩, shoulder_bag 숄더백, tote_bag 토트백, cross_bag 크로스백, clutch 클러치 |
| 세부 종류 · 액세서리 | hat 모자, scarf 머플러·스카프, belt 벨트, gloves 장갑, socks 양말, jewelry 주얼리, watch 시계, eyewear 안경·선글라스, tie 넥타이 |
| 색상 | black 검정, white 흰색, gray 회색, ivory 아이보리, beige 베이지, camel 카멜, brown 브라운, navy 네이비, blue 파랑, skyblue 하늘, denim 데님, green 초록, khaki 카키, red 빨강, burgundy 버건디, pink 분홍, purple 보라, yellow 노랑, orange 주황 |
| 소재 | cotton 면, wool 울·니트, cashmere 캐시미어, denim 데님, leather 가죽, linen 린넨, silk 실크, synthetic 기능성·합성 |
| 패턴 | solid 무지, stripe 스트라이프, check 체크, dot 도트, graphic 그래픽·로고, floral 플로럴 |

세부 종류마다 **추천 계절**(예: padding→겨울, shorts→여름)이 있으며 정리하기·등록 화면에서 계절이 비어 있을 때 제안 칩으로만 쓴다.

## 3. 사진 분류 라벨 매핑 (iOS Vision `VNClassifyImageRequest`, FR-514)

신뢰도 0.6 이상만 사용한다. 매핑에 없는 라벨(`clothing`, `people` 등)은 무시한다.

| 라벨 | 종류 | 세부 종류 |
|---|---|---|
| jeans | 하의 | jeans |
| hoodie | 상의 | hoodie |
| jacket | 아우터 | jacket |
| suit | 아우터 | blazer |
| sneaker | 신발 | sneakers |
| boot | 신발 | boots |
| sandal | 신발 | sandals |
| shoes, footwear | 신발 | — |
| backpack | 가방 | backpack |
| bag, purse, handbag | 가방 | — |
| hat, baseball_hat, sunhat, cowboy_hat | 액세서리 | hat |
| scarf | 액세서리 | scarf |
| glove | 액세서리 | gloves |
| sock | 액세서리 | socks |
| sunglasses | 액세서리 | eyewear |
| jewelry | 액세서리 | jewelry |
| watch | 액세서리 | watch |
| necktie, bowtie | 액세서리 | tie |

Android ML Kit 기본 라벨(소문자·밑줄로 바꿔 같은 표를 쓴다): sneakers(신발·운동화), shoe(신발), shorts(하의·반바지),
leggings(하의·레깅스), dress·gown(원피스·원피스), outerwear(아우터), blazer(아우터·블레이저), jersey(상의), cap·beanie(액세서리·모자),
tie(액세서리·넥타이), handbag(가방), glasses(액세서리·안경), necklace·bracelet·bangle·jewellery(액세서리·주얼리).
jeans·jacket·hat·scarf·sunglasses·bag은 위 행과 같다. 소재 라벨 denim·wool·leather·cotton은 같은 이름의 소재 코드로 제안한다.

## 4. 세탁 그룹 (FR-512, 저장 안 함)

판정 순서: ① `careMethod`가 손세탁·드라이클리닝 → `handCare` ② 세부 종류 `jeans` 또는 대표 색상·소재 `denim` → `denim`
③ 대표 색상이 밝은 계열(white·ivory·beige·skyblue·pink·yellow) → `light` ④ 그 외 색상 → `dark` ⑤ 색상 없음 → `unsorted`.

## 5. UserPreferences 추가 필드

| 필드 | 타입 | 기본값 | 의미 |
|---|---|---|---|
| `removeBackground` | bool | true | iOS 17+ 사진 배경 자동 제거(FR-513) |
| `onDeviceAi` | bool | false | iOS 27 기기 내 AI 분석(FR-515) |

## 6. 백업 형식 v2

- `formatVersion` 2. 옷 레코드에 `subType`, `colors`, `seasons`, `material`, `pattern`, `cutoutImage`(아카이브 참조 `images/{id}_cutout.png` 또는 null),
  설정에 `removeBackground`, `onDeviceAi`를 추가한다.
- v1 백업은 위 필드를 기본값으로 읽는다. 알 수 없는 색상·세부 종류 코드는 버리고(손 편집 방어) 종류와 맞지 않는 세부 종류는 null로 정리한다.
