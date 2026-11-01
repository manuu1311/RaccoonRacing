import argparse

from godot_rl.wrappers.sample_factory_wrapper import sample_factory_enjoy, sample_factory_training

# USAGE
'''
python curriculum_sf.py \
    --experiment_name=my_run \
    --experiment_dir=logs/sf \
    --speedup=1 \
    --learning_rate=0.0003 \
    --gamma=0.995 \
    --batch_size=1024 \
    --num_epochs=1 \
    --rollout=32 \
    --train_for_env_steps=5000000 \
    --encoder_mlp_layers 256 256 \
    --nonlinearity=relu \
    --env_path=builds/MyGame.x86_64 \
    --use_rnn=True \
    --rnn_type=lstm \
    --rnn_size=256 \
    --decoder_mlp_layers 128 \
    --num_workers=8 \
    --num_envs_per_worker=2 \
    --init_checkpoint_path=logs/sf/stage1/checkpoint_p0/checkpoint_XXXX.pth
'''

def get_args():
    parser = argparse.ArgumentParser(allow_abbrev=False)
    parser.add_argument("--env_path", default=None, type=str, help="Godot binary to use")
    parser.add_argument("--eval", default=False, action="store_true", help="whether to eval the model")
    parser.add_argument("--speedup", default=1, type=int, help="whether to speed up the physics in the env")
    parser.add_argument("--seed", default=0, type=int, help="environment seed")
    parser.add_argument("--export", default=False, action="store_true", help="whether to export the model")
    parser.add_argument("--viz", default=False, action="store_true", help="Whether to visualize one process")
    parser.add_argument(
        "--experiment_dir",
        default="logs/sf",
        type=str,
        help="The name of the experiment directory, in which the tensorboard logs are getting stored",
    )
    parser.add_argument(
        "--experiment_name",
        default="experiment",
        type=str,
        help="The name of the experiment, which will be displayed in tensorboard. ",
    )

    return parser.parse_known_args()


def main():
    args, extras = get_args()
    if args.eval:
        sample_factory_enjoy(args, extras)
    else:
        sample_factory_training(args, extras)


if __name__ == "__main__":
    main()
