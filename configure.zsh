network=${1:-local}

dfx canister --network $network call legends configureLegends\
    "(vec {\

        record { back = \"Saxon\"; border = \"Saxon\"; ink = \"Copper\"; };\
        record { back = \"Saxon\"; border = \"Saxon\"; ink = \"Silver\"; };\
        record { back = \"Saxon\"; border = \"Saxon\"; ink = \"Gold\"; };\
        record { back = \"Worn Saxon\"; border = \"Worn Saxon\"; ink = \"Canopy\"; };\
        record { back = \"Staggered\"; border = \"Bordered Saxon\"; ink = \"Rose\"; };\
        record { back = \"Round\"; border = \"Fate\"; ink = \"Spice\"; };\
        record { back = \"Staggered\"; border = \"Fate\"; ink = \"Midnight\"; };\

        record { back = \"Thin\"; border = \"Fate\"; ink = \"Copper\"; };\
        record { back = \"Thin\"; border = \"Fate\"; ink = \"Silver\"; };\
        record { back = \"Bare\"; border = \"Fate\"; ink = \"Copper\"; };\
        record { back = \"Bare\"; border = \"Fate\"; ink = \"Silver\"; };\
        record { back = \"Round\"; border = \"Fate\"; ink = \"Copper\"; };\
        record { back = \"Staggered\"; border = \"Bordered Saxon\"; ink = \"Gold\"; };\
        record { back = \"Thicc\"; border = \"Bordered Saxon\"; ink = \"Copper\"; };\
        record { back = \"Greek\"; border = \"Bordered Saxon\"; ink = \"Gold\"; };\
        record { back = \"Worn Saxon\"; border = \"Worn Saxon\"; ink = \"Copper\"; };\
        record { back = \"Saxon\"; border = \"Saxon\"; ink = \"Copper\"; };\

        record { back = \"Thin\"; border = \"Fate\";	ink = \"Copper\"; };\
        record { back = \"Thin\"; border = \"Fate\";	ink = \"Copper\"; };\
        record { back = \"Thin\"; border = \"Fate\";	ink = \"Copper\"; };\
        record { back = \"Thin\"; border = \"Fate\";	ink = \"Copper\"; };\
        record { back = \"Thin\"; border = \"Fate\";	ink = \"Copper\"; };\
        record { back = \"Thin\"; border = \"Fate\";	ink = \"Silver\"; };\
        record { back = \"Thin\"; border = \"Fate\";	ink = \"Silver\"; };\
        record { back = \"Thin\"; border = \"Fate\";	ink = \"Silver\"; };\
        record { back = \"Thin\"; border = \"Fate\";	ink = \"Silver\"; };\
        record { back = \"Thin\"; border = \"Fate\";	ink = \"Gold\"; };\
        record { back = \"Thin\"; border = \"Fate\";	ink = \"Gold\"; };\
        record { back = \"Thin\"; border = \"Fate\";	ink = \"Canopy\"; };\
        record { back = \"Thin\"; border = \"Fate\";	ink = \"Spice\"; };\
        record { back = \"Thin\"; border = \"Bordered Saxon\";	ink = \"Copper\"; };\
        record { back = \"Thin\"; border = \"Bordered Saxon\";	ink = \"Copper\"; };\
        record { back = \"Thin\"; border = \"Bordered Saxon\";	ink = \"Copper\"; };\
        record { back = \"Thin\"; border = \"Bordered Saxon\";	ink = \"Silver\"; };\
        record { back = \"Thin\"; border = \"Bordered Saxon\";	ink = \"Silver\"; };\
        record { back = \"Thin\"; border = \"Bordered Saxon\";	ink = \"Gold\"; };\
        record { back = \"Thin\"; border = \"Bordered Saxon\";	ink = \"Canopy\"; };\
        record { back = \"Bare\"; border = \"Fate\";	ink = \"Copper\"; };\
        record { back = \"Bare\"; border = \"Fate\";	ink = \"Copper\"; };\
        record { back = \"Bare\"; border = \"Fate\";	ink = \"Copper\"; };\
        record { back = \"Bare\"; border = \"Fate\";	ink = \"Copper\"; };\
        record { back = \"Bare\"; border = \"Fate\";	ink = \"Copper\"; };\
        record { back = \"Bare\"; border = \"Fate\";	ink = \"Silver\"; };\
        record { back = \"Bare\"; border = \"Fate\";	ink = \"Silver\"; };\
        record { back = \"Bare\"; border = \"Fate\";	ink = \"Silver\"; };\
        record { back = \"Bare\"; border = \"Fate\";	ink = \"Silver\"; };\
        record { back = \"Bare\"; border = \"Fate\";	ink = \"Gold\"; };\
        record { back = \"Bare\"; border = \"Fate\";	ink = \"Canopy\"; };\
        record { back = \"Bare\"; border = \"Fate\";	ink = \"Canopy\"; };\
        record { back = \"Bare\"; border = \"Fate\";	ink = \"Rose\"; };\
        record { back = \"Bare\"; border = \"Bordered Saxon\";	ink = \"Copper\"; };\
        record { back = \"Bare\"; border = \"Bordered Saxon\";	ink = \"Copper\"; };\
        record { back = \"Bare\"; border = \"Bordered Saxon\";	ink = \"Copper\"; };\
        record { back = \"Bare\"; border = \"Bordered Saxon\";	ink = \"Silver\"; };\
        record { back = \"Bare\"; border = \"Bordered Saxon\";	ink = \"Silver\"; };\
        record { back = \"Bare\"; border = \"Bordered Saxon\";	ink = \"Gold\"; };\
        record { back = \"Bare\"; border = \"Bordered Saxon\";	ink = \"Canopy\"; };\
        record { back = \"Round\"; border = \"Fate\";	ink = \"Copper\"; };\
        record { back = \"Round\"; border = \"Fate\";	ink = \"Copper\"; };\
        record { back = \"Round\"; border = \"Fate\";	ink = \"Copper\"; };\
        record { back = \"Round\"; border = \"Fate\";	ink = \"Silver\"; };\
        record { back = \"Round\"; border = \"Fate\";	ink = \"Silver\"; };\
        record { back = \"Round\"; border = \"Fate\";	ink = \"Gold\"; };\
        record { back = \"Round\"; border = \"Fate\";	ink = \"Canopy\"; };\
        record { back = \"Round\"; border = \"Fate\";	ink = \"Canopy\"; };\
        record { back = \"Round\"; border = \"Fate\";	ink = \"Rose\"; };\
        record { back = \"Round\"; border = \"Fate\";	ink = \"Spice\"; };\
        record { back = \"Round\"; border = \"Bordered Saxon\";	ink = \"Copper\"; };\
        record { back = \"Round\"; border = \"Bordered Saxon\";	ink = \"Silver\"; };\
        record { back = \"Round\"; border = \"Bordered Saxon\";	ink = \"Gold\"; };\
        record { back = \"Round\"; border = \"Bordered Saxon\";	ink = \"Canopy\"; };\
        record { back = \"Staggered\"; border = \"Fate\";	ink = \"Copper\"; };\
        record { back = \"Staggered\"; border = \"Fate\";	ink = \"Copper\"; };\
        record { back = \"Staggered\"; border = \"Fate\";	ink = \"Copper\"; };\
        record { back = \"Staggered\"; border = \"Fate\";	ink = \"Silver\"; };\
        record { back = \"Staggered\"; border = \"Fate\";	ink = \"Silver\"; };\
        record { back = \"Staggered\"; border = \"Fate\";	ink = \"Gold\"; };\
        record { back = \"Staggered\"; border = \"Fate\";	ink = \"Canopy\"; };\
        record { back = \"Staggered\"; border = \"Fate\";	ink = \"Rose\"; };\
        record { back = \"Staggered\"; border = \"Fate\";	ink = \"Midnight\"; };\
        record { back = \"Staggered\"; border = \"Bordered Saxon\";	ink = \"Copper\"; };\
        record { back = \"Staggered\"; border = \"Bordered Saxon\";	ink = \"Silver\"; };\
        record { back = \"Staggered\"; border = \"Bordered Saxon\";	ink = \"Gold\"; };\
        record { back = \"Staggered\"; border = \"Bordered Saxon\";	ink = \"Rose\"; };\
        record { back = \"Thicc\"; border = \"Fate\";	ink = \"Copper\"; };\
        record { back = \"Thicc\"; border = \"Fate\";	ink = \"Copper\"; };\
        record { back = \"Thicc\"; border = \"Fate\";	ink = \"Silver\"; };\
        record { back = \"Thicc\"; border = \"Fate\";	ink = \"Gold\"; };\
        record { back = \"Thicc\"; border = \"Fate\";	ink = \"Rose\"; };\
        record { back = \"Thicc\"; border = \"Bordered Saxon\";	ink = \"Copper\"; };\
        record { back = \"Thicc\"; border = \"Bordered Saxon\";	ink = \"Silver\"; };\
        record { back = \"Thicc\"; border = \"Bordered Saxon\";	ink = \"Gold\"; };\
        record { back = \"Thicc\"; border = \"Bordered Saxon\";	ink = \"Rose\"; };\
        record { back = \"Greek\"; border = \"Fate\";	ink = \"Copper\"; };\
        record { back = \"Greek\"; border = \"Fate\";	ink = \"Copper\"; };\
        record { back = \"Greek\"; border = \"Fate\";	ink = \"Silver\"; };\
        record { back = \"Greek\"; border = \"Fate\";	ink = \"Gold\"; };\
        record { back = \"Greek\"; border = \"Fate\";	ink = \"Spice\"; };\
        record { back = \"Greek\"; border = \"Bordered Saxon\";	ink = \"Copper\"; };\
        record { back = \"Greek\"; border = \"Bordered Saxon\";	ink = \"Silver\"; };\
        record { back = \"Greek\"; border = \"Bordered Saxon\";	ink = \"Gold\"; };\
        record { back = \"Greek\"; border = \"Bordered Saxon\";	ink = \"Rose\"; };\
        record { back = \"Worn\"; border = \"Saxon	Worn Saxon\";	ink = \"Copper\"; };\
        record { back = \"Worn\"; border = \"Saxon	Worn Saxon\";	ink = \"Copper\"; };\
        record { back = \"Worn\"; border = \"Saxon	Worn Saxon\";	ink = \"Silver\"; };\
        record { back = \"Worn\"; border = \"Saxon	Worn Saxon\";	ink = \"Silver\"; };\
        record { back = \"Worn\"; border = \"Saxon	Worn Saxon\";	ink = \"Gold\"; };\
        record { back = \"Worn\"; border = \"Saxon	Worn Saxon\";	ink = \"Gold\"; };\
        record { back = \"Worn\"; border = \"Saxon	Worn Saxon\";	ink = \"Canopy\"; };\
        record { back = \"Worn\"; border = \"Saxon	Worn Saxon\";	ink = \"Rose\"; };\
        record { back = \"Worn\"; border = \"Saxon	Worn Saxon\";	ink = \"Spice\"; };\
        record { back = \"Worn\"; border = \"Saxon	Worn Saxon\";	ink = \"Midnight\"; };\
        record { back = \"Saxon\"; border = \"Saxon\";	ink = \"Copper\"; };\
        record { back = \"Saxon\"; border = \"Saxon\";	ink = \"Silver\"; };\
        record { back = \"Saxon\"; border = \"Saxon\";	ink = \"Gold\"; };\
        record { back = \"Saxon\"; border = \"Saxon\";	ink = \"Spice\"; };\
        record { back = \"Saxon\"; border = \"Saxon\";	ink = \"Midnight\"; };\
    })"