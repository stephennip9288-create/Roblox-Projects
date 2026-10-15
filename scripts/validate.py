from common import ROOT, load_manifest

def main():
    paths = list((ROOT / "games").glob("*/places/*/deploy.json"))
    if not paths:
        print("No configured places yet; examples are inactive.")
    for path in paths:
        game, place = path.parents[2].name, path.parent.name
        mode, sources, _ = load_manifest(game, place)
        print(f"OK: {game}/{place} ({mode}) | staging: {sources['staging'].relative_to(ROOT)} | production: {sources['production'].relative_to(ROOT)}")
    print(f"Validated {len(paths)} configured place(s)")

if __name__ == "__main__":
    main()
