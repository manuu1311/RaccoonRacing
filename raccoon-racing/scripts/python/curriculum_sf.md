# Training Commands Reference

## 1. Editor Test (Local Debugging / CPU)
Quick run configuration with a single worker, visualization enabled, and small batch size for local testing.

```bash
python curriculum_sf.py \
        --env=gdrl \
        --env_path=/mnt/dump/dump-projects/Godot/RaccoonRacing/github-data/misc/tmp/rl-training.x86_64 \
        --experiment_name=editor_test \
        --experiment_dir=logs/sf \
        --restart_behavior=overwrite \
        --device=cpu \
        --speedup=1 \
        --num_workers=1 \
        --num_envs_per_worker=1 \
        --worker_num_splits=1 \
        --serial_mode=True \
        --async_rl=False \
        --learning_rate=0.0003 \
        --gamma=0.99 \
        --batch_size=256 \
        --num_epochs=1 \
        --rollout=32 \
        --train_for_env_steps=50000 \
        --encoder_mlp_layers 256 256 \
        --nonlinearity=relu \
        --viz \
        --training_mode=curriculum
```

---

## 2. Full Scale Training -- curriculum
Production/general training setup using multiple workers, RNN memory, and larger step limits.

```bash
python curriculum_sf.py \
        --env=gdrl \
        --env_path=/mnt/dump/dump-projects/Godot/RaccoonRacing/github-data/misc/tmp/rl-training.x86_64 \
        --experiment_name=curriculum \
        --experiment_dir=logs/sf \
        --speedup=1 \
        --device=cpu \
        --learning_rate=0.0003 \
        --gamma=0.99 \
        --batch_size=1024 \
        --num_epochs=1 \
        --rollout=32 \
        --encoder_mlp_layers 256 256 \
        --nonlinearity=relu \
        --worker_num_splits=1 \
        --serial_mode=False \
        --async_rl=True \
        --restart_behavior=resume \
        --use_rnn=True \
        --rnn_type=lstm \
        --rnn_size=128 \
        --recurrence=32 \
        --decoder_mlp_layers 128 \
        --num_workers=16 \
        --num_envs_per_worker=1 \
        --viz \
        --env_speedup=10 \
        --training_mode=curriculum \
        --train_for_env_steps=3000000
```

---

## 3. Full Scale Training -- early
Production/general training setup using multiple workers, RNN memory, and larger step limits.

```bash
python curriculum_sf.py \
        --env=gdrl \
        --env_path=/mnt/dump/dump-projects/Godot/RaccoonRacing/github-data/misc/tmp/rl-training.x86_64 \
        --experiment_name=early \
        --experiment_dir=logs/sf \
        --speedup=1 \
        --device=cpu \
        --learning_rate=0.0003 \
        --gamma=0.99 \
        --batch_size=1024 \
        --num_epochs=1 \
        --rollout=32 \
        --encoder_mlp_layers 256 256 \
        --nonlinearity=relu \
        --worker_num_splits=1 \
        --serial_mode=False \
        --async_rl=True \
        --restart_behavior=resume \
        --use_rnn=True \
        --rnn_type=lstm \
        --rnn_size=128 \
        --recurrence=32 \
        --decoder_mlp_layers 128 \
        --num_workers=16 \
        --num_envs_per_worker=1 \
        --viz \
        --init_checkpoint_path=logs/sf/curriculum/checkpoint_p0/checkpoint_XXXXXXXX_YYYYYYY.pth \
        --env_speedup=10 \
        --training_mode=early \
        --train_for_env_steps=3000000
```
