##### Zadanie dodatkowe 3

## Sprawdzenie podatności obrazu na zagrożenia.
![Image](https://github.com/user-attachments/assets/6ff9e9c6-f75f-4f91-9dc2-1d5967128c63)

```
docker scout cves --only-severity critical,high weather-app
```

- cves: wyświetlenie znanych podatności znajdujące się w obrazie,
- --only-severity critical,high: filtrowanie wyniku, pokazując tylko podatności o zagrożeniu critical lub high,
- weather-app: nazwa obrazu.
- W obrazie nie wykryto podatności sklasyfikowanych jako critical lub high.

## Budowanie obrazu.
![Image](https://github.com/user-attachments/assets/22bbba2c-2db9-4cf2-b877-9af1bba36af8)

```
docker buildx build --platform linux/amd64,linux/arm64 --ssh default --cache-from=type=registry,ref=docker.io/ssczupryn/weather-app-lab:buildcache --cache-to=type=registry,ref=docker.io/ssczupryn/weather-app-lab:buildcache,mode=max --push -t docker.io/ssczupryn/weather-app-lab:latest .
```

- buildx: rozszerzenie dockera do wieloplatformowego budowania obrazów, builder oparty jest na sterowniku docker-container,
- --platform linux/amd64,linux/arm64: buduje obraz dla dwóch architektur,
- --ssh default: umożliwia dostęp do lokalnych kluczy SSH w trakcie budowy,
- --cache-from: pobiera cache warstw budowy z repozytorium,
- --cache-to: zapisuje cache z budowy z do rejestru,
- mode=max: zapisuje wszystkie warstwy,
- --push: po zbudowaniu obrazu jest on wypychany do repozytorium,
- -t: taguje obraz,
- . : kontekst budowy.

## Sprawdzenie manifestu
![manifest](https://github.com/user-attachments/assets/106fd37c-123b-46f0-b46e-89787273c83a)

```
docker buildx imagetools inspect docker.io/ssczupryn/weather-app-lab:latest
```

- imagetools inspect: analizuje obraz kontenera i pokazuje jego metadane.

## Pobranie i ponownie sprawdzenie podatności obrazu na zagrożenia.
![zagrozenia po sciagnieciu obrazu](https://github.com/user-attachments/assets/9e33e6a3-2db7-42b9-93ed-b9a35c107c26)

```
docker pull docker.io/ssczupryn/weather-app-lab:latest
docker scout cves --only-severity critical,high ssczupryn/weather-app-lab
```

- W obrazie nie wykryto podatności sklasyfikowanych jako critical lub high.

Obraz na dockerhub: https://hub.docker.com/r/ssczupryn/weather-app-lab
