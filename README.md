# Zadanie 2

### Tagowanie obrazów
- sha- w połączeniu z pierwszymi 12 znakami skróconego skrótu commita. Priorytet jest ustawiony na najniższy, dzięki czemu zawsze powstaje unikalny tag. Dzięki temu łatwo można odnaleźć odpowiednią wersje obrazu dla danego commita.
- semver pobiera tag z Gita. Priorytet jest ustawiony na większy względem sha, dzięki czemu jeśli commit jest oznaczony tagiem zaczynającym się od literki v z cyfrą, to obraz otrzyma również taki tag. Dzięki temu łatwo wskazać konkretną wersję obrazu.
- Wersjonowanie za pomocą semver jest czytelne dla użytkowników i dokumentacji, natomiast tagi SHA gwarantują unikalność i możliwość odtworzenia dokładnej wersji obrazu.

### Tagowanie cache
- Został użyty 1 stały tag, dzięki czemu występuje ciągłe odświeżanie cache w rejestrze. Kolejne buildy zawsze pobierają najnowszy stan cache i dodają do niego nowe warstwy.
- Upraszcza to konfigurację, nie trzeba generować dynamicznych nazw ani zarządzać tagami. Pozwala buildx automatycznie nadpisywać stare warstwy, utrzymując cache w najnowszym stanie, dzięki czemu proces budowania obrazów jest szybszy.
#


```name: Zadanie 2

concurrency:
  group: ${{ github.repository }}-build-${{ github.ref }}
  cancel-in-progress: true

on:
  workflow_dispatch:
  push:
    tags:
      - "v[0-9]*"
```
Akcje uruchamiane są automatycznie po wypchnięciu nowego tagu wersji. concurrency zapewnia, że jest uruchomione tylko 1 akcja, wcześniejsze zostaną anulowane.
#
```
jobs:
  ci_step:
    name: Multiarch Image Build and Push
    runs-on: ubuntu-latest

    permissions:
      contents: read
      packages: write

    strategy:
      matrix:
        arch: [linux/amd64, linux/arm64]

    env:
      IMAGE_NAME: ghcr.io/${{ github.repository_owner }}/weather-app-lab
      CACHE_IMAGE: ${{ vars.DOCKERHUB_USERNAME }}/weather-app-lab-cache
```
Nazywa zadanie widoczne w akcji. Określa system operacyjny używany w runnerze, określa uprawnienia do odczytu plików z repozytorium oraz do publikowania obrazów do ghcr. Definiowana jest macierz budowania, dzięki której obrazy są budowane równolegle dla różnych platform. Pozwala to na uniknięcie zduplikowania kodu akcji, przyspieszenie wykonania całej akcji. Dodatkowo zdefiniowane są 2 zmienne środowiskowe.
#
```
    steps:
      - uses: actions/checkout@v4

      - name: SSH Agent Setup
        uses: webfactory/ssh-agent@v0.9.0
        with:
          ssh-private-key: ${{ secrets.SSH_PRIVATE_KEY }}
          log-public-key: true

      - name: Docker metadata definitions
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: ${{ env.IMAGE_NAME }}
          flavor: latest=false
          tags: |
            type=sha,priority=100,prefix=sha-,format=short
            type=semver,priority=200,pattern={{version}}
```
Pobranie kodu źródłowego do środowiska wykonawczego, konfiguracja klienta ssh do pobrania kodu aplikacji, generowanie tagów obrazu na podstawie wersji i skrótu commita.
#
```
      - name: QEMU set-up
        uses: docker/setup-qemu-action@v3

      - name: Buildx set-up
        uses: docker/setup-buildx-action@v3
```
Konfiguracja QEMU - emulacje architektur oraz Buildx do budowania obrazów wieloplatformowych.
#
```
      - name: Log in to DockerHub
        uses: docker/login-action@v3
        with:
          username: ${{ vars.DOCKERHUB_USERNAME }}
          password: ${{ secrets.DOCKERHUB_TOKEN }}

      - name: Log in to ghcr
        uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GH_TOKEN }}
```
Logowanie do rejestrów DockerHub oraz ghcr.
#
```
      - name: Build ${{ matrix.arch }} Docker image
        id: build-image
        uses: docker/build-push-action@v5
        with:
          context: .
          file: ./Dockerfile
          platforms: ${{ matrix.arch }}
          load: true
          ssh: default
          tags: ${{ steps.meta.outputs.tags }}
          cache-from: |
            type=registry,ref=${{ env.CACHE_IMAGE }}:cache
          cache-to: |
            type=registry,ref=${{ env.CACHE_IMAGE }}:cache,mode=max
```
Budowanie obrazów osobno dla dwóch architektur. Użycie cache z zewnętrznego repozytorium na DockerHub. cache-from pobiera cache, cache-to zapisuje wszystkie, nowe warstwy.
#
```
      - name: Scan ${{ matrix.arch }} image for vulnerabilities
        uses: aquasecurity/trivy-action@0.28.0
        with:
          image-ref: ${{ steps.build-image.outputs.imageid }}
          severity: CRITICAL,HIGH
          format: table
          exit-code: 1
```
Skanowanie zbudowanych obrazów osobno pod kątem zagrożeń krytycznych i wysokich. Jeśli zostanie wykryte takie zagrożenie, akcja zostanie zatrzymana z kodem 1. 
#
```
      - name: Push Docker image to GHCR
        if: success()
        uses: docker/build-push-action@v5
        with:
          platforms: linux/amd64,linux/arm64
          push: true
          ssh: default
          tags: ${{ steps.meta.outputs.tags }}
```
Jeśli skanowanie nie wykryje zagrożeń, obraz dla obu architektur zostanie wypchnięty do rejestru ghcr.

#### Źródła:
- https://github.com/docker/metadata-action
- https://docs.docker.com/build/cache/optimize/#use-an-external-cache
- https://docs.docker.com/build/ci/github-actions/
- https://docs.github.com/en/actions/writing-workflows/choosing-what-your-workflow-does/running-variations-of-jobs-in-a-workflow
