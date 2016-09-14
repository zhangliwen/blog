---
layout: post
title: Rails如何升级到4.2
subtitle: "第一次做翻译，come on！"
categories: [rails]
---

本文档是 [How to Upgrade to Rails 4.2](http://www.justinweiss.com/articles/how-to-upgrade-to-rails-4-dot-2/)中文翻译版， 阅读这个文档可以帮助你了解 *升级Rails* 的技巧。

# 前言

升级Rails项目很简单: *bundle update rails* .

**但是你有多少种Rails类型的项目？**一种还是4.0，甚至3.2版本的，而你不想将来拽着它们发狂吧？

无论你面临的是一个快速升级或者痛苦的方案，这些步骤将帮助你尽可能顺利的将项目升级到4.2版本。在升级过程中，你将学到如何充分利用4.2版本的新功能。

# 阅读升级指南

当你升级你的Rails项目时，应该时刻阅读[Rails Upgrade Guide*升级指南*](http://guides.rubyonrails.org/upgrading_ruby_on_rails.html).

*升级指南*将引导你完成最主要的版本修改。**它会告诉你如何修改你的项目来解决你遇到的最大的问题。**（例如，[这个变化](http://guides.rubyonrails.org/upgrading_ruby_on_rails.html#mutator-methods-called-on-relation)在4.1将会给我们造成数小时的痛苦如果我们没有阅读它。）

但更多的是，*升级指南*将解释为什么你应该做出这些修改。而这很重要，因为它可以帮助你理解哪些建议你应该关注以及哪些可以忽略。

如果你想更深入理解Rails4.2的变化，请阅读[release notes](http://guides.rubyonrails.org/4_2_release_notes.html)。它们将介绍你所有Rails4.2你将用到的酷炫的新功能。毫无例外的话，它会激励你去完成升级。

# 升级步骤

**当你准备升级Rails时，先升级小版本。别跳跃大版本.**

所以如果你想从4.1.6升级到4.2，先从4.1.6到4.1.9，然后再从4.1.9到4.2。如果你从4.0.12开始，先从4.0.12升级到4.0.13，然后再从4.0.13到4.1.9，最后从4.1.9到4.2。这可能看起来工作量更大，但长远来看它会节省你的时间。

为什么？

Rails每发布一个小版本都会有最好的警告信息。

不要低估了这些警告信息的作用。如果你使用上诉步骤来升级，它们会告诉你什么会被破坏以及如何阻止它。如果你升级版本跳的太快，你的项目仅仅是简单的坏了，你也不知道为什么。

最后，如果Rails小版本升级（像4.0.9到4.0.13）在一个*Test*坏了，它通过也会在大版本升级时坏掉。但是这些问题在变化少的情况下更容易调试和修复。

所以，要做的事情有：

1. 将Rails项目升级到Rails所在大版本的任何一个更新的小版本。
2. 升级每一个gems，避免一直处于 *bundle update* 中。
3. 修复*Test*, 根据需要提交。
4. 修复警告信息，根据需要提交。
5. 升级下一个大版本，重复上面的步骤。

# 从你的Test中学习

**当你升级Rails，你的测试将在第一个告诉你哪里有问题。**它们应该在第一时间被执行，并在第一时间完成修复。甚至在你完成大部分修复之前，不要试图启动Rails项目。

# 升级你的Gems

当你的测试出错，它看起来不是代码写错，而通常意味着你某些gems需要升级了。

**Rails升级最糟糕的时刻就是升级Gem。**由于这么多你的项目是变化的，这很难告诉你Rails升级破坏了什么东西，或者Gem的升级破坏了什么东西，又或者你自身破坏了什么东西。

但由于一些gems在Rails自依赖太严重，这是你必须要做的。所以如果一个**sass**出错了，升级**sass-rails** Gem。然后希望这不会让事情更糟糕。

# 做笔记

如果你只有一个特别粗糙的升级方案，你将会一个一个去实验。在这过程中，你有可能做一个调试，调整一些代码，或者修改一些测试。

当你这样做之后，你可能忘记了你做过的操作。一些事情你做了大部分但并不完全的尝试；你还要准备去看一些*Test*；并且还有其他需要地方的代码需要修改。建议和同事分享你正在升级你们的项目。

因此，做一些笔记，任何事情都可以记录下来，你做过的尝试，以及更改过的文件。

假设你在升级那些必须升级的Gems时，你有了关于“为什么会出错“以及“他们是否是正确的”想法。出现了一些貌似很奇怪的结果，然后你会更细心的检查。

你不想在你做出了修改，回滚到原样后，意识到这是正确的解决方案，而你不记得你做了什么。**所以记下它.**

# 其他资源

在评论里，[Miha Rekar](http://www.justinweiss.com/blog/2015/01/27/how-to-upgrade-to-rails-4-dot-2/#comment-1819239786) 提出了 [RailsDiff](http://railsdiff.org/diff/v4.1.9/v4.2.0/),向你展示了不同版本生成的不同Rails项目之间的差异。

[Daniel Kehoe](http://www.justinweiss.com/blog/2015/01/27/how-to-upgrade-to-rails-4-dot-2/#comment-1821457820)也写了一篇指南[comprehensive guide](http://railsapps.github.io/updating-rails.html),通过RVM 和 RVM gemsets 升级Ruby 和Rails。

# 可能的升级体验 
一些Rails 升级是顺利的，所有东西都能正常运行；一些升级则非常有挑战性，需要几天或者几周的开销。这要取决于你的项目，你的依赖，以及Rails指定需要修改的变化。**但如果你按照这些步骤，你将有最好的升级体验。**

你已经是Rails 4.2了吗？你是如何升级你的项目的？你只需要升级一堆Gems，还是仍然在追寻最后一个出错的*Test*？

原文推荐： [How to Upgrade to Rails 4.2](http://www.justinweiss.com/articles/how-to-upgrade-to-rails-4-dot-2/)
