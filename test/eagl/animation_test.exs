defmodule EAGL.AnimationTest do
  use ExUnit.Case
  import EAGL.Math
  alias EAGL.{Animation, Animator, Scene, Node}
  alias EAGL.Animation.{Timeline, Channel, Sampler}

  describe "Animation.Sampler" do
    test "creates sampler with keyframe data" do
      keyframes = [vec3(0, 0, 0), vec3(1, 0, 0), vec3(0, 0, 0)]
      times = [0.0, 1.0, 2.0]

      sampler = Sampler.new(times, keyframes, :linear)

      assert sampler.input_times == times
      assert sampler.output_values == keyframes
      assert sampler.interpolation == :linear
    end

    test "calculates duration correctly" do
      times = [0.0, 1.5, 3.0]
      keyframes = [vec3(0, 0, 0), vec3(1, 0, 0), vec3(0, 0, 0)]

      sampler = Sampler.new(times, keyframes, :linear)

      assert Sampler.duration(sampler) == 3.0
    end

    test "samples exact keyframes" do
      times = [0.0, 1.0, 2.0]
      keyframes = [vec3(0, 0, 0), vec3(2, 0, 0), vec3(4, 0, 0)]

      sampler = Sampler.new(times, keyframes, :linear)

      assert Sampler.sample(sampler, 0.0) == vec3(0, 0, 0)
      assert Sampler.sample(sampler, 1.0) == vec3(2, 0, 0)
      assert Sampler.sample(sampler, 2.0) == vec3(4, 0, 0)
    end

    test "interpolates between keyframes" do
      times = [0.0, 2.0]
      keyframes = [vec3(0, 0, 0), vec3(4, 0, 0)]

      sampler = Sampler.new(times, keyframes, :linear)

      # Sample at 50% between keyframes
      result = Sampler.sample(sampler, 1.0)
      assert result == vec3(2.0, 0.0, 0.0)
    end
  end

  describe "Animation.Channel" do
    test "creates channel with target and sampler" do
      keyframes = [vec3(0, 0, 0), vec3(1, 0, 0)]
      times = [0.0, 1.0]
      sampler = Sampler.new(times, keyframes, :linear)

      channel = Channel.new("test_node", :translation, sampler)

      assert channel.target_node_id == "test_node"
      assert channel.target_property == :translation
      assert channel.sampler == sampler
    end

    test "samples channel at specific time" do
      keyframes = [vec3(0, 0, 0), vec3(2, 0, 0)]
      times = [0.0, 1.0]
      sampler = Sampler.new(times, keyframes, :linear)

      channel = Channel.new("test_node", :translation, sampler)

      result = Channel.sample(channel, 0.5)
      assert result == vec3(1.0, 0.0, 0.0)
    end
  end

  describe "Animation.Timeline" do
    test "creates empty timeline" do
      timeline = Timeline.new("test_animation")

      assert timeline.name == "test_animation"
      assert timeline.channels == []
      assert timeline.duration == 0.0
    end

    test "adds channels and updates duration" do
      # Create two channels with different durations
      sampler1 = Animation.Sampler.new([0.0, 2.0], [vec3(0, 0, 0), vec3(1, 0, 0)], :linear)
      sampler2 = Animation.Sampler.new([0.0, 3.0], [vec3(0, 0, 0), vec3(0, 1, 0)], :linear)

      channel1 = Animation.Channel.new("node1", :translation, sampler1)
      channel2 = Animation.Channel.new("node2", :translation, sampler2)

      timeline =
        Animation.Timeline.new("test")
        |> Animation.Timeline.add_channel(channel1)
        |> Animation.Timeline.add_channel(channel2)

      assert length(timeline.channels) == 2
      # Longest channel duration
      assert timeline.duration == 3.0
    end

    test "finds channels for specific node" do
      sampler = Animation.Sampler.new([0.0, 1.0], [vec3(0, 0, 0), vec3(1, 0, 0)], :linear)

      channel1 = Animation.Channel.new("node1", :translation, sampler)
      channel2 = Animation.Channel.new("node2", :translation, sampler)
      channel3 = Animation.Channel.new("node1", :rotation, sampler)

      timeline =
        Animation.Timeline.new("test")
        |> Animation.Timeline.add_channel(channel1)
        |> Animation.Timeline.add_channel(channel2)
        |> Animation.Timeline.add_channel(channel3)

      node1_channels = Animation.Timeline.channels_for_node(timeline, "node1")
      assert length(node1_channels) == 2

      node2_channels = Animation.Timeline.channels_for_node(timeline, "node2")
      assert length(node2_channels) == 1
    end
  end

  describe "Animation helpers" do
    test "creates rotation animation" do
      timeline = EAGL.Animation.create_rotation_animation(2.0, node_id: "test_cube")

      assert timeline.name == "rotate_y"
      assert timeline.duration == 2.0
      assert length(timeline.channels) == 1

      channel = List.first(timeline.channels)
      assert channel.target_node_id == "test_cube"
      assert channel.target_property == :rotation
    end

    test "creates translation animation" do
      start_pos = vec3(0, 0, 0)
      end_pos = vec3(5, 0, 0)

      timeline =
        Animation.create_translation_animation(start_pos, end_pos, 1.5, node_id: "test_cube")

      assert timeline.name == "translate"
      assert timeline.duration == 1.5
      assert length(timeline.channels) == 1

      channel = List.first(timeline.channels)
      assert channel.target_node_id == "test_cube"
      assert channel.target_property == :translation
    end
  end

  describe "Animator integration" do
    test "creates animator and loads timeline" do
      {:ok, animator} = Animator.new()

      timeline = EAGL.Animation.create_rotation_animation(1.0, node_id: "test")
      :ok = Animator.load_timeline(animator, timeline)

      timelines = Animator.list_timelines(animator)
      assert "rotate_y" in timelines
    end

    test "plays animation and updates time" do
      {:ok, animator} = Animator.new()

      timeline = EAGL.Animation.create_rotation_animation(2.0, node_id: "test")
      :ok = Animator.load_timeline(animator, timeline)
      :ok = Animator.play(animator, "rotate_y")

      # Initial state
      state = Animator.get_state(animator)
      assert state.current_animation == "rotate_y"
      assert state.current_time == 0.0
      assert state.playback_state == :playing

      # Update time
      :ok = Animator.update(animator, 0.5)

      updated_state = Animator.get_state(animator)
      assert updated_state.current_time == 0.5
      assert updated_state.playback_state == :playing
    end

    test "applies animation to scene" do
      # Create scene with node
      scene = Scene.new()
      node = Node.new(name: "animated_node", position: vec3(0, 0, 0))
      scene = Scene.add_root_node(scene, node)

      # Create animation
      {:ok, animator} = Animator.new()

      timeline =
        Animation.create_translation_animation(
          vec3(0, 0, 0),
          vec3(2, 0, 0),
          1.0,
          node_id: "animated_node"
        )

      :ok = Animator.load_timeline(animator, timeline)
      :ok = Animator.play(animator, "translate")

      # Update animation to 50% progress
      :ok = Animator.update(animator, 0.5)

      # Apply to scene
      animated_scene = Animator.apply_to_scene(animator, scene)

      # Check that node position was updated
      updated_node = Scene.find_node(animated_scene, "animated_node")
      assert updated_node != nil
      # At 50% of back-and-forth motion (start->end->start), we should be at the end position
      assert updated_node.position == vec3(2.0, 0.0, 0.0)
    end
  end
end
