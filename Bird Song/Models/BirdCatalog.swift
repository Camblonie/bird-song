//
//  BirdCatalog.swift
//  Bird Song
//
//  Static catalog of ~80 common US Midwest bird species.
//  imageName matches the asset name in Assets.xcassets.
//  birdNETLabel matches the BirdNET-Analyzer label format: "CommonName_ScientificName"
//

import Foundation

/// Represents a single bird species in the catalog.
struct Bird: Identifiable, Hashable {
    let id: String           // BirdNET label — unique key
    let commonName: String
    let scientificName: String
    let birdNETLabel: String // e.g. "American Robin_Turdus migratorius"
    let imageName: String    // asset name in xcassets
    let description: String  // short natural history blurb
}

/// Central catalog of Midwest bird species. Used for label matching and display.
enum BirdCatalog {

    /// All species in the catalog, keyed by birdNETLabel for fast lookup.
    static let all: [Bird] = [
        Bird(id: "american_robin", commonName: "American Robin",
             scientificName: "Turdus migratorius",
             birdNETLabel: "American Robin_Turdus migratorius",
             imageName: "bird_american_robin",
             description: "One of the most familiar North American songbirds. Often seen pulling earthworms from lawns."),

        Bird(id: "northern_cardinal", commonName: "Northern Cardinal",
             scientificName: "Cardinalis cardinalis",
             birdNETLabel: "Northern Cardinal_Cardinalis cardinalis",
             imageName: "bird_northern_cardinal",
             description: "The brilliant red male is unmistakable. Both sexes sing year-round."),

        Bird(id: "red_winged_blackbird", commonName: "Red-winged Blackbird",
             scientificName: "Agelaius phoeniceus",
             birdNETLabel: "Red-winged Blackbird_Agelaius phoeniceus",
             imageName: "bird_red_winged_blackbird",
             description: "Abundant marsh bird. Males display bright red shoulder patches and sing a raspy 'conk-la-ree'."),

        Bird(id: "song_sparrow", commonName: "Song Sparrow",
             scientificName: "Melospiza melodia",
             birdNETLabel: "Song Sparrow_Melospiza melodia",
             imageName: "bird_song_sparrow",
             description: "One of North America's most studied birds, known for its musical and varied song."),

        Bird(id: "house_finch", commonName: "House Finch",
             scientificName: "Haemorhous mexicanus",
             birdNETLabel: "House Finch_Haemorhous mexicanus",
             imageName: "bird_house_finch",
             description: "Common at feeders. Males have a rosy-red head and breast."),

        Bird(id: "american_goldfinch", commonName: "American Goldfinch",
             scientificName: "Spinus tristis",
             birdNETLabel: "American Goldfinch_Spinus tristis",
             imageName: "bird_american_goldfinch",
             description: "Bright yellow males are a summer staple. Often seen on thistle feeders."),

        Bird(id: "black_capped_chickadee", commonName: "Black-capped Chickadee",
             scientificName: "Poecile atricapillus",
             birdNETLabel: "Black-capped Chickadee_Poecile atricapillus",
             imageName: "bird_black_capped_chickadee",
             description: "Energetic and curious. Famous for its 'chick-a-dee-dee-dee' alarm call."),

        Bird(id: "tufted_titmouse", commonName: "Tufted Titmouse",
             scientificName: "Baeolophus bicolor",
             birdNETLabel: "Tufted Titmouse_Baeolophus bicolor",
             imageName: "bird_tufted_titmouse",
             description: "Small but bold gray bird with a jaunty crest. Frequent feeder visitor."),

        Bird(id: "white_breasted_nuthatch", commonName: "White-breasted Nuthatch",
             scientificName: "Sitta carolinensis",
             birdNETLabel: "White-breasted Nuthatch_Sitta carolinensis",
             imageName: "bird_white_breasted_nuthatch",
             description: "Creeps headfirst down tree trunks probing for insects. Gives a nasal 'yank-yank'."),

        Bird(id: "downy_woodpecker", commonName: "Downy Woodpecker",
             scientificName: "Dryobates pubescens",
             birdNETLabel: "Downy Woodpecker_Dryobates pubescens",
             imageName: "bird_downy_woodpecker",
             description: "Smallest woodpecker in North America. Common at suet feeders."),

        Bird(id: "hairy_woodpecker", commonName: "Hairy Woodpecker",
             scientificName: "Dryobates villosus",
             birdNETLabel: "Hairy Woodpecker_Dryobates villosus",
             imageName: "bird_hairy_woodpecker",
             description: "Larger look-alike of the Downy. Prefers mature forest."),

        Bird(id: "red_bellied_woodpecker", commonName: "Red-bellied Woodpecker",
             scientificName: "Melanerpes carolinus",
             birdNETLabel: "Red-bellied Woodpecker_Melanerpes carolinus",
             imageName: "bird_red_bellied_woodpecker",
             description: "Noisy woodland woodpecker with a red cap. Expanding northward."),

        Bird(id: "pileated_woodpecker", commonName: "Pileated Woodpecker",
             scientificName: "Dryocopus pileatus",
             birdNETLabel: "Pileated Woodpecker_Dryocopus pileatus",
             imageName: "bird_pileated_woodpecker",
             description: "Crow-sized woodpecker. Chisels large rectangular cavities in dead trees."),

        Bird(id: "blue_jay", commonName: "Blue Jay",
             scientificName: "Cyanocitta cristata",
             birdNETLabel: "Blue Jay_Cyanocitta cristata",
             imageName: "bird_blue_jay",
             description: "Bold and intelligent. Mimics hawks and caches acorns for winter."),

        Bird(id: "american_crow", commonName: "American Crow",
             scientificName: "Corvus brachyrhynchos",
             birdNETLabel: "American Crow_Corvus brachyrhynchos",
             imageName: "bird_american_crow",
             description: "Highly intelligent and adaptable. Forms large communal roosts in winter."),

        Bird(id: "common_grackle", commonName: "Common Grackle",
             scientificName: "Quiscalus quiscula",
             birdNETLabel: "Common Grackle_Quiscalus quiscula",
             imageName: "bird_common_grackle",
             description: "Iridescent blackbird with a long keel-shaped tail. Often flocks in thousands."),

        Bird(id: "european_starling", commonName: "European Starling",
             scientificName: "Sturnus vulgaris",
             birdNETLabel: "European Starling_Sturnus vulgaris",
             imageName: "bird_european_starling",
             description: "Introduced species. Superb mimic and forms huge murmurations in fall."),

        Bird(id: "house_sparrow", commonName: "House Sparrow",
             scientificName: "Passer domesticus",
             birdNETLabel: "House Sparrow_Passer domesticus",
             imageName: "bird_house_sparrow",
             description: "Introduced from Europe. One of the world's most widespread birds."),

        Bird(id: "mourning_dove", commonName: "Mourning Dove",
             scientificName: "Zenaida macroura",
             birdNETLabel: "Mourning Dove_Zenaida macroura",
             imageName: "bird_mourning_dove",
             description: "Soft cooing call is a familiar sound of suburban mornings."),

        Bird(id: "rock_pigeon", commonName: "Rock Pigeon",
             scientificName: "Columba livia",
             birdNETLabel: "Rock Pigeon_Columba livia",
             imageName: "bird_rock_pigeon",
             description: "Domesticated ancestor of racing pigeons. Thrives in cities."),

        Bird(id: "barn_swallow", commonName: "Barn Swallow",
             scientificName: "Hirundo rustica",
             birdNETLabel: "Barn Swallow_Hirundo rustica",
             imageName: "bird_barn_swallow",
             description: "Graceful aerial insectivore with a deeply forked tail."),

        Bird(id: "tree_swallow", commonName: "Tree Swallow",
             scientificName: "Tachycineta bicolor",
             birdNETLabel: "Tree Swallow_Tachycineta bicolor",
             imageName: "bird_tree_swallow",
             description: "Iridescent blue-green swallow. Readily uses nest boxes near water."),

        Bird(id: "chimney_swift", commonName: "Chimney Swift",
             scientificName: "Chaetura pelagica",
             birdNETLabel: "Chimney Swift_Chaetura pelagica",
             imageName: "bird_chimney_swift",
             description: "Spends almost its entire life in the air. Nests in chimneys."),

        Bird(id: "ruby_throated_hummingbird", commonName: "Ruby-throated Hummingbird",
             scientificName: "Archilochus colubris",
             birdNETLabel: "Ruby-throated Hummingbird_Archilochus colubris",
             imageName: "bird_ruby_throated_hummingbird",
             description: "The only hummingbird breeding in the eastern US. Hovers at flowers and feeders."),

        Bird(id: "eastern_bluebird", commonName: "Eastern Bluebird",
             scientificName: "Sialia sialis",
             birdNETLabel: "Eastern Bluebird_Sialia sialis",
             imageName: "bird_eastern_bluebird",
             description: "Brilliant blue and orange thrush. Populations recovered with nest-box programs."),

        Bird(id: "american_tree_sparrow", commonName: "American Tree Sparrow",
             scientificName: "Spizelloides arborea",
             birdNETLabel: "American Tree Sparrow_Spizelloides arborea",
             imageName: "bird_american_tree_sparrow",
             description: "Winter visitor to the Midwest. Has a rufous cap and chest spot."),

        Bird(id: "dark_eyed_junco", commonName: "Dark-eyed Junco",
             scientificName: "Junco hyemalis",
             birdNETLabel: "Dark-eyed Junco_Junco hyemalis",
             imageName: "bird_dark_eyed_junco",
             description: "Common winter sparrow. Flash of white outer tail feathers in flight."),

        Bird(id: "white_throated_sparrow", commonName: "White-throated Sparrow",
             scientificName: "Zonotrichia albicollis",
             birdNETLabel: "White-throated Sparrow_Zonotrichia albicollis",
             imageName: "bird_white_throated_sparrow",
             description: "Sings a clear 'Oh sweet Canada Canada'. Common winter visitor."),

        Bird(id: "chipping_sparrow", commonName: "Chipping Sparrow",
             scientificName: "Spizella passerina",
             birdNETLabel: "Chipping Sparrow_Spizella passerina",
             imageName: "bird_chipping_sparrow",
             description: "Tiny sparrow with a rufous cap. Often nests in ornamental shrubs."),

        Bird(id: "field_sparrow", commonName: "Field Sparrow",
             scientificName: "Spizella pusilla",
             birdNETLabel: "Field Sparrow_Spizella pusilla",
             imageName: "bird_field_sparrow",
             description: "Pink bill and plaintive accelerating song in old fields."),

        Bird(id: "eastern_towhee", commonName: "Eastern Towhee",
             scientificName: "Pipilo erythrophthalmus",
             birdNETLabel: "Eastern Towhee_Pipilo erythrophthalmus",
             imageName: "bird_eastern_towhee",
             description: "Large sparrow scratching in leaf litter. Calls 'drink-your-teeea'."),

        Bird(id: "common_yellowthroat", commonName: "Common Yellowthroat",
             scientificName: "Geothlypis trichas",
             birdNETLabel: "Common Yellowthroat_Geothlypis trichas",
             imageName: "bird_common_yellowthroat",
             description: "Male wears a black mask. Sings 'witchety-witchety-witchety' in marshes."),

        Bird(id: "yellow_warbler", commonName: "Yellow Warbler",
             scientificName: "Setophaga petechia",
             birdNETLabel: "Yellow Warbler_Setophaga petechia",
             imageName: "bird_yellow_warbler",
             description: "Brilliant yellow warbler common in willows and wet shrubby areas."),

        Bird(id: "american_yellow_warbler", commonName: "American Redstart",
             scientificName: "Setophaga ruticilla",
             birdNETLabel: "American Redstart_Setophaga ruticilla",
             imageName: "bird_american_redstart",
             description: "Flits through foliage flashing orange wing and tail patches to startle insects."),

        Bird(id: "ovenbird", commonName: "Ovenbird",
             scientificName: "Seiurus aurocapilla",
             birdNETLabel: "Ovenbird_Seiurus aurocapilla",
             imageName: "bird_ovenbird",
             description: "Forest-floor warbler with a loud 'teacher-teacher-teacher' song."),

        Bird(id: "red_eyed_vireo", commonName: "Red-eyed Vireo",
             scientificName: "Vireo olivaceus",
             birdNETLabel: "Red-eyed Vireo_Vireo olivaceus",
             imageName: "bird_red_eyed_vireo",
             description: "Sings persistently all day from forest canopy. One of the most common breeding birds."),

        Bird(id: "warbling_vireo", commonName: "Warbling Vireo",
             scientificName: "Vireo gilvus",
             birdNETLabel: "Warbling Vireo_Vireo gilvus",
             imageName: "bird_warbling_vireo",
             description: "Plain gray-green vireo with a cheerful rambling song in riparian trees."),

        Bird(id: "eastern_phoebe", commonName: "Eastern Phoebe",
             scientificName: "Sayornis phoebe",
             birdNETLabel: "Eastern Phoebe_Sayornis phoebe",
             imageName: "bird_eastern_phoebe",
             description: "Early spring flycatcher. Wags its tail and calls its own name 'fee-bee'."),

        Bird(id: "eastern_wood_pewee", commonName: "Eastern Wood-Pewee",
             scientificName: "Contopus virens",
             birdNETLabel: "Eastern Wood-Pewee_Contopus virens",
             imageName: "bird_eastern_wood_pewee",
             description: "Sings a plaintive 'pee-a-wee' from mid-canopy perches."),

        Bird(id: "great_crested_flycatcher", commonName: "Great Crested Flycatcher",
             scientificName: "Myiarchus crinitus",
             birdNETLabel: "Great Crested Flycatcher_Myiarchus crinitus",
             imageName: "bird_great_crested_flycatcher",
             description: "Cavity-nesting flycatcher with a loud wheep call. Often uses shed snakeskin in nest."),

        Bird(id: "eastern_kingbird", commonName: "Eastern Kingbird",
             scientificName: "Tyrannus tyrannus",
             birdNETLabel: "Eastern Kingbird_Tyrannus tyrannus",
             imageName: "bird_eastern_kingbird",
             description: "Aggressive flycatcher that chases hawks and crows from its territory."),

        Bird(id: "house_wren", commonName: "House Wren",
             scientificName: "Troglodytes aedon",
             birdNETLabel: "House Wren_Troglodytes aedon",
             imageName: "bird_house_wren",
             description: "Tiny but loud. Fills nest boxes with twigs and sings an exuberant bubbling song."),

        Bird(id: "carolina_wren", commonName: "Carolina Wren",
             scientificName: "Thryothorus ludovicianus",
             birdNETLabel: "Carolina Wren_Thryothorus ludovicianus",
             imageName: "bird_carolina_wren",
             description: "Loud 'teakettle-teakettle' song belies its small size."),

        Bird(id: "marsh_wren", commonName: "Marsh Wren",
             scientificName: "Cistothorus palustris",
             birdNETLabel: "Marsh Wren_Cistothorus palustris",
             imageName: "bird_marsh_wren",
             description: "Rattling song from cattail marshes. Builds multiple dummy nests."),

        Bird(id: "cedar_waxwing", commonName: "Cedar Waxwing",
             scientificName: "Bombycilla cedrorum",
             birdNETLabel: "Cedar Waxwing_Bombycilla cedrorum",
             imageName: "bird_cedar_waxwing",
             description: "Elegant masked bird with red waxy wingtips. Travels in flocks to find berries."),

        Bird(id: "baltimore_oriole", commonName: "Baltimore Oriole",
             scientificName: "Icterus galbula",
             birdNETLabel: "Baltimore Oriole_Icterus galbula",
             imageName: "bird_baltimore_oriole",
             description: "Flame-orange male weaves a hanging nest. Attracted to orange halves and nectar."),

        Bird(id: "orchard_oriole", commonName: "Orchard Oriole",
             scientificName: "Icterus spurius",
             birdNETLabel: "Orchard Oriole_Icterus spurius",
             imageName: "bird_orchard_oriole",
             description: "Smallest North American oriole. Chestnut-and-black male. Prefers orchards and forest edges."),

        Bird(id: "rose_breasted_grosbeak", commonName: "Rose-breasted Grosbeak",
             scientificName: "Pheucticus ludovicianus",
             birdNETLabel: "Rose-breasted Grosbeak_Pheucticus ludovicianus",
             imageName: "bird_rose_breasted_grosbeak",
             description: "Male has a rose-red triangle on white breast. Robin-like song, sweeter and faster."),

        Bird(id: "indigo_bunting", commonName: "Indigo Bunting",
             scientificName: "Passerina cyanea",
             birdNETLabel: "Indigo Bunting_Passerina cyanea",
             imageName: "bird_indigo_bunting",
             description: "Brilliant blue male sings from prominent perches along roadsides all summer."),

        Bird(id: "bobolink", commonName: "Bobolink",
             scientificName: "Dolichonyx oryzivorus",
             birdNETLabel: "Bobolink_Dolichonyx oryzivorus",
             imageName: "bird_bobolink",
             description: "Bubbling R2-D2-like song over meadows. Male is black below, white and yellow above."),

        Bird(id: "eastern_meadowlark", commonName: "Eastern Meadowlark",
             scientificName: "Sturnella magna",
             birdNETLabel: "Eastern Meadowlark_Sturnella magna",
             imageName: "bird_eastern_meadowlark",
             description: "Flute-like song from fence posts in open grasslands. Yellow breast with black V."),

        Bird(id: "brown_headed_cowbird", commonName: "Brown-headed Cowbird",
             scientificName: "Molothrus ater",
             birdNETLabel: "Brown-headed Cowbird_Molothrus ater",
             imageName: "bird_brown_headed_cowbird",
             description: "Brood parasite that lays eggs in other birds' nests."),

        Bird(id: "killdeer", commonName: "Killdeer",
             scientificName: "Charadrius vociferus",
             birdNETLabel: "Killdeer_Charadrius vociferus",
             imageName: "bird_killdeer",
             description: "Loud 'kill-deer' call. Performs broken-wing display to lead predators away from nest."),

        Bird(id: "american_woodcock", commonName: "American Woodcock",
             scientificName: "Scolopax minor",
             birdNETLabel: "American Woodcock_Scolopax minor",
             imageName: "bird_american_woodcock",
             description: "Chunky shorebird of moist woodlands. Famous for its spiraling spring sky-dance."),

        Bird(id: "sandhill_crane", commonName: "Sandhill Crane",
             scientificName: "Antigone canadensis",
             birdNETLabel: "Sandhill Crane_Antigone canadensis",
             imageName: "bird_sandhill_crane",
             description: "Prehistoric rattling call carries for miles. Large flocks migrate through the Midwest."),

        Bird(id: "great_blue_heron", commonName: "Great Blue Heron",
             scientificName: "Ardea herodias",
             birdNETLabel: "Great Blue Heron_Ardea herodias",
             imageName: "bird_great_blue_heron",
             description: "Tallest North American heron. Stands motionless at water's edge hunting fish."),

        Bird(id: "great_egret", commonName: "Great Egret",
             scientificName: "Ardea alba",
             birdNETLabel: "Great Egret_Ardea alba",
             imageName: "bird_great_egret",
             description: "All-white heron with a yellow bill and black legs."),

        Bird(id: "canada_goose", commonName: "Canada Goose",
             scientificName: "Branta canadensis",
             birdNETLabel: "Canada Goose_Branta canadensis",
             imageName: "bird_canada_goose",
             description: "Familiar honking goose. Many populations are now year-round residents."),

        Bird(id: "mallard", commonName: "Mallard",
             scientificName: "Anas platyrhynchos",
             birdNETLabel: "Mallard_Anas platyrhynchos",
             imageName: "bird_mallard",
             description: "Most abundant duck in the world. Male has an iridescent green head."),

        Bird(id: "wood_duck", commonName: "Wood Duck",
             scientificName: "Aix sponsa",
             birdNETLabel: "Wood Duck_Aix sponsa",
             imageName: "bird_wood_duck",
             description: "One of North America's most colorful ducks. Nests in tree cavities near water."),

        Bird(id: "red_tailed_hawk", commonName: "Red-tailed Hawk",
             scientificName: "Buteo jamaicensis",
             birdNETLabel: "Red-tailed Hawk_Buteo jamaicensis",
             imageName: "bird_red_tailed_hawk",
             description: "Most common hawk in North America. The classic 'eagle scream' in movies is actually this hawk."),

        Bird(id: "cooper_hawk", commonName: "Cooper's Hawk",
             scientificName: "Accipiter cooperii",
             birdNETLabel: "Cooper's Hawk_Accipiter cooperii",
             imageName: "bird_coopers_hawk",
             description: "Agile bird-hunting hawk. Frequents backyard feeders looking for prey."),

        Bird(id: "sharp_shinned_hawk", commonName: "Sharp-shinned Hawk",
             scientificName: "Accipiter striatus",
             birdNETLabel: "Sharp-shinned Hawk_Accipiter striatus",
             imageName: "bird_sharp_shinned_hawk",
             description: "Smallest accipiter. Quick and agile ambush hunter of small songbirds."),

        Bird(id: "osprey", commonName: "Osprey",
             scientificName: "Pandion haliaetus",
             birdNETLabel: "Osprey_Pandion haliaetus",
             imageName: "bird_osprey",
             description: "Fish-eating raptor. Plunges feet-first into water to catch fish."),

        Bird(id: "bald_eagle", commonName: "Bald Eagle",
             scientificName: "Haliaeetus leucocephalus",
             birdNETLabel: "Bald Eagle_Haliaeetus leucocephalus",
             imageName: "bird_bald_eagle",
             description: "National bird of the US. White head and tail at maturity. Recovered from near extinction."),

        Bird(id: "eastern_screech_owl", commonName: "Eastern Screech-Owl",
             scientificName: "Megascops asio",
             birdNETLabel: "Eastern Screech-Owl_Megascops asio",
             imageName: "bird_eastern_screech_owl",
             description: "Small eared owl with a haunting descending whinny. Uses nest boxes."),

        Bird(id: "great_horned_owl", commonName: "Great Horned Owl",
             scientificName: "Bubo virginianus",
             birdNETLabel: "Great Horned Owl_Bubo virginianus",
             imageName: "bird_great_horned_owl",
             description: "Most powerful owl in North America. Begins nesting in January."),

        Bird(id: "barred_owl", commonName: "Barred Owl",
             scientificName: "Strix varia",
             birdNETLabel: "Barred Owl_Strix varia",
             imageName: "bird_barred_owl",
             description: "Calls 'who cooks for you, who cooks for you-all'. Common in wooded swamps."),

        Bird(id: "belted_kingfisher", commonName: "Belted Kingfisher",
             scientificName: "Megaceryle alcyon",
             birdNETLabel: "Belted Kingfisher_Megaceryle alcyon",
             imageName: "bird_belted_kingfisher",
             description: "Rattling call along streams. Dives headfirst to catch fish."),

        Bird(id: "yellow_billed_cuckoo", commonName: "Yellow-billed Cuckoo",
             scientificName: "Coccyzus americanus",
             birdNETLabel: "Yellow-billed Cuckoo_Coccyzus americanus",
             imageName: "bird_yellow_billed_cuckoo",
             description: "Rain crow. Calls a wooden knocking 'ka-ka-ka-kow-kow-kowlp' before storms."),

        Bird(id: "whip_poor_will", commonName: "Whip-poor-will",
             scientificName: "Antrostomus vociferus",
             birdNETLabel: "Whip-poor-will_Antrostomus vociferus",
             imageName: "bird_whip_poor_will",
             description: "Nocturnal bird heard more often than seen. Calls its own name repeatedly at dusk."),

        Bird(id: "common_nighthawk", commonName: "Common Nighthawk",
             scientificName: "Chordeiles minor",
             birdNETLabel: "Common Nighthawk_Chordeiles minor",
             imageName: "bird_common_nighthawk",
             description: "Aerial insectivore. Booming sound made by wings during diving display."),

        Bird(id: "purple_martin", commonName: "Purple Martin",
             scientificName: "Progne subis",
             birdNETLabel: "Purple Martin_Progne subis",
             imageName: "bird_purple_martin",
             description: "Largest North American swallow. Colonies in martin houses are a Midwest tradition."),

        Bird(id: "cliff_swallow", commonName: "Cliff Swallow",
             scientificName: "Petrochelidon pyrrhonota",
             birdNETLabel: "Cliff Swallow_Petrochelidon pyrrhonota",
             imageName: "bird_cliff_swallow",
             description: "Builds gourd-shaped mud nests under bridges and eaves in large colonies."),

        Bird(id: "eastern_kingbird2", commonName: "Dickcissel",
             scientificName: "Spiza americana",
             birdNETLabel: "Dickcissel_Spiza americana",
             imageName: "bird_dickcissel",
             description: "Grassland sparrow-like bird with a yellow breast and black bib. Calls its own name."),

        Bird(id: "yellow_headed_blackbird", commonName: "Yellow-headed Blackbird",
             scientificName: "Xanthocephalus xanthocephalus",
             birdNETLabel: "Yellow-headed Blackbird_Xanthocephalus xanthocephalus",
             imageName: "bird_yellow_headed_blackbird",
             description: "Striking marsh blackbird with a yellow hood. Gives a bizarre rusty-gate call."),

        Bird(id: "american_bittern", commonName: "American Bittern",
             scientificName: "Botaurus lentiginosus",
             birdNETLabel: "American Bittern_Botaurus lentiginosus",
             imageName: "bird_american_bittern",
             description: "Secretive marsh heron. Pumping 'oong-ka-choonk' call is unmistakable."),

        Bird(id: "common_loon", commonName: "Common Loon",
             scientificName: "Gavia immer",
             birdNETLabel: "Common Loon_Gavia immer",
             imageName: "bird_common_loon",
             description: "Haunting wail on northern lakes. Migrates through Midwest lakes in spring and fall."),

        Bird(id: "pied_billed_grebe", commonName: "Pied-billed Grebe",
             scientificName: "Podilymbus podiceps",
             birdNETLabel: "Pied-billed Grebe_Podilymbus podiceps",
             imageName: "bird_pied_billed_grebe",
             description: "Stocky diver that can sink slowly without diving. Gives a whooping call."),

        Bird(id: "american_coot", commonName: "American Coot",
             scientificName: "Fulica americana",
             birdNETLabel: "American Coot_Fulica americana",
             imageName: "bird_american_coot",
             description: "Duck-like but related to rails. Pumps its head while swimming."),

        Bird(id: "sora", commonName: "Sora",
             scientificName: "Porzana carolina",
             birdNETLabel: "Sora_Porzana carolina",
             imageName: "bird_sora",
             description: "Small secretive rail of cattail marshes. Loud descending whinny in spring."),

        Bird(id: "virginia_rail", commonName: "Virginia Rail",
             scientificName: "Rallus limicola",
             birdNETLabel: "Virginia Rail_Rallus limicola",
             imageName: "bird_virginia_rail",
             description: "Secretive marsh bird. Grunting 'kiddick' call given day and night."),

        Bird(id: "trumpeter_swan", commonName: "Trumpeter Swan",
             scientificName: "Cygnus buccinator",
             birdNETLabel: "Trumpeter Swan_Cygnus buccinator",
             imageName: "bird_trumpeter_swan",
             description: "North America's largest native waterfowl. Deep trumpeting call. Recovering in Midwest."),

        Bird(id: "northern_harrier", commonName: "Northern Harrier",
             scientificName: "Circus hudsonius",
             birdNETLabel: "Northern Harrier_Circus hudsonius",
             imageName: "bird_northern_harrier",
             description: "Low-flying marsh hawk with an owl-like facial disc. White rump patch visible in flight."),

        Bird(id: "american_kestrel", commonName: "American Kestrel",
             scientificName: "Falco sparverius",
             birdNETLabel: "American Kestrel_Falco sparverius",
             imageName: "bird_american_kestrel",
             description: "Smallest North American falcon. Hovers over fields hunting insects and small prey."),
    ]

    /// Look up a Bird by its BirdNET label string.
    static func bird(forLabel label: String) -> Bird? {
        all.first { $0.birdNETLabel == label }
    }

    /// BirdNET label strings as a Set for fast membership testing.
    static let labelSet: Set<String> = Set(all.map { $0.birdNETLabel })
}
