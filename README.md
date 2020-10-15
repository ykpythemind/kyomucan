# kyomucan

### ruby

ruby 2.7

```
bundle install
```

### 環境変数を用意

```
export USER_EMAIL=ジョブカンのアドレス
export USER_PASSWORD=ジョブカンのパスワード
```

### 勤務時間csvを用意

format: `日付,出勤時間,退勤時間`

例
```
2020-01-01,1000,1920
2020-01-02,1020,2005
```

### 打刻実行

```
$ ruby main.rb < path/to/csv
```
